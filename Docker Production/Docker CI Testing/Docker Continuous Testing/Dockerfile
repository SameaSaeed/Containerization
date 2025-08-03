FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy test files
COPY tests/ ./tests/
COPY conftest.py .

# Create directories for reports and screenshots
RUN mkdir -p reports screenshots

# Set environment variables
ENV PYTHONPATH=/app
ENV SELENIUM_HUB_URL=http://selenium-hub:4444/wd/hub

# Default command
CMD ["pytest", "tests/", "-v"]