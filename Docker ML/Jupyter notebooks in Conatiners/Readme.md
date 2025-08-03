1. **Set up**

\# Check Docker version

docker --version



\# Pull the Jupyter base notebook image

docker pull jupyter/base-notebook



\# Verify the image was downloaded successfully

docker images | grep jupyter



\# Inspect the Jupyter image

docker inspect jupyter/base-notebook



\# Check image layers and history

docker history jupyter/base-notebook



**2. Project Structure**

\# Create a directory for our ML projects

mkdir -p ~/ml-docker-lab

cd ~/ml-docker-lab



\# Create subdirectories for organization

mkdir notebooks data models



**3. Run the Jupyter Container**

\# Run Jupyter container with volume mounting

docker run -d \\

&nbsp; --name jupyter-ml-lab \\

&nbsp; -p 8888:8888 \\

&nbsp; -v ~/ml-docker-lab:/home/jovyan/work \\

&nbsp; -e JUPYTER\_ENABLE\_LAB=yes \\

&nbsp; jupyter/base-notebook



&nbsp;	OR



\# Build the custom Docker image (ML libraries installed)

docker build -t jupyter-ml-custom:latest .



\# Run container from custom image

docker run -d \\

&nbsp; --name jupyter-ml-custom \\

&nbsp; -p 8888:8888 \\

&nbsp; -v ~/ml-docker-lab:/home/jovyan/work \\

&nbsp; -e JUPYTER\_ENABLE\_LAB=yes \\

&nbsp; jupyter-ml-custom:latest



\# Get the Jupyter access token

docker logs jupyter-ml-lab 2>\&1 | grep -E "token=" | tail -1



Note: Copy the complete URL with the token - you'll need this to access Jupyter in your browser.



Subtask 2.4: Access Jupyter in Browser

Open your web browser

Navigate to http://localhost:8888 or use the complete URL with token from the previous step

You should see the JupyterLab interface with your mounted work directory



**4. Setup ML base inside container**



\# Execute bash shell inside the running container

docker exec -it jupyter-ml-lab bash



\# Update pip to latest version

pip install --upgrade pip



\# Install TensorFlow

pip install tensorflow==2.13.0



\# Install Scikit-learn and additional ML libraries

pip install scikit-learn pandas numpy matplotlib seaborn



\# Install additional useful libraries

pip install plotly jupyter-widgets



\# Verify installations

pip list | grep -E "(tensorflow|scikit-learn|pandas|numpy)"



\# Exit the container terminal

exit



\# Restart the container to ensure all libraries are properly loaded

docker restart jupyter-ml-lab



\# Wait a few seconds, then get the new access token

sleep 5

docker logs jupyter-ml-lab 2>\&1 | grep -E "token=" | tail -1



**5. Build and Train a Model in Jupyter**



a. Create a New Notebook



Access Jupyter in your browser using the new token

Navigate to the work folder

Click New → Python 3 to create a new notebook

Rename the notebook to ml-docker-demo.ipynb



b. Import necessary libraries



import numpy as np

import pandas as pd

import matplotlib.pyplot as plt

import seaborn as sns

from sklearn.datasets import make\_classification

from sklearn.model\_selection import train\_test\_split

from sklearn.ensemble import RandomForestClassifier

from sklearn.metrics import accuracy\_score, classification\_report, confusion\_matrix

import joblib

import os



\# Set random seed for reproducibility

np.random.seed(42)



print("All libraries imported successfully!")

print(f"Current working directory: {os.getcwd()}")



c. Generate Sample Dataset



\# Generate a synthetic classification dataset

X, y = make\_classification(

&nbsp;   n\_samples=1000,

&nbsp;   n\_features=20,

&nbsp;   n\_informative=15,

&nbsp;   n\_redundant=5,

&nbsp;   n\_classes=2,

&nbsp;   random\_state=42

)



\# Create a DataFrame for better handling

feature\_names = \[f'feature\_{i}' for i in range(X.shape\[1])]

df = pd.DataFrame(X, columns=feature\_names)

df\['target'] = y



print(f"Dataset shape: {df.shape}")

print(f"Target distribution:\\n{df\['target'].value\_counts()}")

df.head()



d. Explore the Data



\# Basic statistics

print("Dataset Statistics:")

print(df.describe())



\# Visualize target distribution

plt.figure(figsize=(10, 4))



plt.subplot(1, 2, 1)

df\['target'].value\_counts().plot(kind='bar')

plt.title('Target Distribution')

plt.xlabel('Class')

plt.ylabel('Count')



plt.subplot(1, 2, 2)

\# Correlation heatmap of first 10 features

correlation\_matrix = df.iloc\[:, :10].corr()

sns.heatmap(correlation\_matrix, annot=True, cmap='coolwarm', center=0)

plt.title('Feature Correlation Heatmap')



plt.tight\_layout()

plt.show()



e. Train the Machine Learning Model



\# Split the data into training and testing sets

X\_train, X\_test, y\_train, y\_test = train\_test\_split(

&nbsp;   X, y, test\_size=0.2, random\_state=42, stratify=y

)



print(f"Training set size: {X\_train.shape\[0]}")

print(f"Testing set size: {X\_test.shape\[0]}")



\# Create and train the Random Forest model

rf\_model = RandomForestClassifier(

&nbsp;   n\_estimators=100,

&nbsp;   random\_state=42,

&nbsp;   max\_depth=10

)



\# Train the model

print("Training the model...")

rf\_model.fit(X\_train, y\_train)

print("Model training completed!")



\# Make predictions

y\_pred = rf\_model.predict(X\_test)



\# Calculate accuracy

accuracy = accuracy\_score(y\_test, y\_pred)

print(f"Model Accuracy: {accuracy:.4f}")



f. Evaluate Model Performance



\# Detailed classification report

print("Classification Report:")

print(classification\_report(y\_test, y\_pred))



\# Confusion Matrix

plt.figure(figsize=(8, 6))

cm = confusion\_matrix(y\_test, y\_pred)

sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')

plt.title('Confusion Matrix')

plt.xlabel('Predicted')

plt.ylabel('Actual')

plt.show()



\# Feature importance

feature\_importance = pd.DataFrame({

&nbsp;   'feature': feature\_names,

&nbsp;   'importance': rf\_model.feature\_importances\_

}).sort\_values('importance', ascending=False)



plt.figure(figsize=(10, 6))

sns.barplot(data=feature\_importance.head(10), x='importance', y='feature')

plt.title('Top 10 Feature Importances')

plt.xlabel('Importance')

plt.show()



print("Top 10 Most Important Features:")

print(feature\_importance.head(10))



g. Save Trained Model to Volume for Persistence



1\.

\# Create models directory if it doesn't exist

models\_dir = '/home/jovyan/work/models'

os.makedirs(models\_dir, exist\_ok=True)



\# Save the trained model

model\_path = os.path.join(models\_dir, 'random\_forest\_model.joblib')

joblib.dump(rf\_model, model\_path)



print(f"Model saved to: {model\_path}")



\# Save model metadata

metadata = {

&nbsp;   'model\_type': 'RandomForestClassifier',

&nbsp;   'accuracy': accuracy,

&nbsp;   'n\_features': X.shape\[1],

&nbsp;   'n\_samples\_train': X\_train.shape\[0],

&nbsp;   'n\_samples\_test': X\_test.shape\[0],

&nbsp;   'feature\_names': feature\_names

}



import json

metadata\_path = os.path.join(models\_dir, 'model\_metadata.json')

with open(metadata\_path, 'w') as f:

&nbsp;   json.dump(metadata, f, indent=2)



print(f"Model metadata saved to: {metadata\_path}")



2\. Test Model Loading

Verify that the saved model can be loaded and used:



\# Load the saved model

loaded\_model = joblib.load(model\_path)



\# Load metadata

with open(metadata\_path, 'r') as f:

&nbsp;   loaded\_metadata = json.load(f)



print("Loaded model metadata:")

for key, value in loaded\_metadata.items():

&nbsp;   print(f"  {key}: {value}")



\# Test the loaded model

test\_predictions = loaded\_model.predict(X\_test\[:5])

print(f"\\nTest predictions on first 5 samples: {test\_predictions}")

print(f"Actual values: {y\_test\[:5]}")



\# Verify accuracy matches

loaded\_accuracy = accuracy\_score(y\_test, loaded\_model.predict(X\_test))

print(f"\\nLoaded model accuracy: {loaded\_accuracy:.4f}")

print(f"Original model accuracy: {accuracy:.4f}")

print(f"Accuracy match: {abs(loaded\_accuracy - accuracy) < 1e-10}")



3\. Save your notebook to preserve all the work:



Click File → Save and Checkpoint in Jupyter

The notebook is automatically saved to the mounted volume



Verify Persistence on Host System: Check the contents of our project directory

ls -la ~/ml-docker-lab/



\# Check notebooks directory

ls -la ~/ml-docker-lab/notebooks/



\# Check models directory

ls -la ~/ml-docker-lab/models/



\# View model metadata

cat ~/ml-docker-lab/models/model\_metadata.json



##### Troubleshooting



**Issue 1: Port Already in Use**

If port 8888 is already in use:



\# Check what's using port 8888

sudo netstat -tulpn | grep 8888



\# Use a different port

docker run -d \\

&nbsp; --name jupyter-ml-lab \\

&nbsp; -p 8889:8888 \\

&nbsp; -v ~/ml-docker-lab:/home/jovyan/work \\

&nbsp; jupyter/base-notebook



**Issue 2: Permission Issues with Volumes**

If you encounter permission issues:



\# Fix ownership of the mounted directory

sudo chown -R 1000:1000 ~/ml-docker-lab



\# Or run container with specific user ID

docker run -d \\

&nbsp; --name jupyter-ml-lab \\

&nbsp; -p 8888:8888 \\

&nbsp; -v ~/ml-docker-lab:/home/jovyan/work \\

&nbsp; --user $(id -u):$(id -g) \\

&nbsp; jupyter/base-notebook



**Issue 3: Container Won't Start**

Check container logs for errors:



\# View container logs

docker logs jupyter-ml-lab



\# Check container status

docker ps -a

