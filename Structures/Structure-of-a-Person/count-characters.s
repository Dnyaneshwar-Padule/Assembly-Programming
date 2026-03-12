# This program/Function counts characters of a string

.section .text
.globl count_characters

# parameters
#   1. string location
# variables:
#   eax (al): current character
#   ecx: string length
#   edx: current character address
.equ ST_STRING_STARTING_ADDRESS, 8
count_characters:
    pushl %ebp
    movl %esp, %ebp

    movl ST_STRING_STARTING_ADDRESS(%ebp), %edx
    movl $0, %ecx

    begin_count_loop:
        movb (%edx), %al        # Get the character in al
        cmpb $0, %al            # compare the current character with 0,
        je end_count_loop       # If it's zero, then we are at the end of the string, end loop here
        incl %ecx               # Increment string count
        incl %edx               # go to next character
        jmp begin_count_loop
    
    end_count_loop:
        movl %ecx, %eax         # Return value in eax
        movl %ebp, %esp
        popl %ebp
        ret
        
