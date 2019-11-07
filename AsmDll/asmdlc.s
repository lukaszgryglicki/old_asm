.globl asm_call_implicit_function
.text
asm_call_implicit_function:		# ENTRY, VARIABLE ARGUMENT LIST
	movl 0x4(%esp), %edi		# THIS ROUTINE RUN
	movl 0x8(%esp), %ecx		# HOW MUCH ARGS?
	pushal				# PUSH ALL REGISTERS TO BE SAFE
					# EVERYWHERE OFFSETS+20, BECAUSE OF
					# 0x8 * 0x4 = 0x20, ALL CPU REGS
	movl %ecx, %ebx			# EBX=COPY
	cmpl $0x0, %ecx			# IF NO ARGS GIVEN
	jle args_processed		# IF LESS THAN 0 JUMP
push_stack:				# LOPP ALL ARGS
	pushl 0x34(%esp)		# PUSH ARGUMENT, WITH PUSH ESP CHANGES
					# FIRST DECREMENT ESP BY 4 THEN
					# PUSH TO STACK, SO REALLY ESP+0x10
					# IS PUSHED, so 0x4 is RET_PTR
					# 0x8 IS ROUTINE, 0xC IS NARGS
					# AND ARGUMENTS FOLLOWS...
	decl %ecx			# DECREMENT ARGS COUNTER
	cmpl $0x0, %ecx			# ALL DONE ALREADY?
	jg push_stack			# MORE ARGS FOLLOWS
args_processed:				# ALL ARGS PASSED ON STACK
	call *(%edi)			# CALL ROUTINE
	cmpl $0x0, %ebx			# COMPARE WITH COPY
	jle routine_done		# DONT NEED TO CLEAN STACK
	movl %ebx, %ecx			# RESTRE POP NUMBER
pop_stack:				# POPPING FROM STACK
	popl %ebx			# CLEAR EBX, NO MORE NEEDED
	decl %ecx			# DECREAMENT INDEX
	cmpl $0x0, %ecx			# ALL STACK CLEARED?
	jg pop_stack			# NO, MORE TO CLEAR FOLLOWS
routine_done:				# ALL STACK CLEAN
	popal				# RESTORE ALL REGISTERS TO BE SAFE
	ret				# RETURN TO C CALLER
	
