.equ ST_VAR_1, -4
.equ ST_VAR_2, -8
.section .text
.globl _start
_start:
    movl %esp, %ebp
    subl $8, %esp

    call allocate_init              # initialize allocator

    pushl $4                        # Parameter: requested memory size
    call allocate
    addl $4, %esp                   # free parameter
    movl %eax, ST_VAR_1(%ebp)       # Store memory address

    pushl $4                        
    call allocate
    addl $4, %esp
    movl %eax, ST_VAR_2(%ebp)

    movl ST_VAR_1(%ebp), %ebx      # get address of first memory location
    movl ST_VAR_2(%ebp), %ecx      # get address of second memory location

    movl $2, (%ebx)                # store 2 in first memory location
    movl $4, (%ecx)                # store 4 in second memory location

    movl (%ebx), %eax              
    addl (%ecx), %eax              # add both numbers

    movl %eax, %edx                # store result in edx

    pushl %ebx
    call deallocate
    addl $4, %esp

    pushl %ecx
    call deallocate
    addl $4, %esp

    movl %edx, %ebx              # return addition
    movl $1, %eax                # EXIT system call 
    int $0x80                    # interrupt

