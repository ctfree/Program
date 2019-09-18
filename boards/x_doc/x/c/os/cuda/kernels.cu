#include "kernels.h"

/****************************************** Partie GPU ***********************************************/



//seulement pour tailles multiples de BLOCK_SZ
__global__ void KVectAddFast(const float *A, const float*B, float*C)
{
size_t idx=threadIdx.x+blockIdx.x*blockDim.x;
C[idx]=A[idx]+B[idx];

}

//toutes les tailles
__global__ void KVectAdd(const float *A, const float*B, float*C, size_t vsize)
{
size_t idx=threadIdx.x+blockIdx.x*blockDim.x;
if (idx<vsize) C[idx]=A[idx]+B[idx];

}

__global__ void KImgInv(const float *A, float*B)
{
	size_t idx=blockIdx.x * blockDim.x * blockDim.y + threadIdx.y * blockDim.x + threadIdx.x;
	B[idx]=1.0-A[idx];
}

/****************************************** Partie CPU ********************************************/
bool LaunchVectAdd(const float*d_A, const float*d_B, float* d_C, size_t vsize)
{
  const int BLOCK_SZ=256;
  if (vsize%BLOCK_SZ==0)
  {
    dim3 Db(BLOCK_SZ,1,1), Dg(vsize/BLOCK_SZ,1,1);
    KVectAddFast<<<Dg,Db>>>(d_A, d_B, d_C);
  }
  else
  {
    dim3 Db(BLOCK_SZ,1,1), Dg((vsize+BLOCK_SZ-1)/BLOCK_SZ,1,1);
    KVectAdd<<<Dg,Db>>>(d_A, d_B, d_C,vsize);
  }

    return TestLastError ("Lauch kernel VectAdd");
}

bool LaunchImgInv (const float*d_A,float*d_B, size_t vsize)
{
	const int BLOCK_SZ_x=128,BLOCK_SZ_y=4;
	dim3 Db(BLOCK_SZ_x,BLOCK_SZ_y,1), Dg(vsize/(BLOCK_SZ_x*BLOCK_SZ_y),1,1);
	KImgInv<<<Dg,Db>>>(d_A,d_B);
	
	return TestLastError ("Lauch Kernel ImgInv");
}
