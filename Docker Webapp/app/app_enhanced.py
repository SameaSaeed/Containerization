from flask import Flask, render_template, request, jsonify, session
import os
import sqlite3
import redis
from datetime import datetime
import json

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-in-production'

# Database configuration
DATABASE = '/app/data/visitors.db'

# Redis configuration
try:
    redis_client = redis.Redis(host='redis', port=6379, db=0, decode_responses=True)
    redis_client.ping()
    REDIS_AVAILABLE = True
except:
    REDIS_AVAILABLE = False

def init_db():
    """Initialize the database with a visitors table"""
    os.makedirs('/app/data', exist_ok=True)
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS visitors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ip_address TEXT,
            visit_time TIMESTAMP,
            user_agent TEXT,
            session_id TEXT
        )
    ''')
    conn.commit()
    conn.close()

def log_visitor(ip_address, user_agent, session_id):
    """Log visitor information to database"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO visitors (ip_address, visit_time, user_agent, session_id)
        VALUES (?, ?, ?, ?)
    ''', (ip_address, datetime.now(), user_agent, session_id))
    conn.commit()
    conn.close()

def get_visitor_count():
    """Get total number of visitors"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM visitors')
    count = cursor.fetchone()[0]
    conn.close()
    return count

def increment_page_views():
    """Increment page views counter in Redis"""
    if REDIS_AVAILABLE:
        try:
            return redis_client.incr('page_views')
        except:
            return 0
    return 0

@app.route('/')
def home():
    """Main page route"""
    # Generate session ID if not exists
    if 'session_id' not in session:
        session['session_id'] = os.urandom(16).hex()
    
    # Log the visitor
    ip_address = request.environ.get('HTTP_X_FORWARDED_FOR', request.remote_addr)
    user_agent = request.environ.get('HTTP_USER_AGENT', 'Unknown')
    log_visitor(ip_address, user_agent, session['session_id'])
    
    # Get statistics
    visitor_count = get_visitor_count()
    page_views = increment_page_views()
    
    return f'''
    <html>
    <head>
        <title>Enhanced Flask Docker App</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }}
            .container {{ background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            h1 {{ color: #333; }}
            .info {{ background-color: #e7f3ff; padding: 15px; border-radius: 5px; margin: 20px 0; }}
            .status {{ background-color: #d4edda; padding: 10px; border-radius: 5px; margin: 10px 0; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Enhanced Flask Docker Application!</h1>
            <div class="info">
                <p><strong>Application Status:</strong> Running in Docker Container</p>
                <p><strong>Total Visitors:</strong> {visitor_count}</p>
                <p><strong>Page Views:</strong> {page_views}</p>
                <p><strong>Your IP:</strong> {ip_address}</p>
                <p><strong>Session ID:</strong> {session['session_id'][:8]}...</p>
            </div>
            <div class="status">
                <p><strong>Redis Status:</strong> {'Connected' if REDIS_AVAILABLE else 'Not Available'}</p>
                <p><strong>Database:</strong> SQLite Connected</p>
            </div>
            <p>This enhanced Flask application demonstrates:</p>
            <ul>
                <li>Multi-container deployment with Docker Compose</li>
                <li>Redis integration for session management</li>
                <li>Nginx reverse proxy configuration</li>
                <li>Persistent data storage</li>
                <li>Container networking</li>
            </ul>
            <p><a href="/visitors">View Recent Visitors</a> | <a href="/stats">View Statistics</a></p>
        </div>
    </body>
    </html>
    '''

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'visitors': get_visitor_count(),
        'redis_available': REDIS_AVAILABLE,
        'page_views': increment_page_views() if REDIS_AVAILABLE else 0
    })

@app.route('/stats')
def stats():
    """Statistics page"""
    visitor_count = get_visitor_count()
    page_views = redis_client.get('page_views') if REDIS_AVAILABLE else 0
    
    return jsonify({
        'total_visitors': visitor_count,
        'total_page_views': int(page_views) if page_views else 0,
        'redis_status': 'connected' if REDIS_AVAILABLE else 'disconnected',
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=False)