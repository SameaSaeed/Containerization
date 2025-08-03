from flask import Flask, render_template, request, jsonify
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
import time

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'postgres-db'),
    'database': os.getenv('DB_NAME', 'flaskapp'),
    'user': os.getenv('DB_USER', 'flaskuser'),
    'password': os.getenv('DB_PASSWORD', 'flaskpass'),
    'port': os.getenv('DB_PORT', '5432')
}

def wait_for_db():
    """Wait for database to be ready"""
    max_retries = 30
    for i in range(max_retries):
        try:
            conn = psycopg2.connect(**DB_CONFIG)
            conn.close()
            print("Database connection successful!")
            return True
        except psycopg2.OperationalError:
            print(f"Database not ready, retrying... ({i+1}/{max_retries})")
            time.sleep(2)
    return False

def init_db():
    """Initialize the database with a visitors table"""
    if not wait_for_db():
        raise Exception("Could not connect to database")
    
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS visitors (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def add_visitor(name):
    """Add a visitor to the database"""
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor()
    cursor.execute('INSERT INTO visitors (name) VALUES (%s)', (name,))
    conn.commit()
    conn.close()

def get_visitors():
    """Get all visitors from the database"""
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    cursor.execute('SELECT name, visit_time FROM visitors ORDER BY visit_time DESC LIMIT 10')
    visitors = cursor.fetchall()
    conn.close()
    return visitors

@app.route('/')
def home():
    """Home page route"""
    try:
        visitors = get_visitors()
        return render_template('index.html', visitors=visitors)
    except Exception as e:
        return f"Database error: {str(e)}", 500

@app.route('/add_visitor', methods=['POST'])
def add_visitor_route():
    """Add visitor route"""
    try:
        name = request.form.get('name')
        if name:
            add_visitor(name)
            return jsonify({'status': 'success', 'message': f'Welcome {name}!'})
        return jsonify({'status': 'error', 'message': 'Name is required'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Database error: {str(e)}'})

@app.route('/health')
def health_check():
    """Health check endpoint"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.close()
        return jsonify({'status': 'healthy', 'database': 'connected', 'timestamp': datetime.now().isoformat()})
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'database': 'disconnected', 'error': str(e)}), 500

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)