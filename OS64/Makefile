all: os64.bootimg
os64.bootimg: os64.relloc
	ld -o os64.bootimg --oformat binary -Ttext 0x0000 os64.relloc
	-rm os64.relloc
os64.relloc: os64.S
	#cc -c -ffreestanding -o os64.relloc os64.S
	as -o os64.relloc os64.S
run: os64.bootimg
	-dd if=./os64.bootimg of=os64.flp bs=512 count=1
	-bochs -qf ./rc_os64
clean: 
	-rm os64.relloc os64.bootimg parport.out log.out debugger.out os64.flp

	
