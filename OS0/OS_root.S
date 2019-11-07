
    .code16 
    .text

    jmp kernel_entry 

    kernel_entry:
       cli 
       movw $0x7c0,%ax
       movw %ax,%ds
       movw %ax,%ss
       movw $0x1000,%sp
       sti 

    /* Here we use BIOS interrupt to write our message.
    Interrupt 0x10, function 0x0e. 
    In %al - character to write, in %ah - 0x0e. */

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

    /* Here we just fall into the infinite loop. */

    kernel_exit:
       hlt
       jmp kernel_exit

    hello_msg:
       .asciz "Hello world!!!" /* Zero-padded string. */ 
    #boot_signature: 
    #   .word 0xaa55 /* The boot signature for PC BIOS. */ 
