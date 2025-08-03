import requests
import json
import time

# API base URL
BASE_URL = "http://localhost"

def test_health_check():
    """Test health check endpoint"""
    print("Testing health check...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print("-" * 50)

def test_model_info():
    """Test model info endpoint"""
    print("Testing model info...")
    response = requests.get(f"{BASE_URL}/model/info")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print("-" * 50)

def test_single_prediction():
    """Test single prediction"""
    print("Testing single prediction...")
    
    # Test data for different iris types
    test_cases = [
        {
            "name": "Setosa",
            "features": [5.1, 3.5, 1.4, 0.2]
        },
        {
            "name": "Versicolor", 
            "features": [6.2, 2.9, 4.3, 1.3]
        },
        {
            "name": "Virginica",
            "features": [7.3, 2.9, 6.3, 1.8]
        }
    ]
    
    for test_case in test_cases:
        print(f"Testing {test_case['name']}...")
        response = requests.post(
            f"{BASE_URL}/predict",
            json={"features": test_case["features"]}
        )
        print(f"Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Predicted: {result['predicted_class']}")
            print(f"Confidence: {max(result['probabilities'].values()):.2f}")
        else:
            print(f"Error: {response.text}")
        print("-" * 30)
    
    print("-" * 50)

def test_batch_prediction():
    """Test batch prediction"""
    print("Testing batch prediction...")
    
    batch_data = {
        "batch_features": [
            [5.1, 3.5, 1.4, 0.2],
            [6.2, 2.9, 4.3, 1.3],
            [7.3, 2.9, 6.3, 1.8],
            [5.0, 3.0, 1.6, 0.2]
        ]
    }
    
    response = requests.post(f"{BASE_URL}/predict/batch", json=batch_data)
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"Total predictions: {result['total_predictions']}")
        for pred in result['results']:
            if 'error' not in pred:
                print(f"Index {pred['index']}: {pred['predicted_class']} (confidence: {pred['confidence']:.2f})")
            else:
                print(f"Index {pred['index']}: Error - {pred['error']}")
    else:
        print(f"Error: {response.text}")
    
    print("-" * 50)

def test_prediction_history():
    """Test prediction history"""
    print("Testing prediction history...")
    response = requests.get(f"{BASE_URL}/predictions/history?limit=5")
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"Retrieved {result['total_returned']} predictions")
        for pred in result['predictions'][:3]:  # Show first 3
            print(f"ID: {pred['id']}, Class: {pred['predicted_class']}, Time: {pred['timestamp']}")
    else:
        print(f"Error: {response.text}")
    
    print("-" * 50)

def test_all():
    """Run all tests sequentially"""
    test_health_check()
    time.sleep(0.5)
    
    test_model_info()
    time.sleep(0.5)
    
    test_single_prediction()
    time.sleep(0.5)
    
    test_batch_prediction()
    time.sleep(0.5)
    
    test_prediction_history()

if __name__ == "__main__":
    test_all()
