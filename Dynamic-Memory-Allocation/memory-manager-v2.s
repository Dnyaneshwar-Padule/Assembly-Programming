# Program to allocate and deallocate memory as needed

.include "linux.s"

.section .data
    heap_begin:
        .long 0

    current_break:
        .long 0


# Header Constants
.equ HEADER_SIZE, 8
.equ HDR_AVAIL_OFFSET, 0
.equ HDR_SIZE_OFFSET, 4

# Alignment
.equ ALIGNMENT, 4       # Align memory by 4 bytes

# Memory Status
.equ AVAILABLE, 0
.equ UNAVAILABLE, 1


#   allocate
#   deallocate
#   merge_free_blocks
#   split_block


.section .text

#################################
# allocate_init
#################################
.globl allocate_init
.type allocate_init, @function
allocate_init:
    pushl %ebp              # Store old base
    movl %esp, %ebp         # Update bp, for current function

    # Prepare system call to get the current program break as well as the heap beginning
    movl $SYS_BRK, %eax
    movl $0, %ebx
    int $LINUX_SYSCALL

    # eax contains the current break
    movl %eax, heap_begin
    movl %eax, current_break

    # return from function
    movl %ebp, %esp             # Free local variables, (though there aren't any)
    popl %ebp                   # restore old base
    ret

###############################
# Add padding (Function)
##############################
# Parameters:
#       1. Unaligned memory size
# Returns:
#       Aligned memory size
# Variables:
#       eax: contains the initial memory size
#       ebx: alignment
.equ ST_UNALIGNED_MEM, 8
.type add_padding, @function
add_padding:
    pushl %ebp              # Store old base
    movl %esp, %ebp         # Update base for current function

    movl ST_UNALIGNED_MEM(%ebp), %eax       # get the unalignmed memory in eax
    movl $ALIGNMENT, %ebx                   # get the alignmnet size in ebx
    decl %ebx                               # (alignment - 1)

    addl %ebx, %eax                         # (size = size + (alignment - 1))
    not %ebx                                # ~(alignment - 1)
    andl %ebx, %eax                         # (size + (alignment -1 ) ) & ( ~(alignment - 1) )

    # eax contains the return address, which is aligned memory
    movl %ebp, %esp
    popl %ebp
    ret


##############################
# allocate 
#############################
# This function gets the requested memory size, and returns the actual address of that allocated memory (not header)
# Parameters
#           1. Requested memory size
# Return
#       address of allocated memory
#       or zero on error
# Variables
#         eax: heap begin
#         ebx: current break
#         ecx: required memory size (aligned)
.equ ST_MEM_SIZE, 8
.globl allocate
.type allocate, @function
allocate:
    pushl %ebp
    movl %esp, %ebp

    movl heap_begin, %eax           # eax will hold the heap begin
    movl current_break, %ebx        # ebx will hold the current break
    movl ST_MEM_SIZE(%ebp), %ecx    # ecx holding the requested memory size

    # check is requested size is less than 1 (it's invalid)
    cmpl $0, %ecx
    jle error

    # Now, add padding to requested memory for alignment
    # but before that, save current registers
    pushl %eax
    pushl %ebx

    pushl %ecx   # pushed as parameter
    call add_padding
    addl $4, %esp  # Free parameter
    
    movl %eax, %ecx         # eax contains the alignmed siz
    # Resote registers
    popl %ebx
    popl %eax

    # now, everything is fine, start allocating the memory
    allocate_loop_begin:
        cmpl %ebx, %eax         # if, eax and ebx are equal, i.e we have reached to the current break (heap end), 
        je move_break           # so we have to extend the heap

        movl HDR_SIZE_OFFSET(%eax), %edx               # edx holding the size of the current segment
        cmpl $UNAVAILABLE, HDR_AVAIL_OFFSET(%eax)       # If the current segment is not available go to the next segment (location)
        je next_location

        # If the current block is available as well as it's big enough to fulfill the current request, then allocate at this block
        cmpl %ecx, %edx
        jge allocate_here           # if (current_size >= requested_size)

        next_location:
            addl $HEADER_SIZE, %eax
            addl %edx, %eax
            jmp allocate_loop_begin

    allocate_here:
        movl $UNAVAILABLE, HDR_AVAIL_OFFSET(%eax)       # Mark the current block as unavailable
        # Now check if the current memory can be splitted
    
    move_break:
    


    # Error, return 0
    error:
        movl $0, %eax
        pushl %ebp, %esp
        popl %ebp
        ret


####################################
# split block
###################################
# Parameters 
#           1. Address Of the Memory (Header address)
#           2. Requested Memory Size
# Variables:
#           eax: will hold the memory address
#           ebx: will hold the requested size
#           ecx: actual size
.equ ST_MEM_ADDR, 12
.equ ST_REQ_MEM_SIZE, 8
.type split_block, @function
split_block:
    pushl %ebp
    movl %esp, %ebp

    movl ST_MEM_ADDR(%ebp), %eax            # address of memory header
    movl HDR_SIZE_OFFSET(%eax), %ecx        # Actual memory size

    cmpl %ecx, ST_REQ_MEM_SIZE(%ebp)        # if (requested_size >= actual_size) return
    jge return_from_split_block

    # Get the difference in %edx
    movl %ecx, %edx
    subl ST_REQ_MEM_SIZE(%ebp), %edx

    # Now, see if we can create another empty block with that difference
    subl $HEADER_SIZE, %edx             # Should have space for header
    subl $ALIGNMENT, %edx               # Should have space for atleast single variable

    cmpl $0, %edx
    jl return_from_split_block          # if (edx < 0) return (i.e there is not enough memory for header + single_variable) 


    movl %eax, %edx
    addl $HEADER_SIZE, %edx
    addl ST_REQ_MEM_SIZE(%ebp), %edx

    # Now, edx is at the splitting pos
    movl %ecx, %ebx
    subl ST_REQ_MEM_SIZE(%ebp), %ebx        # now, ebx contains the size of remaining block, with header
    subl $HEADER_SIZE, %ebx                 # Now, ebx contains the size of remaing block, without header

    movl $AVAILABLE, HDR_SIZE_OFFSET(%edx)
    movl %ebx, HDR_SIZE_OFFSET(%edx)

    # Now, change the size of original block
    movl ST_REQ_MEM_SIZE(%ebp), HDR_SIZE_OFFSET(%eax)

    return_from_split_block:
        movl %ebp, %esp
        popl %ebp
        ret

  
