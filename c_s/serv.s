.code64
.globl _start
.data
sigact:
	sa_handler: .long 0
	sa_flags:   .int 0
	sa_mask:    .fill 4, 4, 0
msg_sc:
	.string "Signal catched!\n"
len_sc = .-msg_sc-1
msg_csock:
	.string "Closing socket..\n"
len_csock = .-msg_csock-1
msg_serr:
	.string "Sigaction failed\n"
len_serr = .-msg_serr-1
msg_sorr:
	.string "Socket failed\n"
len_sorr = .-msg_sorr-1
msg_berr:
	.string "Bind failed\n"
len_berr = .-msg_berr-1
msg_lerr:
	.string "Listen failed\n"
len_lerr = .-msg_lerr-1
msg_waitc:
	.string "Waiting for client..."
len_waitc = .-msg_waitc-1
msg_larr:
	.string "Accept failed!\n"
len_larr = .-msg_larr-1
msg_spanic:
	.string "Server Panic - exiting!\n"
len_spanic = .-msg_spanic-1
msg_child:
	.string "Client accepted.\n"
len_child = .-msg_child-1
sockaddr:				# bytes ARE NOT transferred to INET order
	sin_len:    .byte 16		# length
	sin_family: .byte 2		# AF_INET
	sin_port:   .word 1777		# port number
	in_addr:
		in_addr_t: .long 0 	# INADDR_ANY
	sin_zero:    .fill 8,1,0
socket:
	.int 0
csock:
	.int 0
.text           
_start:
	call setup_signals
	call run_server
	call close_socket
	movq    $0, %rdi
	call kern_exit
kern_exit:
	movq $0x1, %rax
	syscall
	retq
kern_write:
	movq $0x4, %rax
	syscall
	retq
kern_sigaction:
	movq $416, %rax
	syscall
	retq
kern_socket:
	movq $97, %rax
	syscall 
	retq
kern_bind:
	movq $104, %rax
	syscall 
	retq
kern_close:
	movq $6, %rax
	syscall 
	retq
kern_listen:
	movq $106, %rax
	syscall 
	retq
kern_accept:
	movq $30, %rax
	syscall 
	retq
kern_fork:
	movq $2, %rax
	syscall 
	retq
setup_signals:
	movq $catch_int, (sigact)
				# sigfillset(&(act.sa_mask));
				# how to do this, is not system call!
				# works without but...
	movq	$0, %rdx
	movq    $sigact, %rsi
	movq    $2, %rdi
	call kern_sigaction
	cmpq    $-1, %rax
	jne signals_ok
	movq    $len_serr, %rdx
	movq    $msg_serr, %rsi
	movq    $2,   %rdi
        call kern_write
	movq   $1, %rdi
	call kern_exit
signals_ok:
	retq
close_csock:
	movl    (csock), %r8d
	cmpl    $0, %r8d
	jl   csock_broken
	movq    $len_csock, %rdx
	movq    $msg_csock, %rsi
	movq    $1,   %rdi
        call kern_write
	movl    (csock), %edi
	call kern_close
	movl $0, (csock)
csock_broken:	
	retq
close_socket:
	movl    (socket), %r8d
	cmpl    $0, %r8d
	jl   socket_broken
	movq    $len_csock, %rdx
	movq    $msg_csock, %rsi
	movq    $1,   %rdi
        call kern_write
	movl    (socket), %edi
	call kern_close
	movl $0, (socket)
socket_broken:	
	retq
catch_int:
	pushq	%rbp
	movq	%rsp, %rbp

	movq    $len_sc, %rdx
	movq    $msg_sc, %rsi
	movq    $1,   %rdi
        call kern_write
	call close_socket
	movq    $0, %rdi
	call kern_exit
	
	leave
	retq
run_server:
	movq    $0, %rdx
	movq    $1, %rsi	# SOCK_STREAM
	movq    $2,   %rdi	# AF_INET
	call kern_socket
	cmpq    $-1, %rax
	jne socket_ok
	movq    $len_sorr, %rdx
	movq    $msg_sorr, %rsi
	movq    $2,   %rdi
        call kern_write
	movq   $1, %rdi
	call kern_exit
socket_ok:
	movl	%eax, (socket)
	movq    $sockaddr, %rdx
	movl    (sin_len), %esi
	movl    (socket),   %edi
	call kern_bind
	cmpq    $-1, %rax
	jne bind_ok
	movq    $len_berr, %rdx
	movq    $msg_berr, %rsi
	movq    $2,   %rdi
        call kern_write
	jmp server_panic
bind_ok:
	movq    $5, %rsi
	movl    (socket),  %edi
	call kern_listen
	cmpq    $-1, %rax
	jne listen_ok
	movq    $len_lerr, %rdx
	movq    $msg_lerr, %rsi
	movq    $2,   %rdi
        call kern_write
	jmp server_panic
listen_ok:
accept_infinite:
	movq    $len_waitc, %rdx
	movq    $msg_waitc, %rsi
	movq    $1,   %rdi
        call kern_write
	movq    $0, %rdx
	movq    $0, %rsi
	movl    (socket),   %edi
	call kern_accept
	cmpq    $-1, %rax
	jne accept_ok
	movq    $len_larr, %rdx
	movq    $msg_larr, %rsi
	movq    $2,   %rdi
        call kern_write
	jmp server_panic
accept_ok:
	movl %eax, (csock)
	call kern_fork
	cmpl $0, %eax
	jg back_to_server
	jl server_panic
	call children_proc
	call close_csock
	movq $0, %rdi
	call kern_exit
back_to_server:	
	jmp accept_infinite
server_panic:
	movq    $len_spanic, %rdx
	movq    $msg_spanic, %rsi
	movq    $2,   %rdi
        call kern_write
	retq
children_proc:
	movq    $len_child, %rdx
	movq    $msg_child, %rsi
	movq    $1,   %rdi
        call kern_write
	retq
