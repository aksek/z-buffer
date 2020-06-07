#ifndef F_HPP_
#define F_HPP_
extern "C" {
    void f(unsigned char *pBuffer, int W, int H, int alpha, int betha, int coordinates[], int translated_coors[], int *output, int z_buffer[]);
}
#endif // F_HPP_