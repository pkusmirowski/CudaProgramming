#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 100000000

float hArray[N];
float *dArray;
int blocks;
clock_t begin1,begin2,begin3,begin4,end1,end2,end3,end4;

void prologue(void)
{
        memset(hArray, 0, sizeof(hArray));
        for(int i = 0; i < N; i++)
        {
                hArray[i] = i + 1;
        }
        cudaMalloc((void**)&dArray, sizeof(hArray));
        begin2 = clock();
        cudaMemcpy(dArray, hArray, sizeof(hArray), cudaMemcpyHostToDevice);
        end2 = clock();
}

void epilogue(void)
{
        begin1 = clock();
        cudaMemcpy(hArray, dArray, sizeof(hArray), cudaMemcpyDeviceToHost);
        end1 = clock();
        cudaFree(dArray);
}

// Kernel
__global__ void pow3(float *A)
{
        int x = blockDim.x * blockIdx.x + threadIdx.x;
        if(x < N)
                A[x] = A[x] * A[x] * A[x] + A[x] * A[x] + A[x];
}

//CPU
void cpu(float *A)
{
        int x;
        for (x = 0; x<N; x++)
        {
                A[x] = A[x] * A[x] * A[x] * A[x] * A[x] * A[x];
        }
}

int main(int argc, char** argv)
{
        int devCnt;
        cudaGetDeviceCount(&devCnt);

        if(devCnt == 0) {
                perror("No CUDA devices available -- exiting.");
                return 1;
        }

        struct cudaDeviceProp *prop;
        prop = (cudaDeviceProp*)malloc(sizeof(struct cudaDeviceProp));
        cudaGetDeviceProperties(prop,0);
        printf("Ilosc watkow: %d\n", prop->maxThreadsPerBlock);

        //GPU
        prologue();
        blocks = N / prop->maxThreadsPerBlock;
        if(N % prop->maxThreadsPerBlock)
                blocks++;
        begin4 = clock();
        pow3<<<blocks, prop->maxThreadsPerBlock>>>(dArray);
        cudaThreadSynchronize();
        end4 = clock();
        epilogue();

        //CPU
        begin3 = clock();
        cpu(hArray);
        end3 = clock();

        double time_spent1 = (double)(end1 - begin1) / CLOCKS_PER_SEC;
        double time_spent2 = (double)(end2 - begin2) / CLOCKS_PER_SEC;
        double time_spent3 = (double)(end3 - begin3) / CLOCKS_PER_SEC;
        double time_spent4 = (double)(end4 - begin4) / CLOCKS_PER_SEC;

        printf("Czas DeviceToHost: %f\n", time_spent1);
        printf("Czas HostToDevice: %f\n", time_spent2);
        printf("Czas funkcji CPU: %f\n", time_spent3);
        printf("Czas funkcji GPU: %f\n", time_spent4);
        return 0;
}
