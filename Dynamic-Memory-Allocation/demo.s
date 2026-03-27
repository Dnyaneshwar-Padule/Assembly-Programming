.equ ST_VAR_1, -4
.equ ST_VAR_2, -8
.section .text
.globl _start
_start:
    movl %esp, %ebp
    subl $8, %esp

    call allocate_init

    pushl $4
    call allocate
    addl $4, %esp
    movl %eax, ST_VAR_1(%ebp)

    pushl $4
    call allocate
    addl $4, %esp
    movl %eax, ST_VAR_2(%ebp)

    movl ST_VAR_1(%ebp), %ebx
    movl ST_VAR_2(%ebp), %ecx

    movl $2, (%ebx)
    movl $4, (%ecx)

    movl (%ebx), %eax
    addl (%ecx), %eax

    pushl %ecx
    call deallocate
    addl $4, %esp
    
    pushl %ebx
    call deallocate
    addl $4, %esp


    movl %eax, %ebx
    movl $1, %eax
    int $0x80

