.code16 
.text
	jmp _pc_start
_pc_os_version:
       .asciz "Morgoth's OS ver 0001"
_pc_start:
	jmp _pc_critical_init
_pc_done_critical_init:
	call _pc_init_vga
	call _pc_vga_demo
	call _pc_wait_ESC
	call _pc_text_mode
	call _pc_text_out
	call _pc_wait_ESC
	call _pc_init_vga
	call _pc_vga_demo
	call _pc_wait_ESC
	call _pc_wait_ESC
	call _pc_text_mode
	call _pc_stop
	ret
_pc_critical_init:
        cli 
        movw $0x7c0,%ax
        movw %ax,%ds
        movw %ax,%ss
        movw $0xFFFF,%sp
        sti 
	jmp _pc_done_critical_init
_pc_stop:
	hlt
	jmp _pc_stop
_pc_init_vga:
	movw $0x0013, %ax
	int $0x10
	ret
_pc_vga_demo:
	movw $0xa000, %bx
	movw %bx, %es
	movw $0x0, %di
_pc_line_y:
	xorb %al, %al
_pc_line_x:
	stosb
	incb %al
	cmpb $0xFF, %al
	jne _pc_line_x
	addw $0x41, %di
	cmpw $63320, %di
	jb _pc_line_y
	ret
_pc_text_mode:
	movw $0x3, %ax
	int $0x10
	ret
_pc_wait_ESC:
	inb $0x60, %al
	cmpb $0x1, %al
	jne _pc_wait_ESC
	ret
_pc_text_out:
       movw $_pc_os_version,%si
_labl_0000: 
	movb (%si),%al
	cmpb $0x00,%al 
	jne _labl_0001
	ret
_labl_0001:
	movb $0x0e,%ah
	xorw %bx,%bx 
	int $0x10
	incw %si
	jmp _labl_0000
	ret
