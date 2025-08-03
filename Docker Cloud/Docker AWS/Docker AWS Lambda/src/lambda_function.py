import json
import datetime
import os

def lambda_handler(event, context):
    """
    AWS Lambda function handler that processes incoming events
    """
    
    # Get current timestamp
    current_time = datetime.datetime.now().isoformat()
    
    # Extract information from the event
    http_method = event.get('httpMethod', 'Unknown')
    path = event.get('path', '/')
    
    # Get query parameters if they exist
    query_params = event.get('queryStringParameters') or {}
    
    # Create response data
    response_data = {
        'message': 'Hello from Dockerized Lambda!',
        'timestamp': current_time,
        'method': http_method,
        'path': path,
        'query_parameters': query_params,
        'container_info': {
            'python_version': os.sys.version,
            'environment': 'Docker Container'
        }
    }
    
    # Return proper API Gateway response format
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(response_data, indent=2)
    }