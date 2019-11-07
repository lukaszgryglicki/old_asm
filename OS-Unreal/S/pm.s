.set LINEAR_SEL, 8 # gdt1-gdt		#8
.equ SYS_CODE_SEL, 16 # gdt2-gdt	#16
.set SYS_DATA_SEL, 24 # gdt3-gdt	#24
.set REAL_CODE_SEL, 32 #gdt4-gdt	#32
.set REAL_DATA_SEL, 40 #gdt5-gdt	#40
.text
start:
	.code16
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
	addr32 lea gdt(%ebx), %eax	#? this is stuck??
        				#lea eax,[gdt + ebx]             
					#.byte 0x66,0x67,0x8d,0x83,0x9f,0x02,0x00,0x00	#fuckin OPCODE
        mov %eax, (gdtr+2)
	cli
	xor %ax,%ax
	mov %ax,%es
					# try unreal
	mov %es:(0x34), %edx
					#.byte 0x26,0x66,0x8b,0x16,0x34,0x00
					#mov edx,[es:0x0D * 4]		
	mov %cs, %es:(0x36)
					#mov [es:0x0D * 4 + 2],cs
					#lea ax,[trap]
	lea trap, %ax
					#mov [es:0x0D * 4],ax
	mov %ax, %es:(0x34) 
	mov $0xb809a, %ebx
					#mov byte [es:ebx],'R'	
	addr32 movb $'R', %es:(%ebx) 
					#.byte 0x26,0x67,0xc6,0x03,0x52
					# done try unreal 
	mov %cs,%ax
	mov %ax, (RealModeCS)		#?
	lea do_rm, %ax
	mov %ax, (RealModeIP)
	mov $0xB800, %ax
	mov %ax,%es
	lgdt (gdtr)			#?
	mov %cr0,%eax
	or $1,%al
	mov %eax,%cr0 
        lea msg0, %si			#?
        mov $164, %di
        mov $9,%cx
        cld
        rep movsb
					#ljmp $SYS_CODE_SEL, $do_pm       #??
	ljmp $SYS_CODE_SEL, $do_pm
trap:	
	mov $0xB800, %ax
					#.byte 0xb8,0x00,0xb8
	mov %ax,%fs
	movb $'!', %fs:(0x9C)		#?
	pop %ax			
	add $0x0005,%ax	
					#.byte 0x05,0x05,0x00
	push %ax
	iret
.code32
do_pm:
        xor %edi,%edi
        xor %esi,%esi
	lea msg1,%si                   
        mov $326, %di
        mov $9,%ecx
        cld
        rep movsb
	mov $SYS_DATA_SEL, %ax		#?	//offset to sys_data
	mov %ax,%ds
	mov %ax,%ss
	mov $LINEAR_SEL, %ax		#?
	mov %ax,%es
	movb $'0', %es:(0xb8000)
	movb $'1', %es:(0xb8002)
	movb $'2', %es:(0xb8004)
	movb $'3', %es:(0xb8006)
					#mov byte [es:dword 0xB8000],'0'
	lea msg2, %esi
					#mov edi,0xB8000+(80*3+4)*2      
	mov $0xb81e8, %edi		#?
	mov $9,%ecx
	cld
	rep movsb
					#ljmp $REAL_CODE_SEL, $do_16	#??
	ljmp  $REAL_CODE_SEL, $do_16
do_16:
	.code16
	mov $REAL_DATA_SEL,%ax		#?
	mov %ax,%ss
	mov %ax,%ds		
	mov %cr0,%eax
	and $0xFE,%al
	mov %eax,%cr0
					#jmp far [RealModeIP]
	ljmp *(RealModeIP)		#?
do_rm:	
	.code16
					#mov byte [es:dword 0xB8008],'4'
	addr32 movb $'4', %es:(0xb8008)	#?
	xor %ax,%ax
	mov %ax,%es
	addr32 movb $'5',%es:(0xb800a)	#?
					#mov byte [es:dword 0xB800A],'5'
	lea msg3, %esi
					#mov edi,0xB8000+(80*4+5)*2      
	mov $0xb828a, %edi
	mov $9,%ecx
	cld
					#.byte 0x67			#a32? 
	addr32 rep movsb
	mov %cs,%ax
	mov %ax,%ds
	mov %ax,%ss
	mov $0xB800,%ax
	mov %ax,%es
	lea msg4, %si                  
					#mov di,(80 * 5 + 6) * 2      
	mov $812, %di			#?
	mov $9,%cx
	cld
	rep movsb
	xor %ax,%ax
	mov %ax,%es
					#mov [es:0x0D * 4],edx
	mov %edx, %es:(0x34)		#?
	sti
	mov $0x4C00,%ax
	int $0x21 
RealModeIP:
        .word 0
RealModeCS:
	.word 0
msg0:   .ascii "r m 1 6 "
msg1:   .ascii "p m 1 6 "
msg2:   .ascii "p%m%3%2%"
msg3:	.ascii "r m 3 2 "
msg4:   .ascii "r e a l "
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
