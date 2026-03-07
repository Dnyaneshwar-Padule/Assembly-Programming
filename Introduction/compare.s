.section .data
	data_items:
	.long 12,43,54,23,65,13,65,78,98,72,46,0

.section .text
.globl _start

_start:
	movl $0, %edi 				# Assign starting inndex to 0
	movl data_items(, %edi, 4), %eax	# Copy the first element in the ax
	movl %eax, %ebx				# Copy the first element in the bx, as it is the greatest (initially)

	loop_start:
		cmpl $0, %eax				# Check if we reached the end of the list (array)
			je loop_exit			# if value in ax equal to  0, then exit the loop
		incl %edi				# Increment the index
		movl data_items(, %edi, 4), %eax	# Fetch the next value from the list and copy into ax
		cmpl %ebx, %eax				# compare previous greatest value with current fetched value (which is in the ax)
			jle loop_start			# if the current value is smaller than or equal to the greatest value, then fetch the next value
		movl %eax, %ebx				# else, copy the current value into the bx (as it is greatest)
		jmp loop_start				# After copying current greatest value, check next values

	loop_exit:
		movl $1, %eax
		int $0x80
