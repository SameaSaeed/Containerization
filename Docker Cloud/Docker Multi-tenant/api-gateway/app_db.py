from flask import Flask, request, jsonify, abort
import psycopg2
import jwt
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-change-in-production'

# Database connection parameters
DB_CONFIG = {
    'host': 'shared-db-compose',
    'database': 'multitenantdb',
    'user': 'dbadmin',
    'password': 'securepassword123'
}

# Tenant schema mappings
TENANT_SCHEMAS = {
    'tenant-a': 'tenant_a',
    'tenant-b': 'tenant_b',
    'tenant-c': 'tenant_c'
}

def verify_token(token):
    try:
        payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
        return payload['tenant_id']
    except:
        return None

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

@app.route('/db/<tenant_id>/query', methods=['POST'])
def execute_query(tenant_id):
    # Verify authentication
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        abort(401, description="Missing or invalid Authorization header")
    
    token = auth_header.split(' ')[1]
    verified_tenant = verify_token(token)
    if verified_tenant != tenant_id:
        abort(403, description="Token does not match tenant")

    # Ensure tenant_id is valid
    schema_name = TENANT_SCHEMAS.get(tenant_id)
    if not schema_name:
        abort(404, description="Tenant not found")

    # Get SQL query from request
    data = request.get_json()
    sql_query = data.get('query')
    if not sql_query:
        abort(400, description="Missing SQL query")

    try:
        conn = get_db_connection()
        conn.autocommit = True
        with conn.cursor() as cur:
            # Set schema for the tenant
            cur.execute(f"SET search_path TO {schema_name}")
            cur.execute(sql_query)
            
            # If it's a SELECT, fetch and return the results
            if sql_query.strip().lower().startswith('select'):
                rows = cur.fetchall()
                columns = [desc[0] for desc in cur.description]
                results = [dict(zip(columns, row)) for row in rows]
                return jsonify(results), 200
            else:
                return jsonify({'message': 'Query executed successfully'}), 200
    except Exception as e:
        print(f"Error executing query: {e}")
        abort(500, description=str(e))
    finally:
        if conn:
            conn.close()
