import pytest
import json
from src.app import app

@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_hello_endpoint(client):
    """Test the hello endpoint returns correct message."""
    response = client.get('/')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['message'] == 'Hello, World!'

def test_health_endpoint(client):
    """Test the health check endpoint."""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'

def test_add_numbers_endpoint(client):
    """Test the add numbers endpoint with various inputs."""
    # Test positive numbers
    response = client.get('/add/5/3')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['result'] == 8
    
    # Test negative numbers
    response = client.get('/add/-2/7')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['result'] == 5
    
    # Test zero
    response = client.get('/add/0/10')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['result'] == 10

def test_invalid_endpoint(client):
    """Test that invalid endpoints return 404."""
    response = client.get('/nonexistent')
    assert response.status_code == 404
