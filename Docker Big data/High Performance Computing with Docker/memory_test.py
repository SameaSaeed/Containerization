#!/usr/bin/env python3
from mpi4py import MPI
import numpy as np
import time

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

# Memory bandwidth test
def memory_bandwidth_test(array_size):
    # Create large arrays
    a = np.random.rand(array_size)
    b = np.random.rand(array_size)
    
    start_time = time.time()
    
    # Perform memory-intensive operations
    for i in range(10):
        c = a + b
        d = c * 2.0
        e = np.sqrt(d)
    
    end_time = time.time()
    
    return end_time - start_time

if __name__ == "__main__":
    array_size = 10000000  # 10M elements
    
    local_time = memory_bandwidth_test(array_size)
    
    # Gather all times to rank 0
    all_times = comm.gather(local_time, root=0)
    
    if rank == 0:
        avg_time = sum(all_times) / len(all_times)
        max_time = max(all_times)
        min_time = min(all_times)
        
        print(f"Memory Bandwidth Test Results:")
        print(f"Processes: {size}")
        print(f"Array size per process: {array_size}")
        print(f"Average time: {avg_time:.4f} seconds")
        print(f"Min time: {min_time:.4f} seconds")
        print(f"Max time: {max_time:.4f} seconds")
        print(f"Load balance efficiency: {min_time/max_time:.4f}")