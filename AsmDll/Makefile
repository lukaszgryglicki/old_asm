all: prog sorun libdll.so
prog: prog.c lib.h libdll.so
	cc -o prog prog.c -pthread -L. -I/usr/X11R6/include -L/usr/X11R6/lib -ldll -lX11
libdll.so: lib.h lib.c
	cc -shared -o libdll.so lib.c
sorun: sorun.o asmdl.o
	cc -g3 -Wall -pedantic -std=c99 -o sorun sorun.o asmdl.o
sorun.o: sorun.c 
	cc -g3 -Wall -pedantic -std=c99 -c sorun.c
asmdl.o: asmdl.s 
	as --gstabs -o asmdl.o asmdl.s
