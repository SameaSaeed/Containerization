#!/usr/bin/env python3

import subprocess
import json
import time
from datetime import datetime

class KafkaMonitor:
    def __init__(self, kafka_container='kafka-broker'):
        self.kafka_container = kafka_container
        
    def get_topic_info(self):
        """Get information about all topics"""
        try:
            cmd = f"docker exec {self.kafka_container} kafka-topics --bootstrap-server localhost:9092 --describe"
            result = subprocess.run(cmd.split(), capture_output=True, text=True)
            return result.stdout
        except Exception as e:
            print(f"Error getting topic info: {e}")
            return None
    
    def get_consumer_groups(self):
        """Get consumer group information"""
        try:
            cmd = f"docker exec {self.kafka_container} kafka-consumer-groups --bootstrap-server localhost:9092 --list"
            result = subprocess.run(cmd.split(), capture_output=True, text=True)
            return result.stdout.strip().split('\n')
        except Exception as e:
            print(f"Error getting consumer groups: {e}")
            return []
    
    def get_consumer_group_details(self, group_id):
        """Get detailed information about a consumer group"""
        try:
            cmd = f"docker exec {self.kafka_container} kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group {group_id}"
            result = subprocess.run(cmd.split(), capture_output=True, text=True)
            return result.stdout
        except Exception as e:
            print(f"Error getting consumer group details: {e}")
            return None
    
    def monitor_cluster(self):
        """Monitor cluster health"""
        print(f"=== Kafka Cluster Monitor - {datetime.now()} ===")
        
        # Topic information
        print("\n--- Topic Information ---")
        topic_info = self.get_topic_info()
        if topic_info:
            print(topic_info)
        
        # Consumer groups
        print("\n--- Consumer Groups ---")
        groups = self.get_consumer_groups()
        for group in groups:
            if group.strip():
                print(f"\nGroup: {group}")
                details = self.get_consumer_group_details(group)
                if details:
                    print(details)

if __name__ == "__main__":
    monitor = KafkaMonitor()
    monitor.monitor_cluster()