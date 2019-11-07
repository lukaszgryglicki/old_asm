.code16 
.text
    jmp kernel_entry 
hello_msg:
       .asciz "Hello world!!!"
kernel_entry:
       cli 
       movw $0x7c0,%ax
       movw %ax,%ds
       movw %ax,%ss
       movw $0x1000,%sp
       sti 
       movw $hello_msg,%si
print_string: 
       movb (%si),%al
       cmpb $0x00,%al 
       je kernel_exit 
       movb $0x0e,%ah
       xorw %bx,%bx 
       int $0x10
       incw %si
       jmp print_string
    kernel_exit:
       hlt
       jmp kernel_exit
