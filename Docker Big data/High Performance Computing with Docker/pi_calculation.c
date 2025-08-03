#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main(int argc, char** argv) {
    int rank, size;
    long long n = 1000000000; // Number of intervals
    double h, sum, x, pi;
    double start_time, end_time;
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    h = 1.0 / (double)n;
    sum = 0.0;
    
    start_time = MPI_Wtime();
    
    for (long long i = rank + 1; i <= n; i += size) {
        x = h * ((double)i - 0.5);
        sum += 4.0 / (1.0 + x * x);
    }
    
    double local_pi = h * sum;
    MPI_Reduce(&local_pi, &pi, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    
    end_time = MPI_Wtime();
    
    if (rank == 0) {
        printf("Calculated PI = %.15f\n", pi);
        printf("Error = %.15f\n", pi - 3.141592653589793);
        printf("Time taken = %.6f seconds\n", end_time - start_time);
        printf("Processes used = %d\n", size);
    }
    
    MPI_Finalize();
    return 0;
}