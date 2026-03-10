.section .data
	err_msg: .ascii "Invalid Command Line Arguments\0" # len = 30

###### Constants ######

### SYSTEM CALLS ###
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6

## INTERRUPT ####
.equ LINUX_SYSCALL, 0x80

## FILE OPENING MODES ###
.equ O_RDONLY, 0
.equ O_CREATE_WRONLY_TRUNC, 03101

## FILE DESCRIPTORS ##
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

.equ END_OF_FILE, 0

.equ NUMBER_ARGUMENTS, 2


## FOR BUFFER
.section .bss
.equ BUFFER_SIZE, 500
.lcomm BUFFER_DATA, BUFFER_SIZE


.section .text

### STACK POSITIONS ###
.equ ST_SIZE_RESERVE, 8		# For 2 variables
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8
.equ ST_ARGC, 0
.equ ST_ARGV_0, 4
.equ ST_ARGV_1, 8
.equ ST_ARGV_2, 12

.globl _start
_start:
	movl %esp, %ebp 		# Save the stack pointer
	subl $ST_SIZE_RESERVE, %esp	# Reserve space to store file descriptors

	cmpl $3, ST_ARGC(%ebp)
	jne exit_with_1

	open_files:
	open_fd_in:
		movl $SYS_OPEN, %eax		#  Open system call
		movl ST_ARGV_1(%ebp), %ebx	# Input file name
		movl $O_RDONLY, %ecx		# Open file in read mode
		movl $0666, %edx		# file permissions
		int $LINUX_SYSCALL


	store_fd_in:
		movl %eax, ST_FD_IN(%ebp)	# Save the given file descriptor
		# movl $0, ST_FD_IN(%ebp)

	open_fd_out:
		movl $SYS_OPEN, %eax		# Open system call
		movl ST_ARGV_2(%ebp), %ebx	# Output File Name
		movl $O_CREATE_WRONLY_TRUNC, %ecx
		movl $0666, %edx
		int $LINUX_SYSCALL

	store_fd_out:
		movl %eax, ST_FD_OUT(%ebp)	# Save the given file descriptor on stack
		# movl $1, ST_FD_OUT(%ebp)

	begin_read_loop:
		# Do Read System call
		movl $SYS_READ, %eax		# Read system call
		movl ST_FD_IN(%ebp), %ebx	# Input file descriptor
		movl $BUFFER_DATA, %ecx		# Buffer location
		movl $BUFFER_SIZE, %edx		# Buffer Size
		# size of characters read, is returned into eax
		int $LINUX_SYSCALL

		# Check if we reached end of the file
		cmpl $END_OF_FILE, %eax
		jle end_loop

		continue_read_loop:
			pushl $BUFFER_DATA	# Location of buffer
			pushl %eax		# Size of characters read (buffer size)
			call convert_to_upper
			popl %eax		# Get the size back
			addl $4, %esp		# restore %esp (stack pointer)

			# Write the block to output file
			movl %eax, %edx			# Size of the buffer
			movl $SYS_WRITE, %eax		# Write system call
			movl ST_FD_OUT(%ebp), %ebx	# output file descriptor
			movl $BUFFER_DATA, %ecx		# Buffer location
			int $LINUX_SYSCALL

			jmp begin_read_loop

	end_loop:
		# Close files
		# Close output file
		movl $SYS_CLOSE, %eax
		movl ST_FD_OUT(%ebp), %ebx
		int $LINUX_SYSCALL

		# close input file
		movl $SYS_CLOSE, %eax
		movl ST_FD_IN(%ebp), %ebx
		int $LINUX_SYSCALL

		# Exit Program
		movl $SYS_EXIT, %eax
		movl $0, %ebx
		int $LINUX_SYSCALL

	exit_with_1:
		movl $SYS_WRITE, %eax
		movl $STDERR, %ebx
		movl $err_msg, %ecx
		movl $30, %edx
		int $LINUX_SYSCALL

		movl $SYS_EXIT, %eax
		movl $1, %ebx
		int $LINUX_SYSCALL


# Function to process data, (convert all letters to uppercase)
#
# PARAMETERS:
#		1. BUFFER LOCATIOn
#		2. Buffer SIZE
# VARIABLES:
#		%eax: beginning of the buffer
#		%ebx: length of the buffer
#		%edi: current buffer offset
#		%cl: current byte being processed

# Constants
.equ LOWERCASE_A, 'a'
.equ LOWERCASE_Z, 'z'
.equ UPPER_CONVERSION, 'A' - 'a'

# Stack Stuff
.equ ST_BUFFER_LEN, 8
.equ ST_BUFFER, 12

.type convert_to_upper, @function
convert_to_upper:
	pushl %ebp		# pushl Old base
	movl %esp, %ebp		# Update the current base pointer

	# Set up variables
	movl ST_BUFFER(%ebp), %eax
	movl ST_BUFFER_LEN(%ebp), %ebx
	movl $0, %edi

	# If buffer length is smaller than or equal to zero, then return
	cmpl $0, %ebx
	je end_convert_loop

	convert_loop:
		movb (%eax, %edi, 1), %cl	# Get the current byte
		cmpb $LOWERCASE_A, %cl
		jl next_byte
		cmpb $LOWERCASE_Z, %cl
		jg next_byte

		addb $UPPER_CONVERSION, %cl
		movb %cl, (%eax, %edi, 1)

		next_byte:
			incl %edi
			cmpl %edi, %ebx
			jne convert_loop

	end_convert_loop:
		movl %ebp, %esp
		popl %ebp
		ret
