all: serv
serv: serv.o
	ld -e _start -o serv serv.o
serv.o: serv.s
	as --gstabs -o serv.o serv.s
clean:
	-rm -f *.o serv
