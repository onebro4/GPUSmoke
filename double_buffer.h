#include <stdio.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include "GRID3D.h"



template <typename T>
class DoubleBuffer
{
public:
    DoubleBuffer();
    DoubleBuffer(int nelements);
    T* readTarget();
    T* writeTarget();
    inline GRID3D* readToGrid() {
        std::cout << "  Reading Grid: ";
        clock_t startTime = clock();
        GRID3D* output = new GRID3D();
        output->load_from_device(dim, readTarget());
        //output->set_pointer(new GRID3D(dim, readTarget()));
        std::cout << (clock() - startTime);
        return output;
    }
    void swap();
    int byteCount();
    void setDim(int3 dim);
    ~DoubleBuffer();
private:
    int nbytes;
    T* A;
    T* B;
    int3 dim;
};
