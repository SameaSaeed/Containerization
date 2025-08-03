FROM python:3.9-slim

WORKDIR /app

# Install required packages
RUN pip install kafka-python

# Copy application code
COPY stream_processor.py .

# Run the stream processor
CMD ["python", "stream_processor.py"]