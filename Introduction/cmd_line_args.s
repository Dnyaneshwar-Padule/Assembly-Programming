.section .text
.globl _start

_start:
    movl 8(%esp), %ecx     # argv[1]

    movl $4, %eax          # write syscall
    movl $1, %ebx          # stdout
    movl $10, %edx         # bytes to print
    int $0x80

    movl $1, %eax          # exit
    xorl %ebx, %ebx
    int $0x80
