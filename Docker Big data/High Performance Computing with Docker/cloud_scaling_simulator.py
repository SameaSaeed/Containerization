#!/usr/bin/env python3
import subprocess
import time
import json
import sys

class CloudHPCManager:
    def __init__(self):
        self.current_workers = 0
        self.max_workers = 10
        self.min_workers = 1
        
    def get_current_load(self):
        """Simulate getting current system load"""
        try:
            # Get CPU usage from containers
            result = subprocess.run(['docker', 'stats', '--no-stream', '--format', 
                                   'json'], capture_output=True, text=True)
            if result.returncode == 0:
                stats = []
                for line in result.stdout.strip().split('\n'):
                    if line:
                        stats.append(json.loads(line))
                
                if stats:
                    cpu_usage = sum(float(stat['CPUPerc'].rstrip('%')) for stat in stats) / len(stats)
                    return cpu_usage
            return 0.0
        except Exception as e:
            print(f"Error getting load: {e}")
            return 0.0
    
    def scale_workers(self, target_count):
        """Scale the number of worker containers"""
        if target_count == self.current_workers:
            return
            
        print(f"Scaling workers from {self.current_workers} to {target_count}")
        
        try:
            # Use docker service scale (assuming swarm mode)
            subprocess.run(['docker', 'service', 'scale', 
                          f'hpc-stack_hpc-service={target_count + 1}'], 
                          check=True)
            self.current_workers = target_count
            print(f"Successfully scaled to {target_count} workers")
        except subprocess.CalledProcessError as e:
            print(f"Error scaling workers: {e}")
    
    def auto_scale(self):
        """Auto-scaling logic based on load"""
        load = self.get_current_load()
        print(f"Current average CPU load: {load:.2f}%")
        
        if load > 80 and self.current_workers < self.max_workers:
            # Scale up
            new_count = min(self.current_workers + 2, self.max_workers)
            self.scale_workers(new_count)
        elif load < 20 and self.current_workers > self.min_workers:
            # Scale down
            new_count = max(self.current_workers - 1, self.min_workers)
            self.scale_workers(new_count)
    
    def monitor_and_scale(self, duration=300):
        """Monitor system and auto-scale for specified duration"""
        print(f"Starting auto-scaling monitor for {duration} seconds")
        start_time = time.time()
        
        while time.time() - start_time < duration:
            self.auto_scale()
            time.sleep(30)  # Check every 30 seconds
        
        print("Auto-scaling monitor stopped")

if __name__ == "__main__":
    manager = CloudHPCManager()
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "scale":
            target = int(sys.argv[2]) if len(sys.argv) > 2 else 3
            manager.scale_workers(target)
        elif sys.argv[1] == "monitor":
            duration = int(sys.argv[2]) if len(sys.argv) > 2 else 300
            manager.monitor_and_scale(duration)
        elif sys.argv[1] == "status":
            load = manager.get_current_load()
            print(f"Current load: {load:.2f}%")
            print(f"Current workers: {manager.current_workers}")
    else:
        print("Usage:")
        print("  python3 cloud_scaling_simulator.py scale [count]")
        print("  python3 cloud_scaling_simulator.py monitor [duration]")
        print("  python3 cloud_scaling_simulator.py status")