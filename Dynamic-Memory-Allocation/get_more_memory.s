# This program gets more 4 bytes of memory

.include "linux.s"

.section .data
    program_break:
        .long 0


.equ ST_VARIABLE_1, -4
.equ ST_VARIABLE_2, -8
.section .text
.globl _start
_start:
    movl %esp, %ebp
    subl $8, %esp       # Get space for two local variables

    movl $SYS_BRK, %eax         # break system call
    movl $0, %ebx               # 0, to get the current program break (heap end)
    int $LINUX_SYSCALL          # eax will contain the current break

    movl %eax, program_break
    addl $4, program_break      # Add four to program break, to get more 4 bytes

    movl $SYS_BRK, %eax
    movl program_break, %ebx    
    int $LINUX_SYSCALL

    cmpl program_break, %eax
    je use_new_memory
        movl $SYS_EXIT, %eax
        movl $1, %ebx
        int $LINUX_SYSCALL

    use_new_memory:
        subl $4, %eax                   # Memory starts at new break - 4
        movl %eax, ST_VARIABLE_1(%ebp)

        movl $4, (%eax)                 # Move 4 into allocated memory
        movl $8, ST_VARIABLE_1(%ebp)    # Stored in 2nd local variable

        movl ST_VARIABLE_1(%ebp), %ecx
        addl (%eax), %ecx               # add both numbers

        movl $SYS_EXIT, %eax
        movl %ecx, %ebx
        int $LINUX_SYSCALL  

