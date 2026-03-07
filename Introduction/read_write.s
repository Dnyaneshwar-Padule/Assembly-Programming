.section .data
buffer: .space 32	# buffer to store the input data

.section .text
.globl _start
_start:
	movl $3, %eax		# Read System Call
	movl $0, %ebx		# Read from STDIN (0)
	movl $buffer, %ecx	# The buffer
	movl $32, %edx		# The byted to read
	int $0x80		# Interrupt

	movl $4, %eax		# write system call
	movl $1, %ebx		# Write to STDOUT (1)
	movl $buffer, %ecx	# Data to write
	movl $32, %edx		# Length of Data
	int $0x80		# Interrupt

	movl $1, %eax		# exit system call
	movl $0, %ebx		# The return value
	int $0x80		# Interrupt
