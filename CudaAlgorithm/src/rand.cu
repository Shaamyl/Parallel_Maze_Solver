/*
 * This code just provides a simple example of how to use the
 * randomness in CUDA. You do not need to modify or upload
 * this code in your submission.
 */

#include <stdio.h>
#include <curand.h>
#include <curand_kernel.h>

#define N_BLOCKS 16
#define N_THREADS 1024

 
/*** GPU functions ***/
__global__ void init_rand_kernel(curandState *state) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  curand_init(0, idx, 0, &state[idx]);
}

__global__ void use_rand_kernel(curandState *state, float *out) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  out[idx] = curand_uniform(&state[idx]);
 
  // Let's print a few numbers on the GPU (for the first 10 threads)
  // This should match the CPU output
  if (idx < 10) {
    printf("GPU (%d): %f\n", idx, out[idx]);
  }
}

/*** CPU functions ***/
int main(void) {
    // Pointers to our memory
    float *out, *d_out;
    curandState *d_state;
    
    // Allocate memory for the random numbers (CPU)
    // We use 'malloc' for CPU memory
    out = (float*)malloc(N_BLOCKS * N_THREADS * sizeof(float));

    // Allocate memory for the random numbers (GPU)
    // We use 'cudaMalloc' for GPU memory
    // Notice that the interface is a bit different, as the pointer is
    // passed into 'cudaMalloc' as the first argument
    cudaMalloc(&d_out, N_BLOCKS * N_THREADS * sizeof(float));

    // Allocate memory for the Random Number Generators (RNGs) on (GPU)
    cudaMalloc(&d_state, N_BLOCKS * N_THREADS * sizeof(curandState));

    // We need to initialize the RNGs on the GPU
    init_rand_kernel<<<N_BLOCKS, N_THREADS>>>(d_state);

    // An example of how to use the RNGs on the GPU
    use_rand_kernel<<<N_BLOCKS, N_THREADS>>>(d_state, d_out);

    // Copy the random numbers from the GPU to the CPU
    cudaMemcpy(out, d_out, N_BLOCKS * N_THREADS * sizeof(float), cudaMemcpyDeviceToHost);

    // prints a few numbers to make sure it works!
    for (int i = 0; i < 10; i++) {
        printf("CPU (%d): %f\n", i, out[i]);
    }

    // Free the memory
    // We use 'free' for CPU memory and 'cudaFree' for GPU memory
    cudaFree(d_state);
    cudaFree(d_out);
    free(out);

    return 0;
}
