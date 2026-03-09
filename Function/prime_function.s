.section .data

.section .text
.globl _start

_start:
    pushl $22
    call is_prime
    addl $4, %esp

    movl %eax, %ebx
    movl $1, %eax
    int $0x80

.type is_prime, @function
is_prime:
    pushl %ebp
    movl %esp, %ebp

    movl $2, %ecx           # using CX as conuter

    cmpl $1, 8(%ebp)       # If number is 1 or smaller than 1, return with false
    jle return_false

    prime_loop_start:
        cmpl %ecx, 8(%ebp)
        je return_true
        movl 8(%ebp), %eax
        movl $0, %edx
        divl %ecx
        cmpl $0, %edx
        je return_false
        incl %ecx
        jmp prime_loop_start

    return_true:
        movl $1, %eax
        jmp return
    
    return_false:
        movl $0, %eax
        jmp return

    return:
        movl %ebp, %esp     # clear local storage
        popl %ebp           # Update bp to old base
        ret
