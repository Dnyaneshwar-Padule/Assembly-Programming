.section .data
	msg:	.ascii "Hello World !\0"

.section .text
.globl _start

_start:
	movl $4, %eax		# Write system call number
	movl $1, %ebx		# First Parameter : file descriptor for console (stdout)
	movl $msg, %ecx		# Second Parameter: The data to write
	movl $13, %edx		# Third Parameter : The length of the data
	int $0x80		# interrupt to call write system call

	movl $1, %eax		# exit system call
	movl $0, %ebx		# Parameter 1: the return status (value)
	int $0x80		# interrupt to terminate the process
