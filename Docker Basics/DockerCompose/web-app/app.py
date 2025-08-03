from flask import Flask, request, jsonify
import redis
import psycopg2
import os
import json
from datetime import datetime

app = Flask(__name__)

# Redis connection
redis_client = redis.Redis(
    host=os.getenv('REDIS_HOST', 'redis'),
    port=int(os.getenv('REDIS_PORT', 6379)),
    decode_responses=True
)

# PostgreSQL connection parameters
db_params = {
    'host': os.getenv('POSTGRES_HOST', 'postgres'),
    'database': os.getenv('POSTGRES_DB', 'appdb'),
    'user': os.getenv('POSTGRES_USER', 'appuser'),
    'password': os.getenv('POSTGRES_PASSWORD', 'apppass'),
    'port': int(os.getenv('POSTGRES_PORT', 5432))
}

@app.route('/')
def home():
    return jsonify({
        'message': 'Complex Application with Redis and PostgreSQL',
        'timestamp': datetime.now().isoformat(),
        'services': ['web', 'redis', 'postgres']
    })

@app.route('/cache/<key>')
def get_cache(key):
    try:
        value = redis_client.get(key)
        return jsonify({
            'key': key,
            'value': value,
            'cached': value is not None
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/cache/<key>/<value>')
def set_cache(key, value):
    try:
        redis_client.set(key, value, ex=300)  # Expire in 5 minutes
        return jsonify({
            'message': f'Cached {key} = {value}',
            'expiry': '5 minutes'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/users')
def get_users():
    try:
        conn = psycopg2.connect(**db_params)
        cur = conn.cursor()
        cur.execute('SELECT id, name, email, created_at FROM users ORDER BY created_at DESC')
        users = cur.fetchall()
        cur.close()
        conn.close()
        
        user_list = []
        for user in users:
            user_list.append({
                'id': user[0],
                'name': user[1],
                'email': user[2],
                'created_at': user[3].isoformat() if user[3] else None
            })
        
        return jsonify({'users': user_list})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/users', methods=['POST'])
def create_user():
    try:
        data = request.get_json()
        name = data.get('name')
        email = data.get('email')
        
        if not name or not email:
            return jsonify({'error': 'Name and email are required'}), 400
        
        conn = psycopg2.connect(**db_params)
        cur = conn.cursor()
        cur.execute(
            'INSERT INTO users (name, email, created_at) VALUES (%s, %s, %s) RETURNING id',
            (name, email, datetime.now())
        )
        user_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({
            'message': 'User created successfully',
            'user_id': user_id,
            'name': name,
            'email': email
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health_check():
    health_status = {'web': 'healthy'}
    
    # Check Redis
    try:
        redis_client.ping()
        health_status['redis'] = 'healthy'
    except:
        health_status['redis'] = 'unhealthy'
    
    # Check PostgreSQL
    try:
        conn = psycopg2.connect(**db_params)
        conn.close()
        health_status['postgres'] = 'healthy'
    except:
        health_status['postgres'] = 'unhealthy'
    
    return jsonify(health_status)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)