all: os1.bootimg
os1.bootimg: os1.relloc
	ld -o os1.bootimg --oformat binary -Ttext 0x0000 os1.relloc
os1.relloc: os1.S
	cc -c -ffreestanding -o os1.relloc os1.S
install: os1.bootimg
	-dd if=./os1.bootimg of=/data/bochs/os1.flp bs=512 count=1
	-bochs -qf /data/bochs/rc_os1
clean: 
	-rm os1.relloc os1.bootimg parport.out

	
