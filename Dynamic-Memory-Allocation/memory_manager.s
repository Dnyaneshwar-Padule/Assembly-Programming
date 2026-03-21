# Program to allocate memory, allocate and deallocate as needed

# The programs using these routines will ask
# for a certain size of memory. We actually
# use more than that size, but we put it
# at the beginning, before the pointer
# we hand back. We add a size field and
# an AVAILABLE/UNAVAILABLE marker. So, the
# memory looks like this
#
# #########################################################
# #Available Marker#Size of memory#Actual memory locations#
# #########################################################
#                                  ^--Returned pointer
#                                     points here
# The pointer we return only points to the actual
# locations requested to make it easier for the
# calling program. It also allows us to change our
# structure without the calling program having to
# change at all.

.include "linux.s"      # Contains required system calls

.section .data
    heap_begin:         # Address of the heap beginning (initial Program Break)
        .long 0

    current_break:     # Store the current Program Break
        .long 0

# #### Structure Information ######
.equ HEADER_SIZE, 8             
# Location of the available flag in the header
.equ HD_AVAIL_OFFSET, 0
# Location of the size field in the header
.equ HD_SIZE_OFFSET, 4

.equ ALIGNMENT_SIZE, 4          # We will use 4 byte alignment 

# You may see the total header is of 8 bytes, the first 4 bytes hold the "available" flag, and the next 4 bytes hold the size of the required memory
# Suppose, the size of required memory is 16 bytes, so we will allocate 24 bytes in the RAM
# the 8 byte header + actual 16 bytes = total 24 bytes, which will look like this
#       Header                 Actual Memory
# |[AVAIL_FLAG:MEM_SIZE][                        ]|  
# |[0001:0016][000000000000000000000000000000000000]|  Hope, you may get it...


# Constants
.equ AVAILABLE, 1
.equ UNAVAILABLE, 0


.section .text

# allocate_init
.type allocate_init, @function
.globl allocate_init
allocate_init:
    pushl %ebp
    movl %esp, %ebp

    # get the current (initial) program break, (or the heap starting)
    movl $SYS_BRK, %eax
    movl $0, %ebx
    int $LINUX_SYSCALL      # The current break will come in %eax

    movl %eax, heap_begin          # Store heap heginning
    movl %eax, current_break       # Store the current program break

    movl %ebp, %esp     # Free Local varaibles (though, there aren't any)
    popl %ebp           # Restore the old base
    ret

# #################################
# allocate
# #################################
# PURPOSE: This function is used to grab a section of
# memory. It checks to see if there are any
# free blocks, and, if not, it asks Linux
# for a new one.
#
# PARAMETERS: This function has one parameter - the size
# of the memory block we want to allocate
#
# RETURN VALUE:
# This function returns the address of the
# allocated memory in %eax. If there is no
# memory available, it will return 0 in %eax

.equ ST_MEM_SIZE, 8             # Function Parameter
.equ ST_MEM_SIZE_WITH_PADDING, -4
.equ ST_RETURN_BLOCK_HEADER, -8
.type allocate, @function
.globl allocate
allocate:
    # Stack stuff
    pushl %ebp
    movl %esp, %ebp

    movl ST_MEM_SIZE(%ebp), %ecx    # ecx contains the size of required memory
    movl heap_begin, %eax           # eax contains the beginning of the hap
    movl current_break, %ebx        # ebx holds the location of current break              

    # Check if the requied size is valid
    cmpl $0, %ecx       # If required memory is less than or equal to zero, just do nothing.....
    jle error           

    # round the requred memory for 4 byte alignment
    pushl %eax
    pushl %ebx
    pushl %ecx

    # In division, eax contains the divident, ecx contains the divisior
    # And after division, edx contains the remainder 
    movl %ecx, %eax     # Divident in eax
    movl $0, %edx
    movl $ALIGNMENT_SIZE, %ecx
    idivl %ecx
    # now, edx contains the remainder, which we need

    # If remainder is zero, i.e no need of alignment
    cmpl $0, %edx
    jne add_padding

    # else, Padding = ALIGNMENT_SIZE - remainder, (ex. 4 - 1 = 3)
    # movl $ALIGNMENT_SIZE, %ecx
    subl %edx, %ecx
    movl %ecx, %edx

    # restore the registers (in reverse order)
    add_padding:
        popl %ecx
        popl %ebx
        popl %eax

        # To round up the required memory size, for 4 byte alignment, we will add remainder to the ecx
        # ecx contains the required memory size, so we will add the round up bytes to it
        addl %edx, %ecx 
        pushl %ecx          # we will need it later

    alloc_loop_start:
        cmpl %eax, %ebx         # If we have reached the current break, with no available memory, then ask for new memory from linux
        je move_break

        movl HD_SIZE_OFFSET(%eax), %edx             # get the size of this memory block
        cmpl $UNAVAILABLE, HD_AVAIL_OFFSET(%eax)    # If the space is Unavailable, go to the next block
        je next_location

        # Else, the current block is available,
        cmpl %edx, %ecx            # If block size >= requested size, allocate this block
        jle allocate_here

        next_location:
            # To go to the next location we have to add the header size and current block size to eax
            # next_location = HEADER_SIZE + size_of_current_block
            addl $HEADER_SIZE, %eax
            addl %edx, %eax                   # edx holds the size of current block (without header)
            jmp alloc_loop_start

    allocate_here:
        # Mark the current block as unavailable, and return the block starting
        movl $UNAVAILABLE, HD_AVAIL_OFFSET(%eax)
        pushl %eax
        jmp split_block
        # addl $HEADER_SIZE, %eax                 # eax holds the return address, now return from function
        # movl %ebp, %esp                         # Free Local Variables
        # popl %ebp                               # restore old base
        # ret  

        # Get new memory from linux
    move_break:
        # %ebx holds the current break, so add HEADER_SiZE and REQUESTED_MEM_SIZE into it
        addl $HEADER_SIZE, %ebx
        addl %ecx, %ebx             # ecx holds the required memory size

        # Store require data
        pushl %eax              # holds the last break
        pushl %ecx              # holds the required_mem_size
        pushl %ebx              # holds the new break

        movl $SYS_BRK, %eax         # SYTEM CALL for brk
        # ebx already contains the new break size
        int $LINUX_SYSCALL

        cmpl $0, %eax
        je error

        # restore saved registers
        popl %ebx
        popl %ecx
        popl %eax

        movl $UNAVAILABLE, HD_AVAIL_OFFSET(%eax)    # Set this memory as Unavailable 
        movl %ecx, HD_SIZE_OFFSET(%eax)             # The size of this memory block
        movl %ebx, current_break                    # Update the current break, as it is changed (extended)
        pushl %eax
        # addl $HEADER_SIZE, %eax                     # eax now holds the actual address of required memory, which is return value

    split_block:
        # If the current block size is much greater than requested size, then split it
        # Now, eax holds the starting of current block, (starting of header)
        # If more than or equal to HEADER_SIZE + ALIGNMENT_SIZE are wasting in current block, then split it.
        
        # let %edx hols the remaining Size
        movl HD_SIZE_OFFSET(%eax), %edx         # Total size of current block
        movl ST_MEM_SIZE_WITH_PADDING(%ebp), %ecx            # Required size
        subl %ecx, %edx                         # edx = edx - ecx

        # Now, see if we can split it
        movl $HEADER_SIZE, %ecx
        addl $ALIGNMENT_SIZE, %ecx
        cmpl %ecx, %edx
        jl return               # If, free_bytes < (HEADER_SIZE + ALIGNMENT), return

        # Else, split
        movl ST_MEM_SIZE_WITH_PADDING(%ebp), %ecx            # Get the actual required size of current block 
        movl ST_RETURN_BLOCK_HEADER(%ebp), %eax             # Get the header of the current block
        movl %ecx, HD_SIZE_OFFSET(%eax)                     # Update the size in header
        addl $HEADER_SIZE, %eax                 # move eax to starting of the current memory
        addl %ecx, %eax                         # Go to the end of current required memory, so that we can split from here

        # Now, deallocate will handel that block, with merging
        pushl %eax
        call deallocate
        addl $4, %esp               # Free parameter

    return:
        movl ST_RETURN_BLOCK_HEADER(%ebp), %eax
        addl $HEADER_SIZE, %eax
        movl %ebp, %esp
        popl %ebp
        ret

    error:
        movl $0, %eax
        movl %ebp, %esp
        popl %ebp
        ret


# #################################
# deallocate
# #################################
# This function is very simple, get the location of the memory block to free, and return, JUST IT.....;)
.equ ST_MEMORY_SEG, 4       # since, we won't push ebp, we can use 4 instead of 8, to fetch the function parameter
                            # Ofcourse, 0 is for return address....
.type deallocate, @function
.globl deallocate
deallocate:
    # get the memory segment address in %eax
    movl ST_MEMORY_SEG(%esp), %eax

    # Just make sure that the given memory address is valid
    cmpl current_break, %eax                # eax should be smaller than current_break
    jge return

    # If the given memory is smaller than heap origin Then It's also Invalid
    movl heap_begin, %ebx
    addl $HEADER_SIZE, %ebx             # First memory block starts here.

    # If first_mem_seg > requested_mem_seg, then it's invalid
    cmpl %ebx, %eax
    jl return

    # Make the memory segment as AVAILABLE
    subl $HEADER_SIZE, %eax
    movl $AVAILABLE, HD_AVAIL_OFFSET(%eax)

    # Now check, if the next block is available or free, if it is, then merge it with current block
    # edx holds the size of current block
    # ecx will hold the TOTAL SIZE of next block
    # eax will hold the current block which is being examined
    
    movl HD_SIZE_OFFSET(%eax), %edx         # get the size of current block

    # move the eax on next block
    addl $HEADER_SIZE, %eax
    addl %edx, %eax                 # Now, eax is at the end of current block, (and also at the beginning of the next block, if it exists)

    # Check if there is a block next to current block
    cmpl current_break, %eax
    jge return                    # If the current block was the last block, then there is no next block to merge 

    # Now check if next block is available
    cmpl $AVAILABLE, HD_AVAIL_OFFSET(%eax)
    jne return                              # if not available, return

    # else, (means available)
    # get the total size of the next block
    movl $HEADER_SIZE, %ecx             # Header size
    addl HD_SIZE_OFFSET(%eax), %ecx     # Total size = Header Size + memory size

    # Now, come back to the header of the current block
    subl %edx, %eax             # actual memory of current block
    subl $HEADER_SIZE, %eax     # came to the cureent block header
    
    # add the size of current block to ecx
    addl HD_SIZE_OFFSET(%eax), %ecx         # now ecx means size of current block + total size of next block
    movl %ecx, HD_SIZE_OFFSET(%eax)         # Size of current available block updated !!

    return:
        # since ebp wasn't changed and the esp points to the return address, we can just write ret
        ret



# Improvements
# 1. Alignment                          (Done.)
# 2. Block splitting 
# 3. Coalescing                         (Done.)    
# 4. Free list [Linked List]

