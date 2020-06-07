#include<iostream>
#include<GL/glut.h>
#include<climits>
#include "f.hpp"

const int H = 400, W = 400, BPP = 4;
unsigned char *g_pBuffer = 0;

int g_alpha = 0, g_betha = 0;
int g_coordinates[12] = {0, 0, 0, 100, 0, 0, 50, 86, 0, 50, 28, 81};
int g_translated_coors[12];

void redraw() {
    int output = 0;
    int z_buffer[W*H] = {INT_MIN};
    f(g_pBuffer, W, H, g_alpha, g_betha, g_coordinates, g_translated_coors, &output, z_buffer);
    glDrawPixels(W, H, GL_RGBA, GL_UNSIGNED_BYTE, g_pBuffer); 
    glutSwapBuffers();
    std::cout << output << '\n';
}

void displayCallback() {
    redraw();
    std::cout << "displayCallback()" << std::endl;
}

void keyboardCallback(unsigned char key, int x, int y) {
    int alpha = g_alpha, betha = g_betha;
    if ('a' == key) {
        betha = (g_betha - 1);
        if (betha == -1)
            betha = 359;
    } else if ('d' == key) {
        betha = (g_betha + 1) % 360;
    }
    if ('w' == key) {
        alpha = (g_alpha + 1) % 360;
    } else if ('s' == key) {
        alpha = (g_alpha - 1) % 360;
        if (alpha == -1)
            alpha = 359;
    }

    if ((alpha != g_alpha)) {
        g_alpha = alpha ;
        redraw();
        std::cout << "alpha(" << g_alpha << ")" << std::endl;
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 3; j++) {
                std::cout << g_translated_coors[i*3+j] << ' ';
            }
            std::cout << '\n';
        }
    }
    if ((betha != g_betha)) {
        g_betha = betha ;
        redraw();
        std::cout << "betha(" << g_betha << ")" << std::endl;
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 3; j++) {
                std::cout << g_translated_coors[i*3+j] << ' ';
            }
            std::cout << '\n';
        }
    }
}

int main(int argc, char *argv[]) {
    std::cout << sizeof(int) << '\n';

    bool debug = false;

    if (!debug) {
        std::cout << "Type tetrahedron coordinates (range: (-200; 200) will fit in the window)\n";
        for (int i = 0; i < 12; i++) {
            std::cin >> g_coordinates[i];
        }
    }
    std::cout << "Init coordinates: \n";
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 3; j++) {
            std::cout << g_coordinates[i*3+j] << ' ';
         }
         std::cout << '\n';
    }
    
    g_pBuffer = new unsigned char[H * W * BPP];

    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_SINGLE);
    glutInitWindowSize(W, H);
    glutInitWindowPosition(100, 100);
    glutCreateWindow("Tetrahedron x86 64");
    glutDisplayFunc(displayCallback);
    glutKeyboardFunc(keyboardCallback);
    glutMainLoop();
    return 0;
}