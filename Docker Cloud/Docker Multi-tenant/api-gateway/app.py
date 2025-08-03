from flask import Flask, request, jsonify, abort
import requests
import jwt
import datetime
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-change-in-production'

# Tenant service mappings
TENANT_SERVICES = {
    'tenant-a': 'http://tenant-a-compose:5000',
    'tenant-b': 'http://tenant-b-compose:3000',
    'tenant-c': 'http://tenant-c-compose:80'
}

# Simple authentication
def generate_token(tenant_id):
    payload = {
        'tenant_id': tenant_id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=24)
    }
    return jwt.encode(payload, app.config['SECRET_KEY'], algorithm='HS256')

def verify_token(token):
    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        return payload['tenant_id']
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

@app.route('/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    tenant_id = data.get('tenant_id')
    password = data.get('password')
    
    # Simple authentication (in production, use proper authentication)
    if tenant_id in TENANT_SERVICES and password == 'password123':
        token = generate_token(tenant_id)
        return jsonify({'token': token, 'tenant_id': tenant_id})
    
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/<tenant_id>/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def proxy_request(tenant_id, path):
    # Verify authentication
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        abort(401)
    
    token = auth_header.split(' ')[1]
    authenticated_tenant = verify_token(token)
    
    if not authenticated_tenant:
        abort(401)
    
    # Check if tenant is authorized to access the requested service
    if authenticated_tenant != tenant_id:
        abort(403)
    
    # Check if tenant service exists
    if tenant_id not in TENANT_SERVICES:
        abort(404)
    
    # Proxy the request
    target_url = f"{TENANT_SERVICES[tenant_id]}/{path}"
    
    try:
        if request.method == 'GET':
            response = requests.get(target_url, params=request.args)
        elif request.method == 'POST':
            response = requests.post(target_url, json=request.get_json())
        elif request.method == 'PUT':
            response = requests.put(target_url, json=request.get_json())
        elif request.method == 'DELETE':
            response = requests.delete(target_url)
        
        return jsonify(response.json()), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({'error': 'Service unavailable'}), 503

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'service': 'api-gateway'})

@app.route('/')
def home():
    return jsonify({
        'service': 'Multi-Tenant API Gateway',
        'endpoints': {
            'auth': '/auth/login',
            'api': '/api/<tenant_id>/<path>',
            'health': '/health'
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)