.text
.code16
.set LINEAR_SEL, 8
.equ SYS_CODE_SEL, 16
.set SYS_DATA_SEL, 24
.set REAL_CODE_SEL, 32
.set REAL_DATA_SEL, 40
_start:
	cli 
	movw $0x7c0,%ax
	movw %ax,%ds
	movw %ax,%ss
	movw $0x1000,%sp
	sti
dalej:
	#call init16
	call debug_inf
	call proton
protoff:
	call debug_inf
	#call real16
kernel_halt:
	hlt
	jmp kernel_halt
write_si: 
       movb (%si),%al
       cmpb $0x00,%al 
       je done
       movb $0x0e,%ah
       xorw %bx,%bx 
       int $0x10
       incw %si
       jmp write_si
done:
	ret
debug_inf:
	lea debug_msg, %si
	call write_si
	ret
proton:
	xor %ebx,%ebx
	mov %ds,%bx                       
	shll $4,%ebx                      
	mov %ebx,%eax
	mov %ax, (gdt2+2)
	mov %ax, (gdt3+2)
	mov %ax, (gdt4+2)
	mov %ax, (gdt5+2)
	shr $16,%eax
	mov %al, (gdt2+4)
	mov %al, (gdt3+4)
	mov %al, (gdt4+4)
	mov %al, (gdt5+4)
	mov %ah, (gdt2+7)
	mov %ah, (gdt3+7)
	mov %ah, (gdt4+7)
	mov %ah, (gdt5+7)
	addr32 lea gdt(%ebx), %eax
        mov %eax, (gdtr+2)
	cli
	movw $0x7c0, (RealModeCS)
	lea do_rm, %ax
	movw %ax, (RealModeIP)
	mov $0xB800, %ax
	mov %ax,%es
	lgdt (gdtr)			
	mov %cr0,%eax
	or $1,%al
	mov %eax,%cr0 
        lea msg0, %si		
        mov $164, %di
        mov $0xc,%cx
        cld
        rep movsb
	#call prot16
	ljmp $SYS_CODE_SEL, $do_pm
.code32
do_pm:
        xor %edi,%edi
        xor %esi,%esi
	lea msg1,%si                   
        mov $326, %di
        mov $0xc,%ecx
        cld
        rep movsb
	mov $SYS_DATA_SEL, %ax
	mov %ax,%ds
	mov %ax,%ss
	mov $LINEAR_SEL, %ax
	mov %ax,%es
	movb $'0', %es:(0xb8000)
	movb $'1', %es:(0xb8002)
	movb $'2', %es:(0xb8004)
	movb $'3', %es:(0xb8006)
	lea msg2, %esi
	mov $0xb81e8, %edi		
	mov $0xc,%ecx
	cld
	rep movsb
	call prot32_os
	ljmp  $REAL_CODE_SEL, $do_16
do_16:
	.code16
	mov $REAL_DATA_SEL,%ax	
	mov %ax,%ss
	mov %ax,%ds		
	mov %cr0,%eax
	and $0xFE,%al
	mov %eax,%cr0
	ljmp *(RealModeIP)	
do_rm:	
	.code16
	addr32 movb $'4', %es:(0xb8008)	
	xor %ax,%ax
	mov %ax,%es
	addr32 movb $'5',%es:(0xb800a)
	lea msg3, %esi
	mov $0xb828a, %edi
	mov $0xc,%ecx
	cld
	addr32 rep movsb
	#call unreal
	mov %cs,%ax
	mov %ax,%ds
	mov %ax,%ss
	mov $0xB800,%ax
	mov %ax,%es
	lea msg4, %si                  
	mov $812, %di		
	mov $0x12,%cx
	cld
	rep movsb
	xor %ax,%ax
	mov %ax,%es
	mov %edx, %es:(0x34)		
	sti
	jmp protoff
.code16
debug_msg:
       .asciz "-"
RealModeIP:
        .word 0
RealModeCS:
	.word 0
RealModeSP:
	.word 0
msg0:   .ascii "r e a l 1 6 "
msg1:   .ascii "p r o t 1 6 "
msg2:   .ascii "p%r%o%t%3%2%"
msg3:	.ascii "u n r e a l "
msg4:   .ascii "b a c k   r m 1 6 "
gdtr:	.word gdt_end-gdt-1
	.long gdt             
gdt:	
	.word 0		
	.word 0	
	.byte 0	
	.byte 0	
	.byte 0	
	.byte 0
gdt1:
	.word 0xFFFF		
	.word 0			
	.byte 0
	.byte 0x92			
        .byte 0xCF                 
	.byte 0
gdt2:   
	.word 0xFFFF               
	.word 0			
	.byte 0
	.byte 0x9A			
        .byte 0xCF                
	.byte 0
gdt3:   .word 0xFFFF               
	.word 0			
	.byte 0
	.byte 0x92			
        .byte 0xCF                 
	.byte 0
gdt4:   .word 0xFFFF
	.word 0			
	.byte 0
	.byte 0x9A		
	.byte 0			
	.byte 0
gdt5:   .word 0xFFFF
	.word 0			
	.byte 0
	.byte 0x92			
	.byte 0		
	.byte 0
gdt_end:
prot32_os:	
	ret
	.byte 0x0,0x0,0x0,0x0
	.word 0xaa55

