/*
============================================================================
Filename    : implementation.cu
Author      : Jonathan Berezyiat and Lenny Del Zio
SCIPER      : 282962 311240
============================================================================
*/

#include <iostream>
#include <iomanip>
#include <sys/time.h>
#include <cuda_runtime.h>
using namespace std;

#define INIT_VALUE 1000
#define INPUT(I, J) input[(I)*length + (J)]
#define OUTPUT(I, J) output[(I)*length + (J)]
#define S_DATA(I, J) sdata[(I)*s_length + (J)]

// CPU Baseline
void array_process(double *input, double *output, int length, int iterations)
{
    double *temp;

    for (int n = 0; n < (int)iterations; n++)
    {
        for (int i = 1; i < length - 1; i++)
        {
            for (int j = 1; j < length - 1; j++)
            {
                 OUTPUT(i, j) = (INPUT(i - 1, j - 1) + INPUT(i - 1, j) + INPUT(i - 1, j + 1) + INPUT(i, j - 1) + INPUT(i, j) + INPUT(i, j + 1) + INPUT(i + 1, j - 1) + INPUT(i + 1, j) + INPUT(i + 1, j + 1)) / 9;
            }
        }
        OUTPUT(length / 2 - 1, length / 2 - 1) = INIT_VALUE;
        OUTPUT(length / 2, length / 2 - 1) = INIT_VALUE;
        OUTPUT(length / 2 - 1, length / 2) = INIT_VALUE;
        OUTPUT(length / 2, length / 2) = INIT_VALUE;

        temp = input;
        input = output;
        output = temp;
    }
}

// GPU functions
// strateforward isolated iteration
__global__ void iterate(double *input, double *output, int length)
{
    int j = (blockIdx.x * blockDim.x) + threadIdx.x;
    int i = (blockIdx.y * blockDim.y) + threadIdx.y;
    if (0 < i && i < length - 1 && 0 < j && j < length - 1)
    {
         OUTPUT(i, j) = (INPUT(i - 1, j - 1) + INPUT(i - 1, j) + INPUT(i - 1, j + 1) + INPUT(i, j - 1) + INPUT(i, j) + INPUT(i, j + 1) + INPUT(i + 1, j - 1) + INPUT(i + 1, j) + INPUT(i + 1, j + 1)) / 9;
    }
    OUTPUT(length / 2 - 1, length / 2 - 1) = INIT_VALUE;
    OUTPUT(length / 2, length / 2 - 1) = INIT_VALUE;
    OUTPUT(length / 2 - 1, length / 2) = INIT_VALUE;
    OUTPUT(length / 2, length / 2) = INIT_VALUE;
}

// Iteration branching on the middle cells to avoid rewriting and avoir performing calculations for the 4 of them
__global__ void iterate_avoid_center(double *input, double *output, int length)
{
    int j = (blockIdx.x * blockDim.x) + threadIdx.x;
    int i = (blockIdx.y * blockDim.y) + threadIdx.y;
    int index = (i * length) + j;
    int middle1 = (length / 2 - 1) * length + length / 2 - 1;
    int middle2 = (length / 2) * length + length / 2 - 1;
    int middle3 = (length / 2 - 1) * length + length / 2;
    int middle4 = (length / 2) * length + length / 2;
    if (index == middle1 || index == middle2 || index == middle3 || index == middle4)
    {
        return;
    }
    if (0 < i && i < length - 1 && 0 < j && j < length - 1)
    {
         OUTPUT(i, j) = (INPUT(i - 1, j - 1) + INPUT(i - 1, j) + INPUT(i - 1, j + 1) + INPUT(i, j - 1) + INPUT(i, j) + INPUT(i, j + 1) + INPUT(i + 1, j - 1) + INPUT(i + 1, j) + INPUT(i + 1, j + 1)) / 9;
    }
}

// Iterate using the share memory of the GPU
__global__ void iterate_shared(double *input, double *output, int length)
{
    extern __shared__ double sdata[]; // For the S_DATA macro

    int j = (blockIdx.x * (blockDim.x - 2)) + threadIdx.x;
    int i = (blockIdx.y * (blockDim.y - 2)) + threadIdx.y;
    int s_i = threadIdx.y;
    int s_j = threadIdx.x;
    int s_length = blockDim.x; // For the S_DATA macro
    // Load the shared memory
    if (0 <= i && i <= length - 1 && 0 <= j && j <= length - 1)
    {
        S_DATA(s_i, s_j) = INPUT(i, j);
        __syncthreads();
    }
    if (0 < s_i && s_i < s_length - 1 && 0 < s_j && s_j < s_length - 1)
    {
        if (0 < i && i < length - 1 && 0 < j && j < length - 1)
        {
             OUTPUT(i, j) = (INPUT(i - 1, j - 1) + INPUT(i - 1, j) + INPUT(i - 1, j + 1) + INPUT(i, j - 1) + INPUT(i, j) + INPUT(i, j + 1) + INPUT(i + 1, j - 1) + INPUT(i + 1, j) + INPUT(i + 1, j + 1)) / 9;
        }
    }
    OUTPUT(length / 2 - 1, length / 2 - 1) = INIT_VALUE;
    OUTPUT(length / 2, length / 2 - 1) = INIT_VALUE;
    OUTPUT(length / 2 - 1, length / 2) = INIT_VALUE;
    OUTPUT(length / 2, length / 2) = INIT_VALUE;
}

// GPU Optimized function
void GPU_array_process(double *input, double *output, int length, int iterations)
{
    // Cuda events for calculating elapsed time
    cudaEvent_t cpy_H2D_start, cpy_H2D_end, comp_start, comp_end, cpy_D2H_start, cpy_D2H_end;
    cudaEventCreate(&cpy_H2D_start);
    cudaEventCreate(&cpy_H2D_end);
    cudaEventCreate(&cpy_D2H_start);
    cudaEventCreate(&cpy_D2H_end);
    cudaEventCreate(&comp_start);
    cudaEventCreate(&comp_end);

    /* Preprocessing goes here */
    double *gpu_array_in;
    double *gpu_array_out;
    size_t array_size = length * length * sizeof(double);
    // CUDA specific malloc
    cudaMalloc((void **)&gpu_array_in, array_size);
    cudaMalloc((void **)&gpu_array_out, array_size);

    cudaEventRecord(cpy_H2D_start);
    /* Copying array from host to device goes here */
    cudaMemcpy((void *)gpu_array_in, (void *)input, array_size, cudaMemcpyHostToDevice);
    cudaMemcpy((void *)gpu_array_out, (void *)output, array_size, cudaMemcpyHostToDevice);

    cudaEventRecord(cpy_H2D_end);
    cudaEventSynchronize(cpy_H2D_end);

    // Copy array from host to device
    cudaEventRecord(comp_start);
    /* GPU calculation goes here */

    // Define a squared thread bloc (chosed option over the commented code under)
    size_t threadBlockSide = 8;
    size_t nbBlockSide = length / threadBlockSide;
    // If not a multiple
    if (length % threadBlockSide != 0)
        nbBlockSide++;

    dim3 thrsPerBlock(threadBlockSide, threadBlockSide);
    dim3 nBlks(nbBlockSide, nbBlockSide);

    // Define the shared memory
    // size_t threadBlockSide_shared = 32;
    // size_t nbBlockSide_shared = length / (threadBlockSide_shared - 2);
    // // If not a multiple
    // if (length % (threadBlockSide_shared - 2) != 0)
    //     nbBlockSide_shared++;

    // size_t smemSize_shared = threadBlockSide_shared * threadBlockSide_shared * sizeof(double);
    // dim3 thrsPerBlock_shared(threadBlockSide_shared, threadBlockSide_shared);
    // dim3 nBlks_shared(nbBlockSide_shared, nbBlockSide_shared);

    // Define a row shaped thread block
    // size_t threadBlockSide_row = length;
    // size_t nbBlockSide_row = 1;
    // if (threadBlockSide_row > 1024)
    // {
    //     threadBlockSide_row = 512;
    //     nbBlockSide_row = length / threadBlockSide_row;
    //     // If not a multiple
    //     if (length % threadBlockSide_row != 0)
    //         nbBlockSide_row++;
    // }
    // dim3 thrsPerBlock_row(threadBlockSide_row, 1);
    // dim3 nBlks_row(nbBlockSide_row, length);

    double *temp;
    for (int n = 0; n < iterations; n++)
    {
        // iterate <<< nBlks, thrsPerBlock >>> (gpu_array_in, gpu_array_out, length);
        // iterate <<< nBlks_row, thrsPerBlock_row >>> (gpu_array_in, gpu_array_out, length);
        // iterate_shared <<< nBlks_shared, thrsPerBlock_shared, smemSize_shared >>> (gpu_array_in, gpu_array_out, length);
        iterate_avoid_center<<<nBlks, thrsPerBlock>>>(gpu_array_in, gpu_array_out, length);

        temp = gpu_array_in;
        gpu_array_in = gpu_array_out;
        gpu_array_out = temp;
    }

    cudaEventRecord(comp_end);
    cudaEventSynchronize(comp_end);

    cudaEventRecord(cpy_D2H_start);
    /* Copying array from device to host goes here */
    cudaMemcpy((void *)output, (void *)gpu_array_in, array_size, cudaMemcpyDeviceToHost);

    cudaEventRecord(cpy_D2H_end);
    cudaEventSynchronize(cpy_D2H_end);

    /* Postprocessing goes here */
    cudaFree((void *)gpu_array_in);
    cudaFree((void *)gpu_array_out);

    float time;
    cudaEventElapsedTime(&time, cpy_H2D_start, cpy_H2D_end);
    cout << "Host to Device MemCpy takes " << setprecision(4) << time / INIT_VALUE << "s" << endl;

    cudaEventElapsedTime(&time, comp_start, comp_end);
    cout << "Computation takes " << setprecision(4) << time / INIT_VALUE << "s" << endl;

    cudaEventElapsedTime(&time, cpy_D2H_start, cpy_D2H_end);
    cout << "Device to Host MemCpy takes " << setprecision(4) << time / INIT_VALUE << "s" << endl;
}