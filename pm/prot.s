.text
.code16
_start:	
	xorl %ebx,%ebx
	movw %ds,%bx                       
	shll $4,%ebx                       
	movl %ebx,%eax
	movw %ax,(gdt2+2) 
	movw %ax,(gdt3+2)
	movw %ax,(gdt4+2)               
	movw %ax,(gdt5+2)
	shrl $0x10,%eax
	movb %al,(gdt2+4)
	movb %al,(gdt3+4)
	movb %al,(gdt4+4)
	movb %al,(gdt5+4)
	mov %ah,(gdt2+7)
	mov %ah,(gdt3+7)
	mov %ah,(gdt4+7)
	mov %ah,(gdt5+7)
        #leal gdt(%ebx),%eax 	#FUCK cannot be EBX
	#leal gdt(%bx), %eax
	#.code32
	addr32 leal gdt(%ebx), %eax
	#.code16
        movl %eax,(gdtr+2)
	cli
	xorw %ax,%ax
	movw %ax,%es
	#mov edx,[es:0x0D * 4]		
	movl %es:(0x34), %edx
	#mov [es:0x0D * 4 + 2],cs
	movw %cs, %es:(0x36) 
	#lea ax,[trap]
	leaw trap, %ax
	#mov [es:0x0D * 4],ax
	movw %ax, %es:(0x34)
	movl $0xB809A, %ebx			
	#mov byte [es:ebx],'R'		
	addr32 movb $'R', %es:(%ebx)
	movw %cs, %ax
	#mov [RealModeCS],ax
	movw %ax, (RealModeCS)
	#lea ax,[do_rm]
	leaw do_rm, %ax
	#mov [RealModeIP],ax
	movw %ax, (RealModeIP)
	movw $0xB800, %ax
	movw %ax,%es
	#lgdt [gdtr]
	lgdt gdtr
	movl %cr0, %eax
	orb $1, %al
	movl %eax, %cr0
        #lea si,[msg0]                   
	leaw msg0, %si
        #mov di,(80 * 1 + 2) * 2         
	movw $0xa4, %di
        movw $38, %cx
        cld
        rep movsb
	#jmp SYS_CODE_SEL:do_pm          
	jmp do_pm
trap:	
	movw $0xB800, %ax
	movw %ax, %fs
	#mov byte [fs:0x9C],'!'
	movb $'!', %fs:(0x9C)
	popw %ax				
	addw $5,%ax			
	pushw %ax
	iret
.code32
do_pm:
        xorl %edi,%edi
        xorl %esi,%esi
	#lea si,[msg1]                   
	leaw msg1, %si
        #mov di,(80 * 2 + 3) * 2         
	movw $326, %di
        movl $46,%ecx
        cld
        rep movsb
	#mov ax,SYS_DATA_SEL
	movw $SYS_DATA_SEL, %ax
	movw %ax,%ds
	movw %ax,%ss
	movw $LINEAR_SEL,%ax
	movw %ax,%es
	#mov byte [es:dword 0xB8000],'0'
	#mov byte [es:dword 0xB8002],'1'
	#mov byte [es:dword 0xB8004],'2'
	#mov byte [es:dword 0xB8006],'3'
	movb $'0', %es:(0xb8000)
	movb $'1', %es:(0xb8002)
	movb $'2', %es:(0xb8004)
	movb $'3', %es:(0xb8006)
	#lea esi,[msg2]                  
	leal msg2, %esi
	#mov edi,0xB8000 + (80 * 3 + 4) * 2      
	movl $0xb81e8, %edi
	movl $52, %ecx
	cld
	rep movsb
	#jmp REAL_CODE_SEL:do_16
	jmp do_16
.code16
do_16:
	movw $REAL_DATA_SEL, %ax
	movw %ax,%ss
	movw %ax,%ds			
	movl %cr0,%eax
	andb $0xFE,%al
	movl %eax,%cr0
	#jmp far [RealModeIP]
	ljmp *(RealModeIP)
.code16
do_rm:	
	#mov byte [es:dword 0xB8008],'4'
	addr32 movb $'4', %es:(0xb8008)
	xorw %ax,%ax
	movw %ax,%es
	#mov byte [es:dword 0xB800A],'5'
	addr32 movb $'5', %es:(0xb800A)
	#lea esi,[msg3]			
	leal msg3, %esi
	#mov edi,0xB8000 + (80 * 4 + 5) * 2      
	movl $0xb8248, %edi
	movl 56, %ecx
	cld
	#a32				
	.byte 0x67
	rep movsb
	movw %cs,%ax
	movw %ax,%ds
	movw %ax,%ss
	movw $0xB800,%ax
	movw %ax,%es
	#lea si,[msg4]                   
	leaw msg4, %si
	#mov di,(80 * 5 + 6) * 2         
	movw $812, %di
	movw $56,%cx
	cld
	rep movsb
	xorw %ax,%ax
	movw %ax,%es
	#mov [es:0x0D * 4],edx		
	movl %edx, %es:(0x34)
	sti
	movw $0x4C00,%ax
	int $0x21
RealModeIP:
        .byte 0,0

RealModeCS:
	.byte 0,0
msg0:   .ascii "s t i l l   i n   r e a l   m o d e ! "
msg1:   .ascii "E S ,   D S   s t i l l   r e a l   m o d e ! "
msg2:   .ascii "F i n a l l y   i n   p r o t e c t e d   m o d e ! "
msg3:	.ascii "E S ,   D S   s t i l l   p r o t e c t e d   m o d e ! "
msg4:   .ascii "b a c k   t o   B O R I N G   o l d   r e a l   m o d e "
gdtr:	.word gdt_end-gdt-1	
	.long 0                  
gdt:	.byte 0,0			
	.byte 0,0			
	.byte 0			
	.byte 0			
	.byte 0			
	.byte 0			

.equ LINEAR_SEL, .-gdt
	.word 0xFFFF		
	.word 0			
	.byte 0
	.byte 0x92			
        .byte 0xCF                 
	.byte 0
.equ SYS_CODE_SEL, .-gdt
gdt2:   .word 0xFFFF               
	.word 0			
	.byte 0
	.byte 0x9A			
        .byte 0xCF                 
	.byte 0
.equ SYS_DATA_SEL, .-gdt
gdt3:   .word 0xFFFF               
	.word 0			
	.byte 0
	.byte 0x92			
        .byte 0xCF                 
	.byte 0
.equ REAL_CODE_SEL, .-gdt
gdt4:   .word 0xFFFF
	.word 0			
	.byte 0
	.byte 0x9A			
	.byte 0			
	.byte 0
.equ REAL_DATA_SEL, .-gdt
gdt5:   .word 0xFFFF
	.word 0			
	.byte 0
	.byte 0x92			
	.byte 0		
	.byte 0
gdt_end:
	.byte 0
