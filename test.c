#define CL_TARGET_OPENCL_VERSION 300
#include <CL/opencl.h>
#include <stdio.h>
#include <stdlib.h>

#define CL_CHECK(err)                                              \
    if (err != CL_SUCCESS) {                                       \
        printf("Error Code %d encoutered at L:%d\n", err, __LINE__); \
        exit(1);                                                   \
    }

int main()
{
    cl_int err;

    cl_uint platformCount;
    err = clGetPlatformIDs(0, NULL, &platformCount);
    CL_CHECK(err)

    printf("Discovered %d OpenCL Platform(s) ...\n\n", platformCount);

    cl_platform_id* platforms = (cl_platform_id*)malloc(platformCount * sizeof(cl_platform_id));
    err = clGetPlatformIDs(platformCount, platforms, NULL);
    CL_CHECK(err)

    for (int i = 0; i < platformCount; i++) {
        char platformName[50];
        clGetPlatformInfo(platforms[i], CL_PLATFORM_NAME, 50, platformName, NULL);
        printf("%d. %s\n", i+1, platformName);

        cl_uint deviceCount;
        err = clGetDeviceIDs(platforms[i], CL_DEVICE_TYPE_ALL, 0, NULL, &deviceCount);
        CL_CHECK(err)
        printf("\tDiscovered %d Device(s)\n\n", deviceCount);

        cl_device_id* devices = (cl_device_id*)malloc(deviceCount * sizeof(cl_device_id));
        err = clGetDeviceIDs(platforms[i], CL_DEVICE_TYPE_ALL, deviceCount, devices, NULL);
        for (int j = 0; j < deviceCount; j++) {
            char deviceName[50];
            err = clGetDeviceInfo(devices[j], CL_DEVICE_NAME, 50, deviceName, NULL);
            CL_CHECK(err)
            printf("\t%d. %s\n", j+1, deviceName);
        }

        free(devices);

        puts("");
    }

    free(platforms);

    return 0;
}