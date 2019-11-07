.code16					#pc starts here BIOS: 0000:07c0 
.text					#code section
	jmp _pc_start			#bypass data
_pc_os_version:				#our version os
       .asciz "Morgoth's OS ver 0001"	#banner
_pc_ten:
       .word 0xa
_pc_cnt:
       .word 0x0
_pc_reg:
       .asciz "LRESULT: $"
_pc_start:				#cpu starts from this 
	jmp _pc_critical_init		#do the critical init of CS, DS, SS
_pc_done_critical_init:			#ok it is done
	call _pc_angry_stack		#test stack working
	#call _pc_regs
	call _pc_wait_ESC
	call _pc_test_fpu		#test working of FPU
	call _pc_init_vga		#set 320:200:256 13H mode
	call _pc_vga_demo		#display palette
	call _pc_wait_ESC		#wait 4 esc
	call _pc_text_mode		#set text mode
	call _pc_text_out		#write banner to stdout
	call _pc_regs			#should print out registers
	call _pc_wait_ESC		#wait 4 esc
	call _pc_init_vga		#set gmode
	call _pc_vga_demo		#palette again?
	call _pc_wait_ESC		#wait 4 esc
	call _pc_text_mode		#text mode
	call _pc_text_out		#another banner
	call _pc_regs
	call _pc_stop			#halt the machine
	ret				#should be there (never)
_pc_critical_init:			#setup control registers
        cli 				#we don't want interrupts there
					#CS is already set if we are here
					#and BIOS set it to SEG:07c0 = PHISICAL_ADDR: 00007c00
        movw $0x7c0,%ax			#ax = 0x7c0 (FIXME) I am right there?
        movw %ax,%ds			#ds = 0x7c00 0001:07c0 = 0x10*0x7c0 = 0x7c00 (FIXME) ?
					#ds = 0x7c0 in REAL mem (16*seg+off) = 10h*7c0h+0h = 7c00h [OK]
        movw %ax,%ss			#stack segment also there
        movw $0x2000,%sp		#setup 8k stack (should be enough) SP don't segment addres
					#but linear so 0x2000 mean just 8KB of STACK
					#we have 64K for CODE,DATA,STACK (and 8k FOR STACK IS ENOUGH)
					#expect 40K CODE AND 16K DATA (or sth)
        sti 				#now allow interrupts
	jmp _pc_done_critical_init	#ret from CRIT_INIT
_pc_test_fpu:				#test FPU
	fldpi				#st(0) = PI
	fsqrt				#st(0) = pierw z PI
	fchs				#st(0) = -(pierwiastek z PI)
	ftst				#porownaj st z 0.0
	fstsw %ax			#FpuSTatuSWord => AX
	sahf				#AX => CPU Flags
	fcomp				#just free st (compare it with st(1) and free)
					#IF we didn't do that and next loop will go there
					#after 8 loops all FPU reg would be full
					#and after 9 loop we will have FPU exception
					#without setup handler FPU will just product bad results
					#I've checed it !!!
	ja _pc_test_fpu			#if result is more than 0 (shouldn't be)
					#enter dead-loop (if your FPU is OK will pass this)
	movq %mm1, %mm0			#some MMX instruction needed ?
	ret				#return to heaven and leave FPU alone :-)
_pc_angry_stack:			#uses some stack instruction
	pushf				#to examine that it works (save flags)
	pushw %ax			#save bx,ax
	pushw %bx			#and then all registers
	pusha				#restore
	popa				#them
	popw %bx			#in the inverted
	popw %ax			#order: ax,bx
	popf				#and flags
	ret				#return
_pc_stop:				#stop lablel
	hlt				#halt CPU
	jmp _pc_stop			#preserve
_pc_init_vga:				#set 320:200:256 13H mode
	movw $0x0013, %ax		#ah=0, al=13h, int 10h 
	int $0x10			#bios call 0x10 (from INTR_TABLE setup by BIOS)
	ret				#go back
_pc_vga_demo:				#woanna draw palette
	movw $0xa000, %bx		#set address of GRAPHIC_CARD bios setup to A0000 so (FIXME)
	movw %bx, %es			#our address is 0001:A000 = 0x10*A000 = A0000 from BIOS
	movw $0x0, %di			#segment segment*16+offset AAAA:BBBB AAAA=SEGMENT; BBBB=offset
					#so 0x7c0 => SEGMENT OFFSET GIVES US 0x7c00 and
					#A000 => SEGMENT gives area A0000 up to FFFFF (GRAPHIC_CARD)
					#ES extend seg = addr.GC, DI=0 (index of cur point)
_pc_line_y:				#scanline
	xorb %al, %al			#AL=0
_pc_line_x:				#cross
	stosb				#send byte ES:DI into correct place in GC-MEM
	incb %al			#AL++
	cmpb $0xFF, %al			#we dont't want overflow 255
	jne _pc_line_x			#if so continue this line
	addw $0x41, %di			#di += 65 because 65 + 255 = 320 (we have 320:200:8 mode)
	cmpw $63320, %di		#is di = MEM_MAX(13h)
	jb _pc_line_y			#if below draw next scanline
	ret				#end demo now
_pc_text_mode:				#set text mode for PC
	movw $0x3, %ax			#al=3, ah=0, int 10h
	int $0x10			#so do it
	ret				#back to caller
_pc_wait_ESC:				#read port of keyboard untill ESC code found
	inb $0x60, %al			#get from  port 60h number to al
	cmpb $0x1, %al			#AL?=1 (ESC code sends 1)
	jne _pc_wait_ESC		#if not loop
	ret				#just before ESC scan (cpu works only for this stuff)
					#so it is about 0.000000001s after ESC is pressed and signal
					#sent to MotherBoard
_pc_text_out:				#print out our banner
       movw $_pc_os_version,%si		#data segment is set to SEG=07c0:offset of _pc_os_version
       					#offset probable 8bytes so physical address is: 00007c08 
					#real mode (BELOW 64K) about 31K
_labl_0000: 				#the first text label
	movb (%si),%al			#al = litera[si]
	cmpb $0x00,%al 			#but shouldn't be \x00
	jne _labl_0001			#isn't so INT and put it to stdout
	ret				#was 0 bye
_labl_0001:				#we have good letter in AL
	movb $0x0e,%ah			#and correct func_num in AH 0eh (write_letter_to_stdout)
	xorw %bx,%bx 			#set bx to 0 (I don't know for what?)
	int $0x10			#call int 10h (BIOS) get proc_addres from IDT(2*10h)
	incw %si			#IDT initially setup by BIOS to (probably 0x0 first 512bytes
					#of RAM is the interrupt procedure-address table)
					#si++ (get next letter) go to check section
	jmp _labl_0000			#now
	ret				#bye
					#we should do a whoule about 5111-512 byte
					#there must be 55AAH for BIOS bootable flag
					#will be done this way (I think)
					#... instr; jmp after_boot_magic; nop; nop; .word 0x55aa; 
					#nop; after_boot_magic:; nextinstr; ...
_pc_regs:
	push %eax
	call _pc_print_stack
	addw $0x4, %sp
	ret
_pc_print_stack:
	popw %bp
	popl %eax
_pc_digits:
	movl $0x0, %edx
	divl _pc_ten
	#
	pushw %dx
	incw _pc_cnt
	cmpw $0x0, %ax
	jne _pc_digits
	#
	movb $0x9, %ah
	movw $_pc_reg, %dx
	int $0x21
	movw _pc_cnt, %cx
_pc_write_loop:
	popw %dx
	add $0x30, %dx
	movb $0x0, %ah
	int $0x21
	loop _pc_write_loop

	#
	subw $0x4, %sp
	push %bp
	ret
