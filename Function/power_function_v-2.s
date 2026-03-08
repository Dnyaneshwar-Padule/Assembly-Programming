.section .data

.section .text
.globl _start

_start:
    pushl $3
    pushl $2
    call power
    addl $8, %esp
    pushl %eax      # Store the previous result

    pushl $2
    pushl $4
    call power
    addl $8, %esp
    pushl %eax

    pushl $2
    pushl $5
    call power
    add $8, %esp
    
                    # eax contains the result of 5^2
    popl %ebx       # Previous result in ebx
    addl %eax, %ebx
    popl %eax
    addl %eax, %ebx

    movl $1, %eax
    int $0x80

# Power Function
.type power, @function
power:
    pushl %ebp          # Push old base 
    movl %esp, %ebp     # Update the bp
    sub $4, %esp        # Get space for local variables

    movl 8(%ebp), %ebx  # Get the firsr argumenr
    movl 12(%ebp), %ecx # get the second argument 
    movl %ebx, -4(%ebp) # Put the initial result in the local storage

    power_loop_start:
        cmpl $1, %ecx
        je power_loop_exit
        movl -4(%ebp), %eax     # Get the current (old) result
        imull %ebx, %eax        # Multiply the base with current (old) result
        movl %eax, -4(%ebp)     # Store the new result
        decl %ecx               # Decrement the power by 1
        jmp power_loop_start

    power_loop_exit:
        movl -4(%ebp), %eax     # Store the return value in eax
        movl %ebp, %esp         # Free Local Storage
        popl %ebp               # Update the bp to old base
        ret
        