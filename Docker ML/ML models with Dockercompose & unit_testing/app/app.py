from flask import Flask, request, jsonify
import joblib
import pickle
import numpy as np
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global variables for model and info
model = None
model_info = None

def load_model():
    """Load the trained model and model info"""
    global model, model_info
    
    try:
        # Load the model
        model = joblib.load('/app/model/iris_model.pkl')
        
        # Load model info
        with open('/app/model/model_info.pkl', 'rb') as f:
            model_info = pickle.load(f)
        
        logger.info("Model loaded successfully")
        logger.info(f"Model accuracy: {model_info['accuracy']:.2f}")
        
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        raise

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model_loaded': model is not None
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
    """Make predictions using the loaded model"""
    try:
        # Check if model is loaded
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500
        
        # Get JSON data from request
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Extract features
        if 'features' not in data:
            return jsonify({'error': 'Features not provided'}), 400
        
        features = data['features']
        
        # Validate feature count
        if len(features) != 4:
            return jsonify({
                'error': 'Expected 4 features',
                'expected_features': model_info['feature_names']
            }), 400
        
        # Convert to numpy array and reshape
        features_array = np.array(features).reshape(1, -1)
        
        # Make prediction
        prediction = model.predict(features_array)[0]
        prediction_proba = model.predict_proba(features_array)[0]
        
        # Get class name
        predicted_class = model_info['target_names'][prediction]
        
        # Create response
        response = {
            'prediction': int(prediction),
            'predicted_class': predicted_class,
            'probabilities': {
                model_info['target_names'][i]: float(prob) 
                for i, prob in enumerate(prediction_proba)
            },
            'features_used': {
                model_info['feature_names'][i]: float(features[i]) 
                for i in range(len(features))
            },
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"Prediction made: {predicted_class}")
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/predict/batch', methods=['POST'])
def predict_batch():
    """Make batch predictions"""
    try:
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500
        
        data = request.get_json()
        
        if not data or 'batch_features' not in data:
            return jsonify({'error': 'Batch features not provided'}), 400
        
        batch_features = data['batch_features']
        
        # Validate batch
        if not isinstance(batch_features, list):
            return jsonify({'error': 'Batch features must be a list'}), 400
        
        results = []
        
        for i, features in enumerate(batch_features):
            if len(features) != 4:
                results.append({
                    'index': i,
                    'error': 'Expected 4 features'
                })
                continue
            
            try:
                features_array = np.array(features).reshape(1, -1)
                prediction = model.predict(features_array)[0]
                prediction_proba = model.predict_proba(features_array)[0]
                predicted_class = model_info['target_names'][prediction]
                
                results.append({
                    'index': i,
                    'prediction': int(prediction),
                    'predicted_class': predicted_class,
                    'confidence': float(max(prediction_proba))
                })
                
            except Exception as e:
                results.append({
                    'index': i,
                    'error': str(e)
                })
        
        return jsonify({
            'results': results,
            'total_predictions': len(results),
            'timestamp': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Load model on startup
    load_model()
    
    # Run the app
    app.run(host='0.0.0.0', port=5000, debug=False)