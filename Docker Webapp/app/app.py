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
            ip_address TEXT,
            visit_time TIMESTAMP,
            user_agent TEXT
        )
    ''')
    conn.commit()
    conn.close()

def log_visitor(ip_address, user_agent):
    """Log visitor information to database"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO visitors (ip_address, visit_time, user_agent)
        VALUES (?, ?, ?)
    ''', (ip_address, datetime.now(), user_agent))
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

@app.route('/')
def home():
    """Main page route"""
    # Log the visitor
    ip_address = request.environ.get('HTTP_X_FORWARDED_FOR', request.remote_addr)
    user_agent = request.environ.get('HTTP_USER_AGENT', 'Unknown')
    log_visitor(ip_address, user_agent)
    
    # Get visitor count
    visitor_count = get_visitor_count()
    
    return f'''
    <html>
    <head>
        <title>Flask Docker App</title>
        <style>
            body {{ font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }}
            .container {{ background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            h1 {{ color: #333; }}
            .info {{ background-color: #e7f3ff; padding: 15px; border-radius: 5px; margin: 20px 0; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Welcome to Flask Docker Application!</h1>
            <div class="info">
                <p><strong>Application Status:</strong> Running in Docker Container</p>
                <p><strong>Total Visitors:</strong> {visitor_count}</p>
                <p><strong>Your IP:</strong> {ip_address}</p>
            </div>
            <p>This is a simple Flask web application running inside a Docker container.</p>
            <p>The application demonstrates:</p>
            <ul>
                <li>Web application containerization</li>
                <li>Database integration with SQLite</li>
                <li>Visitor tracking functionality</li>
                <li>Port mapping and networking</li>
            </ul>
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
        'visitors': get_visitor_count()
    })

@app.route('/visitors')
def visitors():
    """Display recent visitors"""
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM visitors ORDER BY visit_time DESC LIMIT 10')
    recent_visitors = cursor.fetchall()
    conn.close()
    
    html = '<html><head><title>Recent Visitors</title></head><body>'
    html += '<h1>Recent Visitors</h1>'
    html += '<table border="1"><tr><th>ID</th><th>IP Address</th><th>Visit Time</th><th>User Agent</th></tr>'
    
    for visitor in recent_visitors:
        html += f'<tr><td>{visitor[0]}</td><td>{visitor[1]}</td><td>{visitor[2]}</td><td>{visitor[3][:50]}...</td></tr>'
    
    html += '</table><br><a href="/">Back to Home</a></body></html>'
    return html

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)