
#include <opencv2/opencv.hpp>
#include <cuda_runtime.h>
#include <stdio.h>

int main(){

    cv::Mat image(300, 300, CV_8UC3, cv::Scalar(0, 255, 128));
    cv::imwrite("image.jpg", image);
    
    printf("image.rows = %d, image.cols = %d, image.channels = %d\n", image.rows, image.cols, image.channels());
    printf("Save to %s/image.jpg\n", getenv("workdir"));
    printf("Env srcdir = %s, pwd = %s\n", getenv("srcdir"), getenv("pwd"));
    printf("Macro PROD = " PROD "\n");

    float* ptr = nullptr;
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    cudaMalloc(&ptr, sizeof(float) * 100);

    printf("Device Pointer: %p\n", ptr);
    printf("Device Name: %s\n", prop.name);
    printf("Device Memory Size: %d MB\n", prop.totalGlobalMem / 1024 / 1024);
    cudaFree(ptr);
    return 0;
}