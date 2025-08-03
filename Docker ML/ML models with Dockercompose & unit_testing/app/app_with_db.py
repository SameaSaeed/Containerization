from flask import Flask, request, jsonify
import joblib
import pickle
import numpy as np
import os
import logging
import psycopg2
import json
from datetime import datetime
import uuid
from contextlib import contextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'postgres'),
    'database': os.getenv('DB_NAME', 'ml_predictions'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'postgres'),
    'port': os.getenv('DB_PORT', '5432')
}

# Global variables
model = None
model_info = None

@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    conn = None
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        yield conn
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Database error: {str(e)}")
        raise
    finally:
        if conn:
            conn.close()

def load_model():
    """Load the trained model and model info"""
    global model, model_info
    
    try:
        model = joblib.load('/app/model/iris_model.pkl')
        
        with open('/app/model/model_info.pkl', 'rb') as f:
            model_info = pickle.load(f)
        
        logger.info("Model loaded successfully")
        logger.info(f"Model accuracy: {model_info['accuracy']:.2f}")
        
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        raise

def save_prediction_to_db(features, prediction, predicted_class, probabilities, request_id):
    """Save prediction to database"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            insert_query = """
                INSERT INTO predictions (features, prediction, predicted_class, probabilities, request_id)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id;
            """
            
            cursor.execute(insert_query, (
                json.dumps(features),
                prediction,
                predicted_class,
                json.dumps(probabilities),
                request_id
            ))
            
            prediction_id = cursor.fetchone()[0]
            conn.commit()
            
            logger.info(f"Prediction saved to database with ID: {prediction_id}")
            return prediction_id
            
    except Exception as e:
        logger.error(f"Error saving prediction to database: {str(e)}")
        return None

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    db_status = "unknown"
    
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT 1;")
            db_status = "healthy"
    except:
        db_status = "unhealthy"
    
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model_loaded': model is not None,
        'database_status': db_status
    })

@app.route('/model/info', methods=['GET'])
def get_model_info():
    """Get model information"""
    if model_info is None:
        return jsonify({'error': 'Model not loaded'}), 500
    
    return jsonify({
        'feature_names': model_info['feature_names'],
        'target_names': model_info['target_names'],
        'accuracy': model_info['accuracy'],
        'model_type': 'RandomForestClassifier'
    })

@app.route('/predict', methods=['POST'])
def predict():
    """Make predictions and save to database"""
    try:
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500
        
        data = request.get_json()
        
        if not data or 'features' not in data:
            return jsonify({'error': 'Features not provided'}), 400
        
        features = data['features']
        
        if len(features) != 4:
            return jsonify({
                'error': 'Expected 4 features',
                'expected_features': model_info['feature_names']
            }), 400
        
        # Generate request ID
        request_id = str(uuid.uuid4())
        
        # Make prediction
        features_array = np.array(features).reshape(1, -1)
        prediction = model.predict(features_array)[0]
        prediction_proba = model.predict_proba(features_array)[0]
        predicted_class = model_info['target_names'][prediction]
        
        # Create probabilities dictionary
        probabilities = {
            model_info['target_names'][i]: float(prob) 
            for i, prob in enumerate(prediction_proba)
        }
        
        # Save to database
        db_id = save_prediction_to_db(
            features, int(prediction), predicted_class, probabilities, request_id
        )
        
        # Create response
        response = {
            'request_id': request_id,
            'database_id': db_id,
            'prediction': int(prediction),
            'predicted_class': predicted_class,
            'probabilities': probabilities,
            'features_used': {
                model_info['feature_names'][i]: float(features[i]) 
                for i in range(len(features))
            },
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"Prediction made: {predicted_class} (ID: {request_id})")
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/predictions/history', methods=['GET'])
def get_prediction_history():
    """Get prediction history from database"""
    try:
        limit = request.args.get('limit', 10, type=int)
        offset = request.args.get('offset', 0, type=int)
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            query = """
                SELECT id, timestamp, features, prediction, predicted_class, 
                       probabilities, request_id
                FROM predictions 
                ORDER BY timestamp DESC 
                LIMIT %s OFFSET %s;
            """
            
            cursor.execute(query, (limit, offset))
            results = cursor.fetchall()
            
            predictions = []
            for row in results:
                predictions.append({
                    'id': row[0],
                    'timestamp': row[1].isoformat(),
                    'features': json.loads(row[2]),
                    'prediction': row[3],
                    'predicted_class': row[4],
                    'probabilities': json.loads(row[5]),
                    'request_id': row[6]
                })
            
            return jsonify({
                'predictions': predictions,
                'total_returned': len(predictions),
                'limit': limit,
                'offset': offset
            })
            
    except Exception as e:
        logger.error(f"Error retrieving prediction history: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/predictions/stats', methods=['GET'])
def get_prediction_stats():
    """Get prediction statistics"""
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Get total predictions
            cursor.execute("SELECT COUNT(*) FROM predictions;")
            total_predictions = cursor.fetchone()[0]
            
            # Get predictions by class
            cursor.execute("""
                SELECT predicted_class, COUNT(*) 
                FROM predictions 
                GROUP BY predicted_class 
                ORDER BY COUNT(*) DESC;
            """)
            class_counts = dict(cursor.fetchall())
            
            # Get recent predictions (last 24 hours)
            cursor.execute("""
                SELECT COUNT(*) 
                FROM predictions 
                WHERE timestamp > NOW() - INTERVAL '24 hours';
            """)
            recent_predictions = cursor.fetchone()[0]
            
            return jsonify({
                'total_predictions': total_predictions,
                'predictions_by_class': class_counts,
                'recent_predictions_24h': recent_predictions,
                'timestamp': datetime.now().isoformat()
            })
            
    except Exception as e:
        logger.error(f"Error retrieving prediction stats: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Load model on startup
    load_model()
    
    # Run the app
    app.run(host='0.0.0.0', port=5000, debug=False)