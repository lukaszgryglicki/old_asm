[ORG 0x100]
[BITS 16]
start:	xor ebx,ebx
	mov bx,ds                       ; BX=segment
	shl ebx,4                       ; BX="linear" address of segment base
	mov eax,ebx
	mov [gdt2 + 2],ax               ; set base address of 32-bit segments
	mov [gdt3 + 2],ax
	mov [gdt4 + 2],ax               ; set base address of 16-bit segments
	mov [gdt5 + 2],ax
	shr eax,16
	mov [gdt2 + 4],al
	mov [gdt3 + 4],al
	mov [gdt4 + 4],al
	mov [gdt5 + 4],al
	mov [gdt2 + 7],ah
	mov [gdt3 + 7],ah
	mov [gdt4 + 7],ah
	mov [gdt5 + 7],ah
        lea eax,[gdt + ebx]             ; EAX=PHYSICAL address of gdt
        mov [gdtr + 2],eax
	cli
	xor ax,ax
	mov es,ax
	mov edx,[es:0x0D * 4]		; INT 0Dh vector -> EDX
	mov [es:0x0D * 4 + 2],cs
	lea ax,[trap]
	mov [es:0x0D * 4],ax
	mov ebx,0xB809A			; ES still 0
	mov byte [es:ebx],'R'		; 'R' in upper right corner of screen
	mov ax,cs
	mov [RealModeCS],ax
	lea ax,[do_rm]
	mov [RealModeIP],ax
	mov ax,0xB800
	mov es,ax
	lgdt [gdtr]
	mov eax,cr0
	or al,1
	mov cr0,eax
        lea si,[msg0]                   ; -> "still in real mode!"
        mov di,(80 * 1 + 2) * 2         ; row 1, column 2
        mov cx,38
        cld
        rep movsb
	jmp SYS_CODE_SEL:do_pm          ; jumps to do_pm
trap:	mov ax,0xB800
	mov fs,ax
	mov byte [fs:0x9C],'!'
	pop ax				; point stacked IP beyond...
	add ax,5			; ...the offending instruction
	push ax
	iret
[BITS 32]
do_pm:
        xor edi,edi
        xor esi,esi
	lea si,[msg1]                   ; -> "ES, DS still real mode!"
        mov di,(80 * 2 + 3) * 2         ; row 2, column 3
        mov ecx,46
        cld
        rep movsb
	mov ax,SYS_DATA_SEL
	mov ds,ax
	mov ss,ax
	mov ax,LINEAR_SEL
	mov es,ax
	mov byte [es:dword 0xB8000],'0'
	mov byte [es:dword 0xB8002],'1'
	mov byte [es:dword 0xB8004],'2'
	mov byte [es:dword 0xB8006],'3'
	lea esi,[msg2]                  ; -> "Finally in protected mode!"
	mov edi,0xB8000 + (80 * 3 + 4) * 2      ; row 3, column 4
	mov ecx,52
	cld
	rep movsb
	jmp REAL_CODE_SEL:do_16
[BITS 16]
do_16:
	mov ax,REAL_DATA_SEL
	mov ss,ax
	mov ds,ax			; leave ES alone
	mov eax,cr0
	and al,0xFE
	mov cr0,eax
	jmp far [RealModeIP]
[BITS 16]
do_rm:	mov byte [es:dword 0xB8008],'4'
	xor ax,ax
	mov es,ax
	mov byte [es:dword 0xB800A],'5'
	lea esi,[msg3]			; -> "ES, DS still protected mode!"
	mov edi,0xB8000 + (80 * 4 + 5) * 2      ; row 4, column 5
	mov ecx,56
	cld
	a32				; same as 'db 0x67'
	rep movsb
	mov ax,cs
	mov ds,ax
	mov ss,ax
	mov ax,0xB800
	mov es,ax
	lea si,[msg4]                   ; -> "back to BORING old real mode"
	mov di,(80 * 5 + 6) * 2         ; row 5, column 6
	mov cx,56
	cld
	rep movsb
	xor ax,ax
	mov es,ax
	mov [es:0x0D * 4],edx		; EDX -> INT 0x0D vector
	sti
	mov ax,0x4C00
	int 0x21
RealModeIP:
        dw 0

RealModeCS:
	dw 0
msg0:   db "s t i l l   i n   r e a l   m o d e ! "
msg1:   db "E S ,   D S   s t i l l   r e a l   m o d e ! "
msg2:   db "F i n a l l y   i n   p r o t e c t e d   m o d e ! "
msg3:	db "E S ,   D S   s t i l l   p r o t e c t e d   m o d e ! "
msg4:   db "b a c k   t o   B O R I N G   o l d   r e a l   m o d e "
gdtr:	dw gdt_end - gdt - 1	; GDT limit
	dd gdt                  ; (GDT base gets set above)
gdt:	dw 0			; limit 15:0
	dw 0			; base 15:0
	db 0			; base 23:16
	db 0			; type
	db 0			; limit 19:16, flags
	db 0			; base 31:24

LINEAR_SEL	equ	$-gdt
	dw 0xFFFF		; limit 0xFFFFF
	dw 0			; base 0
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
        db 0xCF                 ; page-granular, 32-bit
	db 0
SYS_CODE_SEL	equ	$-gdt
gdt2:   dw 0xFFFF               ; limit 0xFFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x9A			; present, ring 0, code, non-conforming, readable
        db 0xCF                 ; page-granular, 32-bit
	db 0
SYS_DATA_SEL	equ	$-gdt
gdt3:   dw 0xFFFF               ; limit 0xFFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
        db 0xCF                 ; page-granular, 32-bit
	db 0
REAL_CODE_SEL	equ	$-gdt
gdt4:   dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x9A			; present, ring 0, code, non-conforming, readable
	db 0			; byte-granular, 16-bit
	db 0
REAL_DATA_SEL	equ	$-gdt
gdt5:   dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
	db 0			; byte-granular, 16-bit
	db 0
gdt_end:
