# This function exits with printing the error code on STDERR

.include "../linux.s"

.section .data
    colon:
        .ascii ": \0"

# Parameters:
#   1. ERROR_CODE (8)
#   2. ERROR_MESSAGE (12)
.section .text
.globl error_exit

.equ ST_ERROR_CODE, 8
.equ ST_ERROR_MSG, 12

.type error_exit, @function
error_exit:
    pushl %ebp
    movl %esp, %ebp

    # Print Error code
    movl ST_ERROR_CODE(%ebp), %ecx
    pushl %ecx
    call count_characters
    popl %ecx               # Message
    movl %eax, %edx         # message length
    movl $STDERR, %ebx      # File descriptor
    movl $SYS_WRITE, %eax   # write system call
    int $LINUX_SYSCALL

    # Print a colon
    movl $SYS_WRITE, %eax
    movl $STDERR, %ebx
    movl $colon, %ecx
    movl $2, %edx
    int $LINUX_SYSCALL

    # Print the message
    movl ST_ERROR_MSG(%ebp), %ecx
    pushl %ecx
    call count_characters
    popl %ecx
    movl %eax, %edx
    movl $STDERR, %ebx
    movl $SYS_WRITE, %eax
    int $LINUX_SYSCALL

    pushl $STDERR
    call write_new_line
    
    # Exit with status 1
    movl $SYS_EXIT, %eax
    movl $0, %ebx
    int $LINUX_SYSCALL
