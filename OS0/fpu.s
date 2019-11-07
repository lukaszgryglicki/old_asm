.text
.globl _start
_start:
	fldpi
	fsqrt
	ftst
	fstsw %ax
	sahf
	fcomp
	ja _start
	movl $0x1, %eax
	pushl $0x0
	pushl $0x0
	int $0x80
