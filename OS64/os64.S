
.text
    .code16 

    jmp kernel_entry 
pGDT32:
gdt32_limit:
	.byte 0xFF,0xFF
gdt32_base:
	.byte 0x0,0x0,0x0,0x0
pIDT32:
idt32_limit:
	.byte 0xFF,0xFF
idt32_base:
	.byte 0x0,0x0,0x0,0x0
pGDT64:
gdt64_limit:
	.byte 0x0,0x0
gdt64_base:
	.byte 0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0
pIDT64:
idt64_limit:
	.byte 0x0,0x0
idt64_base:
	.byte 0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0
hello_msg:
       .asciz "Hello world!!!" 
    kernel_entry:
       cli 
       movw $0x7c0,%ax
       movw %ax,%ds
       movw %ax,%ss
       movw $0x1000,%sp
       movl $0x80000000, %eax
       cpuid
       cmpl $0x80000000, %eax
       jbe kernel_exit
       movl $0x80000001, %eax
       cpuid
       btl $29, %edx
       #jnc kernel_exit			#fatal error here! NO_LM
       lgdt pGDT32
       lidt pIDT32
       movl $0x11, %eax
       movl %eax, %cr0
       
now_in_prot:
       sti 
       /*movw $hello_msg,%si
    print_string: 
       movb (%si),%al
       cmpb $0x00,%al 
       je kernel_exit 
       movb $0x0e,%ah
       xorw %bx,%bx 
       int $0x10
       incw %si
       jmp print_string*/


    kernel_exit:
       hlt
       jmp kernel_exit
