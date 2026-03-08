# This function calculates factorial of a number, and gives the result as the return status

.section .data
# No Global data

.section .text
.globl _start

_start:
    pushl $4        # The function parameter, This is the number to find factorial
    call factorial
    addl $4, %esp   # Remove parameters from the stack

    movl %eax, %ebx # %eax contains the return value, move it into ebx (as the return status)
    movl $1, %eax   # Exit system call
    int $0x80       # interrupt


.type factorial, @function
factorial:
    pushl %ebp      # push old base pointer
    movl %esp, %ebp # Update current base pointer
    
    movl 8(%ebp), %eax  # Get the factorial number in eax

    cmpl $1, %eax   # If number is 1, return from function
    je return

    decl %eax
    pushl %eax
    call factorial
    movl 8(%ebp), %ebx
    imull %ebx, %eax

    return:
        movl %ebp, %esp
        popl %ebp
        ret
        