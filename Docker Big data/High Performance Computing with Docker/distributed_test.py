#!/usr/bin/env python3
from mpi4py import MPI
import numpy as np
import time
import socket

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()
hostname = socket.gethostname()

def distributed_matrix_multiply(n):
    """Distributed matrix multiplication"""
    # Create matrices
    if rank == 0:
        A = np.random.rand(n, n)
        B = np.random.rand(n, n)
    else:
        A = None
        B = None
    
    # Broadcast matrices to all processes
    A = comm.bcast(A, root=0)
    B = comm.bcast(B, root=0)
    
    # Calculate portion of work for each process
    rows_per_proc = n // size
    start_row = rank * rows_per_proc
    end_row = start_row + rows_per_proc if rank < size - 1 else n
    
    # Perform local computation
    local_result = np.dot(A[start_row:end_row], B)
    
    # Gather results
    if rank == 0:
        result = np.zeros((n, n))
        result[start_row:end_row] = local_result
        
        for i in range(1, size):
            proc_start = i * rows_per_proc
            proc_end = proc_start + rows_per_proc if i < size - 1 else n
            received = comm.recv(source=i, tag=i)
            result[proc_start:proc_end] = received
    else:
        comm.send(local_result, dest=0, tag=rank)
    
    return result if rank == 0 else None

if __name__ == "__main__":
    matrix_size = 500
    
    start_time = time.time()
    result = distributed_matrix_multiply(matrix_size)
    end_time = time.time()
    
    if rank == 0:
        print(f"Distributed Matrix Multiplication Results:")
        print(f"Matrix size: {matrix_size}x{matrix_size}")
        print(f"Processes: {size}")
        print(f"Time taken: {end_time - start_time:.4f} seconds")
        print(f"Result matrix shape: {result.shape}")
    
    print(f"Process {rank} on host {hostname} completed")