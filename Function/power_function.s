# This program will find 2^3 and 5^2 and add them which will be our return value.

.section .data
# No global data


.section .text
.globl _start

# The we will call the power function twice, and get it's result
_start:
	pushl $3	# Push second argument
	pushl $2	# Push First Argument
	call power	# Push the return address on the stack and update the instruction pointer to the called function
	addl $8, %esp	# Move the stack pointer back, (i.e. Free 3 and 2 from the stack)

	pushl %eax	# Store the current result, (%eax contains the return value)

	pushl $2
	pushl $5
	call power
	addl $8, %esp

	# Now top contains the previous result and %eax contains the current result
	popl %ebx	# Pop the previous result into %ebx
	addl %eax, %ebx	# Add the current result and previous result

	# Exit program
	movl $1, %eax
	int $0x80

# The power function
# Register Use:
#		%eax: Temperory storage
#		%ebx: Holds the base number
#		%ecx: Holds the power the base has to raise to
.type power, @function
power:
	pushl %ebp		# Store the old base
	movl %esp, %ebp		# Update the current base 
	subl $4, %esp		# Get space for local storage

	movl 8(%ebp), %ebx	# Get the first argument
	movl 12(%ebp), %ecx	# Get the second argument
	movl %ebx, -4(%ebp)	# Store the current result

	power_loop_start:
		cmpl $1, %ecx		# If the power is 1, we are done
		je power_loop_exit
		movl -4(%ebp), %eax	# Get the current result
		imull %ebx, %eax	# Multiply the base with current result, and put in %eax
		movl %eax, -4(%ebp)	# Store the current result
		decl %ecx		# decrement the power by 1
		jmp power_loop_start

	power_loop_exit:
		movl -4(%ebp), %eax	# Get the result as the return value
		movl %ebp, %esp		# Restore the stack pointer to old base, and destroy local variablespop
		popl %ebp		# Restore the base pointer to the old base (pop the top of the stack and put in the given register)
		ret			# Pop the top of the stack (which should be the return address) and store in the Instruction pointer
