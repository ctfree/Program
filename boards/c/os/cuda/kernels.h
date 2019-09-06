#ifndef _KERNELS_H_
#define _KERNELS_H_
#include <stdio.h>
#define _USE_MATH_DEFINES
#include <math.h>
#include <cuda_runtime.h>  //cude c++ API





typedef unsigned char uchar;

//vsize in float elements (not bytes)
bool LaunchVectAdd(const float* d_A, const float* d_B, float *d_C, size_t vsize);






inline bool TestLastError (const char* msg="???")
{
  cudaError_t err=cudaGetLastError ();
  if(err==cudaSuccess) return true;
  printf("error \"%s\" in%s \n", cudaGetErrorString(err),msg);
  return false;
}





#endif //_KERNELS_H_