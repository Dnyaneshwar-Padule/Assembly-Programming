# This program prints the command line arguments

.section .data
    new_line: .ascii "\n\0"
.equ NEW_LINE_LEN, 1

### NO DATA ##

### CONSTANTS ####
.equ SYS_EXIT, 1
.equ SYS_WRITE, 4

.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

.equ LINUX_SYSCALL, 0x80

### INITIAL STACK
.equ ST_ARGC, 0
.equ ST_ARGV_0, 4
.equ ST_ARGV_1, 8
.equ ST_ARGV_2, 12
# .
# .
# .
# And so on....

 
.section .text
.globl _start
_start:
    movl %esp, %ebp

    movl $1, %esi                   # The current argument to print


    start_printing_argv:
        cmpl %esi, ST_ARGC(%ebp)
        jl stop_printing_argv 

        # get count of the first argument
        pushl (%ebp, %esi, 4)
        call count_str_length
        addl $4, %esp

        print_argv:
            movl %eax, %edx
            movl $SYS_WRITE, %eax
            movl $STDOUT, %ebx
            movl (%ebp, %esi, 4), %ecx
            int $LINUX_SYSCALL

        print_new_line:
            movl $SYS_WRITE, %eax
            movl $STDOUT, %ebx
            movl $new_line, %ecx
            movl $NEW_LINE_LEN, %edx
            int $LINUX_SYSCALL

        incl %esi
        jmp start_printing_argv 

    stop_printing_argv:
        movl $SYS_EXIT, %eax
        movl $0, %ebx
        int $LINUX_SYSCALL


# This function counts the length of argument string
# Parameter:
#   1. The string location
# Return:
#   The string length
.equ ST_STR, 8
.type count_str_length, @function
count_str_length:
    pushl %ebp 
    movl %esp, %ebp

    # movl $0, %eax               # eax will store the current length
    movl ST_STR(%ebp), %ebx     # ebx will store the string address
    movl $0, %edi               # edi will be offset for current byte

    start_counting_str_length:
        cmpb $0, (%ebx, %edi, 1)    # check if the current byte is \0
        je stop_counting_str_length
        # incl %eax
        incl %edi 
        jmp start_counting_str_length

    stop_counting_str_length:
        movl %edi, %eax
        movl %ebp, %esp
        popl %ebp
        ret
