from flask import Flask, render_template, request, jsonify
import os
import sqlite3
from datetime import datetime

app = Flask(__name__)

# Database configuration
DATABASE = '/app/data/visitors.db'

def init_db():
    """Initialize the database with a visitors table"""
    os.makedirs('/app/data', exist_ok=True)
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS visitors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def add_visitor(name):
    """Add a visitor to the database"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('INSERT INTO visitors (name) VALUES (?)', (name,))
    conn.commit()
    conn.close()

def get_visitors():
    """Get all visitors from the database"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('SELECT name, visit_time FROM visitors ORDER BY visit_time DESC')
    visitors = cursor.fetchall()
    conn.close()
    return visitors

@app.route('/')
def home():
    """Home page route"""
    visitors = get_visitors()
    return render_template('index.html', visitors=visitors)

@app.route('/add_visitor', methods=['POST'])
def add_visitor_route():
    """Add visitor route"""
    name = request.form.get('name')
    if name:
        add_visitor(name)
        return jsonify({'status': 'success', 'message': f'Welcome {name}!'})
    return jsonify({'status': 'error', 'message': 'Name is required'})

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)