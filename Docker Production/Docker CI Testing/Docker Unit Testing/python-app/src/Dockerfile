# Use Python 3.9 slim image as base
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONPATH=/app/src
ENV FLASK_APP=src/app.py

# Expose port 5000
EXPOSE 5000

# Default command to run tests
CMD ["python", "-m", "pytest", "tests/", "-v", "--tb=short"]