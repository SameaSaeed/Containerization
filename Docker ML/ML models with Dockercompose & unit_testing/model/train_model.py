import pickle
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import joblib

def train_iris_model():
    """Train a simple iris classification model"""
    
    # Load the iris dataset
    iris = load_iris()
    X, y = iris.data, iris.target
    
    # Split the data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    # Train the model
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Test the model
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"Model accuracy: {accuracy:.2f}")
    
    # Save the model
    joblib.dump(model, 'iris_model.pkl')
    
    # Save feature names and target names for reference
    model_info = {
        'feature_names': iris.feature_names,
        'target_names': iris.target_names.tolist(),
        'accuracy': accuracy
    }
    
    with open('model_info.pkl', 'wb') as f:
        pickle.dump(model_info, f)
    
    print("Model saved successfully!")
    return model, model_info

if __name__ == "__main__":
    train_iris_model()