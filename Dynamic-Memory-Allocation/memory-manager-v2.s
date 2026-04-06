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
.equ AVAILABLE, 1
.equ UNAVAILABLE, 0


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
        jge move_break           # so we have to extend the heap

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
        pushl %eax  
        pushl %ecx          # Requested size
        call split_block
        addl $8, %esp

        addl $HEADER_SIZE, %eax
        movl %ebp, %esp
        popl %ebp
        ret

    move_break:
        movl $SYS_BRK, %eax
        addl %ecx, %ebx
        addl $HEADER_SIZE, %ebx
        int $LINUX_SYSCALL

        # eax now contains the 
        cmpl %ebx, %eax
        jl error

        movl current_break, %edx
        movl %eax, current_break

        movl %edx, %eax
        movl $UNAVAILABLE, HDR_AVAIL_OFFSET(%eax)
        movl %ecx, HDR_SIZE_OFFSET(%eax)

        addl $HEADER_SIZE, %eax

        movl %ebp, %esp
        popl %ebp
        ret


    # Error, return 0
    error:
        movl $0, %eax
        movl %ebp, %esp
        popl %ebp
        ret


###################################
# deallocate
##################################
# Parameters
#       1. The memory address (without header) to mark as free, or deallocate it
# Returns, nothing
.equ ST_MEM_ADDR_TO_DEALLOCATE, 4       # we won't push the old base
.globl deallocate
.type deallocate, @function
deallocate:
    movl ST_MEM_ADDR_TO_DEALLOCATE(%esp), %eax
    subl $HEADER_SIZE, %eax

    # Check if the location is valid
    #  If (location >= heap start && location < current_creak) then it's valid

    cmpl heap_begin, %eax
    jl return_from_deallocate

    cmpl current_break, %eax
    jge return_from_deallocate

    movl $AVAILABLE, HDR_AVAIL_OFFSET(%eax)        # mark the current memory as available

    # See, if it can be merged
    pushl %eax                      # Memory Address, with Header
    call merge_free_blocks
    popl %eax

    return_from_deallocate:
        ret

###################################
# merge_free_blocks
###################################
# Parameter: 
#           1. Address of available memory with header
# Returns, nothing
.equ ST_MRG_FR_BLOCKS_MEM_ADDR, 8
.type merge_free_blocks, @function
merge_free_blocks:
    pushl %ebp
    movl %esp, %ebp

    movl heap_begin, %eax           # We will start from the heap beginning till the memory address (to merge previous block)
    movl %eax, %ecx
    movl ST_MRG_FR_BLOCKS_MEM_ADDR(%ebp), %ebx

    start_cheking_previous_available_block:
        cmpl %eax, %ebx
        je stop_checking
        
        cmpl current_break, %eax
        jge return_from_merge_block

        movl HDR_SIZE_OFFSET(%eax), %edx
        
        go_to_next_block:
            movl %eax, %ecx    
            addl $HEADER_SIZE, %eax
            addl %edx, %eax
            jmp start_cheking_previous_available_block

    
    stop_checking:
        cmpl $UNAVAILABLE, HDR_AVAIL_OFFSET(%ecx)
        je check_next_block

        cmpl %eax, %ecx
        jge check_next_block

        # Total size of the current block
        movl HDR_SIZE_OFFSET(%ebx), %edx
        addl $HEADER_SIZE, %edx
        addl HDR_SIZE_OFFSET(%ecx), %edx

        movl %edx, HDR_SIZE_OFFSET(%ecx)    # merged previous block
        movl %ecx, %ebx

    check_next_block:
        movl %ebx, %eax
        addl $HEADER_SIZE, %eax
        addl HDR_SIZE_OFFSET(%ebx), %eax

        cmpl current_break, %eax
        jge return_from_merge_block

        cmpl $UNAVAILABLE, HDR_AVAIL_OFFSET(%eax)
        je return_from_merge_block

        movl HDR_SIZE_OFFSET(%eax), %edx
        addl $HEADER_SIZE, %edx
        addl HDR_SIZE_OFFSET(%ebx), %edx

        movl %edx, HDR_SIZE_OFFSET(%ebx)     # Merge next block


    return_from_merge_block:
        movl %ebp, %esp
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
    addl ST_REQ_MEM_SIZE(%ebp), %edx        # Now, edx is at the splitting pos
    
    movl %ecx, %ebx                         # ebx has total size of entire memory (without header)
    subl ST_REQ_MEM_SIZE(%ebp), %ebx        # now, ebx contains the size of remaining block, with header
    subl $HEADER_SIZE, %ebx                 # Now, ebx contains the size of remaing block, without header

    movl $AVAILABLE, HDR_AVAIL_OFFSET(%edx)
    movl %ebx, HDR_SIZE_OFFSET(%edx)

    # Now, change the size of original block
    movl ST_REQ_MEM_SIZE(%ebp), %ecx
    movl %ecx, HDR_SIZE_OFFSET(%eax)

    return_from_split_block:
        movl %ebp, %esp
        popl %ebp
        ret

  
