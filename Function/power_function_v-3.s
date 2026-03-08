.section .data


.section .text
.globl _start
_start:
    pushl $0
    pushl $12
    call power
    addl $8, %esp

    movl %eax, %ebx
    movl $1, %eax
    int $0x80


.type power, @function
power:
    pushl %ebp
    movl %esp, %ebp
    subl $4, %esp

    movl 8(%ebp), %ebx
    movl 12(%ebp), %ecx
    movl %ebx,-4(%ebp)

    cmpl $0, %ecx
    je zero_power

    zero_power:
        movl $1, -4(%ebp)
        jmp exit

    power_loop_start:
        cmpl $1, %ecx
        je exit
        movl -4(%ebp), %eax
        movl %ebx, %eax
        movl %eax, -4(%ebp)
        decl %ecx
        jmp power_loop_start

    exit:
        movl -4(%ebp), %eax
        movl %ebp, %esp
        popl %ebp
        ret
