# This program writes a newline character to a file

.include "../linux.s"

.section .data
    new_line:
        .ascii "\n\0"

.section .text
.globl write_new_line

.equ ST_WR_NW_LINE_FILE_DESCRIPTOR, 8

.type write_new_line, @function
write_new_line:
    pushl %ebp
    movl %esp, %ebp

    movl $SYS_WRITE, %eax
    movl ST_WR_NW_LINE_FILE_DESCRIPTOR(%ebp), %ebx
    movl $new_line, %ecx
    movl $1, %edx
    int $LINUX_SYSCALL

    movl %ebp, %esp
    popl %ebp
    ret
