CC = g++
CFLAGS = -Wall -m64

all: display.o f_a.o
	$(CC) $(CFLAGS) -no-pie -o fun display.o f_a.o -lglut -lGLU -lGL

f_a.o: f.s
	nasm -f elf64 -o f_a.o f.s

display.o: display.cpp
	$(CC) $(CFLAGS) -c -o display.o display.cpp

clean:
	rm -f *.o
