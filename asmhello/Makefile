all: hel
hel: hel.o
	ld -e _start -o hel hel.o
	strip -s hel
hel.o: hel.s
	as -o hel.o hel.s

