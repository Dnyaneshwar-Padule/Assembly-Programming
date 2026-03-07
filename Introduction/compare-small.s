# Program to find the smallest number from list/array

.section .data
	data_items:
	.long 55,12,46,77,86,4,98,67,48,25,3,13,54

	last_index:
	.long 12

.section .text
.globl _start
_start:
	movl $0, %edi				# assign the index to 0
	movl data_items(, %edi, 4), %eax	# fetch th first value, and copy into eax
	movl %eax, %ebx				# copy the first value from eax to ebx, (as it is the smallest value we have fetched)

	# Start the loop to fetch the smallest value
	start_loop:
		cmpl last_index, %edi				# If the value is zero, it means we have reached the end of the list (array)
			je exit_loop
		incl %edi				# Increment the index by 1
		movl data_items(, %edi, 4), %eax	# fetch the next value, and copy into eax
		cmpl %ebx, %eax				# Compare the current value with the smallest value
			jge start_loop			# If the current value is greater, go the starting of the loop
		movl %eax, %ebx
		jmp start_loop

	exit_loop:
		movl $1, %eax				# linux system call to terminate the process
		int $0x80
