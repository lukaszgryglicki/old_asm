.globl asm_call_implicit_function
.data
mem:
.long 0x0
.text
asm_call_implicit_function:		
	movl 0x4(%esp), %edi		#have routine to run	
	movl 0x8(%esp), %ecx		#have num_of_args
	movl 0xc(%esp), %esi		#have arg_array
	pushal				#all C registers
	cmpl $0x0, %edi			#null cannot be called
	jne routine_ok			#but other can
	popal				#all C registers
	ret				#cowardly refuse
routine_ok:				#now we have nonnull function
	movl %ecx, %eax			#current arg
	sall $0x2, %eax			#nned *4 becouse it is pointer
	subl $0x4,%eax			#nargs-1 (-4) push in inverted direc.
	movl %ecx, %ebx			#we want copy
	cmpl $0x0, %ecx			#is there 0 args
	jle args_processed		#yes there is
push_stack:				#push args to stack loop
	pushl (%esi,%eax)		#argptr:ESI, BY OFFSET EAX (which)
	subl $0x4, %eax			#next argument (inverted direct)
	decl %ecx			#processed--
	cmpl $0x0, %ecx			#all?
	jg push_stack			#no
args_processed:				#we put args to stack
	call *(%edi)			#now call routine
	cmpl $0x0, %ebx			#do not want clean stack?
	jle routine_done		#yes there were no args
	movl %ebx, %ecx			#restory ECX counter
pop_stack:				#clean stack
	popl %ebx			#to EBX no more needed
	decl %ecx			#to_clean--
	cmpl $0x0, %ecx			#all clean?
	jg pop_stack			#no
routine_done:				#yes, cleaned, return now
	mov %eax, (mem)			#we want return code in memory
	popal				#restore all C registers
	mov (mem), %eax			#through popal
	ret				#return to C caller
	
