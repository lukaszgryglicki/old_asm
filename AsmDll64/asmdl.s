.globl asm_call_implicit_function
.data
mem:
.long 0x0,0x0
.text
asm_call_implicit_function:		
	movq %rbx, %rdi
	movq %rsi, %rcx
	movq %rdx, %rsi
	pushq %rax
	pushq %rbx
	pushq %rcx
	pushq %rdx
	pushq %rsi
	pushq %rdi
	cmpq $0x0, %rdi			#null cannot be called
	jne routine_ok			#but other can
	pushq %rdi
	pushq %rsi
	pushq %rdx
	pushq %rcx
	pushq %rbx
	pushq %rax
	retq				#cowardly refuse
routine_ok:				#now we have nonnull function
	movq %rcx, %rax			#current arg
	salq $0x3, %rax			#need *8 becouse it is ptr 64bit machine
	subq $0x8, %rax			#nargs-1 (-8) push in inverted direct
	movq %rcx, %rbx			#we want copy
	cmpq $0x0, %rcx			#is there 0 args
	jle args_processed		#yes there is
push_stack:				#push args to stack loop
	pushq (%rsi,%rax)		#argptr:ESI, BY OFFSET EAX (which)
	subq $0x8, %rax			#next argument (inverted direct)
	decq %rcx			#processed--
	cmpq $0x0, %rcx			#all?
	jg push_stack			#no
args_processed:				#we put args to stack
	callq *(%rdi)			#now call routine
	cmpq $0x0, %rbx			#do not want clean stack?
	jle routine_done		#yes there were no args
	movq %rbx, %rcx			#restory ECX counter
pop_stack:				#clean stack
	popq %rbx			#to EBX no more needed
	decq %rcx			#to_clean--
	cmpq $0x0, %rcx			#all clean?
	jg pop_stack			#no
routine_done:				#yes, cleaned, return now
	movq %rax, (mem)		#we want return code in memory
	pushq %rdi
	pushq %rsi
	pushq %rdx
	pushq %rcx
	pushq %rbx
	pushq %rax
	movq (mem), %rax		#through popal
	retq				#return to C caller
	
