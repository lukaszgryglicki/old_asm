
.data                       
msg:
    .asciz "Hello\n" 
.text               
.global _start
_start:              
    pushl   $6      
    pushl   $msg       
    pushl   $1          
    movl    $4, %eax     
    call    kernel
    addl    $12, %esp     
    pushl   $0             
    movl    $1, %eax        
    call    kernel
kernel:
 int     $0x80     
 ret
