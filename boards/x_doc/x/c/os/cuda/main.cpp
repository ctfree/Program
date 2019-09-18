#include "kernels.h"
#include "cutil.h"



void test1()
{
const size_t VECT_SZ=1024+7, VECT_SZ_BYTE=VECT_SZ*sizeof(float);
//alloc Host(CPU) data:
float *h_A=0, *h_B=0, *h_C=0;
h_A=new float[VECT_SZ]; h_B=new float[VECT_SZ]; h_C=new float[VECT_SZ];
printf("Host@: %p, %p, %p\n", h_A, h_B, h_C);
for (size_t i=0; i<VECT_SZ; i++) { h_A[i]=float(i)*float(i); h_B[i]=sqrt(float(i)); h_C[i]=0;}

//alloc Device(GPU) data:
float *d_A=0, *d_B=0, *d_C=0;
cudaMalloc((void**)&d_A, VECT_SZ_BYTE); cudaMalloc((void**)&d_B, VECT_SZ_BYTE); cudaMalloc((void**)&d_C, VECT_SZ_BYTE); 
// CPU -> GPU data transfer:
cudaMemcpy (d_A, h_A, VECT_SZ_BYTE,  cudaMemcpyHostToDevice);
cudaMemcpy (d_A, h_B, VECT_SZ_BYTE,  cudaMemcpyHostToDevice);
//cudaMemcpy (d_A, h_C, VECT_SZ_BYTE,  cudaMemcpyHostToHostToDevice);
//Kernel launch
LaunchVectAdd (d_A, d_B, d_C, VECT_SZ);      //fonction qui va lancer le kernel


//GPU-> CPU
cudaMemcpy (h_C, d_C, VECT_SZ_BYTE,  cudaMemcpyDeviceToHost);
//visual test
for ( size_t i=0; i<10; i++)
   printf ("[%9u] %18.3f +%18.3f =%18.3f (%18.f)\n" ,i, h_A[i], h_B[i], h_C[i], h_A[i]+h_B[i]);
for ( size_t i=VECT_SZ-10; i<VECT_SZ; i++)
   printf ("[%9u] %18.3f +%18.3f =%18.3f (%18.f)\n" ,i, h_A[i], h_B[i], h_C[i], h_A[i]+h_B[i]);
//free CPU/GPU data:
delete[] h_A; delete[] h_B; delete[] h_C;
cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);


}


void test2()
{
unsigned int W_Image=512;
unsigned int H_Image=512;
const size_t VECT_SZ=H_Image*W_Image, VECT_SZ_BYTE=VECT_SZ*sizeof(float);
//alloc Host(CPU) data:
float *h_A=0, *h_B=0;
h_A=new float[VECT_SZ]; h_B=new float[VECT_SZ]; 
printf("Host@: %p, %p, %p\n", h_A, h_B);

//chargement de l'image 
loadPGMf("image.pgm",&h_A,&W_Image,&H_Image);

//alloc Device(GPU) data:
float *d_A=0, *d_B=0;
cudaMalloc((void**)&d_A, VECT_SZ_BYTE); cudaMalloc((void**)&d_B, VECT_SZ_BYTE);  
// CPU -> GPU data transfer:
cudaMemcpy (d_A, h_A, VECT_SZ_BYTE,  cudaMemcpyHostToDevice);
//cudaMemcpy (d_A, h_C, VECT_SZ_BYTE,  cudaMemcpyHostToHostToDevice);
//Kernel launch
LaunchImgInv (d_A, d_B, VECT_SZ);      //fonction qui va lancer le kernel


//GPU-> CPU
cudaMemcpy (h_B, d_B, VECT_SZ_BYTE,  cudaMemcpyDeviceToHost);
//visual test
/*
for ( size_t i=0; i<10; i++)
   printf ("[%9u] %18.3f +%18.3f =%18.3f (%18.f)\n" ,i, h_A[i], h_B[i], h_C[i], h_A[i]+h_B[i]);
for ( size_t i=VECT_SZ-10; i<VECT_SZ; i++)
   printf ("[%9u] %18.3f +%18.3f =%18.3f (%18.f)\n" ,i, h_A[i], h_B[i], h_C[i], h_A[i]+h_B[i]);
*/
SavePGMf("image_sortie.pgm",h_B,&W_Image,&H_Image);
//free CPU/GPU data:
delete[] h_A; delete[] h_B;
cudaFree(d_A); cudaFree(d_B);

}






void main ()

{
  cudaSetDevice(0);
  test2();
  cudaDeviceReset();
}