#!/usr/bin/env python3

import json
import logging
from kafka import KafkaConsumer, KafkaProducer
from collections import defaultdict, deque
from datetime import datetime, timedelta
import threading
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class StreamProcessor:
    def __init__(self):
        # Consumer for input data
        self.consumer = KafkaConsumer(
            'sensor-data',
            bootstrap_servers=['kafka:29092'],
            value_deserializer=lambda m: json.loads(m.decode('utf-8')),
            key_deserializer=lambda k: k.decode('utf-8') if k else None,
            group_id='stream-processor-group',
            auto_offset_reset='latest'
        )
        
        # Producer for processed data
        self.producer = KafkaProducer(
            bootstrap_servers=['kafka:29092'],
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None
        )
        
        # In-memory storage for windowed aggregations
        self.sensor_data = defaultdict(lambda: deque(maxlen=10))  # Keep last 10 readings per sensor
        self.alerts_sent = set()
        
    def process_sensor_reading(self, key, data):
        """Process individual sensor reading"""
        try:
            sensor_id = data.get('sensor_id')
            temperature = data.get('temperature', 0)
            humidity = data.get('humidity', 0)
            timestamp = data.get('timestamp')
            location = data.get('location')
            
            # Add to sliding window
            self.sensor_data[sensor_id].append({
                'temperature': temperature,
                'humidity': humidity,
                'timestamp': timestamp
            })
            
            # Calculate moving average
            readings = list(self.sensor_data[sensor_id])
            avg_temp = sum(r['temperature'] for r in readings) / len(readings)
            avg_humidity = sum(r['humidity'] for r in readings) / len(readings)
            
            # Create processed record
            processed_data = {
                'sensor_id': sensor_id,
                'location': location,
                'current_temperature': temperature,
                'current_humidity': humidity,
                'avg_temperature': round(avg_temp, 2),
                'avg_humidity': round(avg_humidity, 2),
                'reading_count': len(readings),
                'processed_at': datetime.now().isoformat()
            }
            
            # Send to processed data topic
            self.producer.send('processed-sensor-data', key=sensor_id, value=processed_data)
            
            # Check for alerts
            self.check_alerts(sensor_id, processed_data)
            
            logger.info(f"Processed data for {sensor_id}: Avg Temp={avg_temp:.2f}°C")
            
        except Exception as e:
            logger.error(f"Error processing sensor reading: {e}")
    
    def check_alerts(self, sensor_id, data):
        """Check for alert conditions"""
        try:
            alert_key = f"{sensor_id}_{datetime.now().strftime('%Y%m%d%H')}"  # One alert per sensor per hour
            
            # Temperature alert
            if data['avg_temperature'] > 32 and alert_key not in self.alerts_sent:
                alert = {
                    'alert_type': 'HIGH_TEMPERATURE',
                    'sensor_id': sensor_id,
                    'location': data['location'],
                    'current_value': data['current_temperature'],
                    'average_value': data['avg_temperature'],
                    'threshold': 32,
                    'severity': 'HIGH',
                    'timestamp': datetime.now().isoformat()
                }
                
                self.producer.send('sensor-alerts', key=sensor_id, value=alert)
                self.alerts_sent.add(alert_key)
                logger.warning(f"HIGH TEMPERATURE ALERT: {alert}")
            
            # Humidity alert
            if data['avg_humidity'] > 85 and f"humidity_{alert_key}" not in self.alerts_sent:
                alert = {
                    'alert_type': 'HIGH_HUMIDITY',
                    'sensor_id': sensor_id,
                    'location': data['location'],
                    'current_value': data['current_humidity'],
                    'average_value': data['avg_humidity'],
                    'threshold': 85,
                    'severity': 'MEDIUM',
                    'timestamp': datetime.now().isoformat()
                }
                
                self.producer.send('sensor-alerts', key=sensor_id, value=alert)
                self.alerts_sent.add(f"humidity_{alert_key}")
                logger.warning(f"HIGH HUMIDITY ALERT: {alert}")
                
        except Exception as e:
            logger.error(f"Error checking alerts: {e}")
    
    def cleanup_old_alerts(self):
        """Clean up old alert keys to prevent memory leaks"""
        current_hour = datetime.now().strftime('%Y%m%d%H')
        self.alerts_sent = {key for key in self.alerts_sent if current_hour in key}
    
    def start_processing(self):
        """Start the stream processing"""
        logger.info("Starting stream processor...")
        
        # Start cleanup thread
        cleanup_thread = threading.Thread(target=self.periodic_cleanup)
        cleanup_thread.daemon = True
        cleanup_thread.start()
        
        try:
            for message in self.consumer:
                self.process_sensor_reading(message.key, message.value)
                
        except KeyboardInterrupt:
            logger.info("Stream processor interrupted by user")
        except Exception as e:
            logger.error(f"Stream processing error: {e}")
        finally:
            self.consumer.close()
            self.producer.close()
    
    def periodic_cleanup(self):
        """Periodic cleanup of old data"""
        while True:
            time.sleep(3600)  # Run every hour
            self.cleanup_old_alerts()
            logger.info("Performed periodic cleanup")

if __name__ == "__main__":
    processor = StreamProcessor()
    processor.start_processing()