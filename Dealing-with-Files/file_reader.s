# This program takes a file name as command line argument and printns it's contents on the console.

.section .data
# No Data

# CONSTANTS #

# System calls
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6

# Interrupt
.equ LINUX_SYSCALL, 0x80

# File Opening mode
.equ O_RDONLY, 0

# Standard File Descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

# End of file
.equ EOF, 0

.section .bss
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE


.section .text

.equ ST_SIZE_RESERVE, 4 # For storing Input file descriptor
.equ ST_FD_IN, -4
.equ ST_ARGC, 0
.equ ST_ARGV_0, 4 # Program name
.equ ST_ARGV_1, 8 # First command line argument


.globl _start
_start:
    movl %esp, %ebp
    subl $ST_SIZE_RESERVE, %esp

    open_file:
        movl $SYS_OPEN, %eax        # Open system call
        movl ST_ARGV_1(%ebp), %ebx  # File name
        movl $O_RDONLY, %ecx        # Open mode, read only
        movl $0666, %edx            # File permissions
        int $LINUX_SYSCALL

    
    cmpl $0, %eax
    jle stop_reading

    store_fd_in:
        movl %eax, ST_FD_IN(%ebp)   # Store file descriptor

    start_reading_file:
        movl $SYS_READ, %eax        # Read system call
        movl ST_FD_IN(%ebp), %ebx   # File descriptor
        movl $BUFFER_DATA, %ecx     # Buffer
        movl $BUFFER_SIZE, %edx     # buffer_size
        int $LINUX_SYSCALL

        cmpl $0, %eax
        jle  stop_reading

        print_content:
            pushl $BUFFER_DATA  # 2nd argument, Buffer data
            pushl %eax          # 1st argument, size of buffer
            call display_content
            addl $8, %esp       # Restore stack
            jmp start_reading_file     

    stop_reading:
        # Close File
        movl $SYS_CLOSE, %eax
        movl ST_FD_IN(%ebp), %ebx
        int $LINUX_SYSCALL

        # Exit
        movl $SYS_EXIT, %eax
        movl $0, %ebx
        int $LINUX_SYSCALL


.equ ST_BUFFER, 12
.equ ST_BUFFER_LEN, 8

.type display_content, @function
display_content:
    pushl %ebp      # old base
    movl %esp, %ebp
    
    print_data:
        movl $SYS_WRITE, %eax           # write system call
        movl $STDOUT, %ebx              # file descriptor, STDOUT
        movl ST_BUFFER(%ebp), %ecx         # Buffer location
        movl ST_BUFFER_LEN(%ebp), %edx    # buffer length
        int $LINUX_SYSCALL

    return:
        movl %ebp, %esp
        popl %ebp
        ret



