.sectio .data

.section .text
.globl _start

_start:
    pushl $23
    call is_prime
    addl $4, %esp

    movl %eax, %ebx
    movl $1, %eax
    int $0x80

.type is_prime, @function
is_prime:
    pushl %ebp
    movl %esp, %ebp

    movl %ebx, -4(%ebp)     # BX containing the number
    movl $2, %ecx           # using CX as conuter

    cmpl %ebx, $1       # If number is 1 or smaller than 1, return with false
    jge return

    prime_loop_start:
        cmpl %ecx, -4(%ebp)
        jmp return_true
        

    return_true:
        movl $1, %eax
        jmp return
    
    return_false:
        movl $2, %eax
        jmp return

    return:
    movl %ebp, %esp     # clear local storage
    popl %ebp           # Update bp to old base
    ret

