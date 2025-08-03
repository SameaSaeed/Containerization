from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        'tenant': 'Tenant A - E-commerce Platform',
        'status': 'running',
        'port': os.environ.get('PORT', '5000'),
        'container_id': os.environ.get('HOSTNAME', 'unknown')
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'tenant': 'A'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))