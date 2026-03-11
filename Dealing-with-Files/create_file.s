# This program create a new file and writes "Hello World, from assembly!" into it
# The file name will be provided as command line argument.

.section .data
    greeting_msg: .ascii "Hello World, from assembly!\0" 

.equ GREETING_MSG_LEN, 27

# CONSTANTS #
.equ SYS_EXIT, 1
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6

.equ LINUX_SYSCALL, 0x80

.equ O_RDONLY, 0
.equ O_CREATE_WRONLY_TRUNC, 03101
.equ BASIC_FILE_PERMISSIONS, 0666

# No need of buffer


# STACK STUFF
.equ ST_SIZE_RESERVE, 4
.equ ST_FD_OUT, -4
.equ ST_ARGC, 0         # Command line argument count
.equ ST_ARGV_0, 4       # program name
.equ ST_ARGV_1, 8       # file name

.section .text
.globl _start
_start:
    movl %esp, %ebp

    open_file:
        movl $SYS_OPEN, %eax
        movl ST_ARGV_1(%ebp), %ebx
        movl $O_CREATE_WRONLY_TRUNC, %ecx
        movl $BASIC_FILE_PERMISSIONS, %edx
        int $LINUX_SYSCALL

    store_fd_out:
        movl %eax, ST_FD_OUT(%ebp)

    start_writing:
        movl $SYS_WRITE, %eax
        movl ST_FD_OUT(%ebp), %ebx
        movl $greeting_msg, %ecx
        movl $GREETING_MSG_LEN, %edx
        int $LINUX_SYSCALL

    close_file:
        movl $SYS_CLOSE, %eax
        movl ST_FD_OUT(%ebp), %ebx
        int $LINUX_SYSCALL

    exit:
        movl $SYS_EXIT, %eax
        movl $0, %ebx
        int $LINUX_SYSCALL
