# This program reads data from STDIN, and writes it to STDOUT
# It reads max 32 bytes data at a time.

.section .data
    string_prompt_for_input: .ascii "Enter the string(0 for exit): \0"

.equ STR_PROMPT_FOR_INPUT_LENGTH, 30

### CONSTANTS ###
.equ SYS_EXIT, 1            # Exit system call
.equ SYS_READ, 3            # read system call
.equ SYS_WRITE, 4           # write system cal

.equ LINUX_SYSCALL, 0x80    # interrupt

.equ STDIN, 0               # standard input
.equ STDOUT, 1              # standard output
.equ STDERR, 2              # standard error stream (in standard output)

# The buffer section, the data which is read will be stored here.
.section .bss
.equ BUFFER_SIZE, 32
.lcomm BUFFER_DATA, BUFFER_SIZE


# Code section
.section .text
.globl _start
_start:
    movl %esp, %ebp
    movl $0, %edi

    start_read_write_loop:
        prompt_msg:
            pushl $string_prompt_for_input
            pushl $STR_PROMPT_FOR_INPUT_LENGTH
            call write_data
            addl $8, %esp
        
        start_reading:
            pushl $BUFFER_DATA          # 2nd argument
            pushl $BUFFER_SIZE          # 1st argument
            call read_data
            addl $8, %esp               # Restore stack

        # eax contains the no. of bytes read
        # cmpl $0, %eax       # If no bytes are read, stop reading (i.e writing also)
        # jle stop_read_write_loop

        # Check if the no. of bytes read is 1 and it's zero
        cmpl $2, %eax
        jg start_writing

        cmpb $'0', BUFFER_DATA(, %edi, 1) # Check if the first character is zero
        je stop_read_write_loop 

        start_writing:
            pushl $BUFFER_DATA
            pushl %eax
            call write_data
            addl $8, %esp
        jmp start_read_write_loop

    stop_read_write_loop:
        movl $SYS_EXIT, %eax
        movl $0, %ebx
        int $LINUX_SYSCALL



.type write_data, @function
# function to write data on console
# Parameters:
#       1. Buffer Length    (8)
#       2. Buffer Data      (12)
# Return:
#   no. of bytes write, (it automatically get's into eax)  
# Stack stuff
.equ ST_BUFFER, 12
.equ ST_BUFFER_LEN, 8
write_data:
    pushl %ebp          # Store old base
    movl %esp, %ebp     # Update base for current function stack

    movl $SYS_WRITE, %eax               # write system call
    movl $STDOUT, %ebx                  # File descriptor for Standard out
    movl ST_BUFFER(%ebp), %ecx     # Buffer data
    movl ST_BUFFER_LEN(%ebp), %edx      # Buffer Length
    int $LINUX_SYSCALL                  # System call

    return_from_write_data:
        movl %ebp, %esp         # Free local variables (there are not any, but convention)
        popl %ebp          # Store old base into %ebp
        ret


.type read_data, @function
# Function to read data from console
# Parameters:   
#           1. Buffer length (8)
#           2. Buffer location (12)
# Return:
#   no. of bytes read (it's automatically gets into eax)
read_data:
    pushl %ebp
    movl %esp, %ebp

    movl $SYS_READ, %eax
    movl $STDIN, %ebx
    movl ST_BUFFER(%ebp), %ecx
    movl ST_BUFFER_LEN(%ebp), %edx
    int $LINUX_SYSCALL

    return_from_read_data:
        movl %ebp, %esp
        popl %ebp
        ret
