# A sinmple program, which returns exits with status code 0


# Anything written with a period aren't translated to actual instructions, instead these are special instructions to the assembler itself.
# These are called assembler directives, bcauz they are handeled by the assembler and are not actually executed by the CPU
# The .section command breaks the our program into sections.

# This command starts the data section
# Data section is used to list any memory storage we will need for data. This program doesn't need any so, it's empty.
# But we have written this for completeness. Almost every program we write has the .data section
.section .data


# The .text section contains the actual instructions which will be executed
#  .globl _start tells the assembler that this is important to remember. _start is a symbol, at it may be replaced by something else while assembly or linking
#	symbols are used to denote a address, we can use the literal address, but it will be so confusing for us to remember the memory locations.
# .globl means the assembler shouldn't discard this symbol after assembly, bcaz linker may need it.
# _start is a label (and also a symbol), which is used to tell the CPU that our program should start executing from here. (like entry point of our program)

.section .text
.globl _start
_start:			# Here we have definned the _start label, and it contains all the instructions which will be executed by the CPU
	movl $1, %eax	# we are moving 1 to the ax register, 1 in ax register referes to linux system call to exit the program.
	movl $0, %ebx	# The exit system call needs a status code as a parameter, which is kept in the bx register, so we are putting 0 in the bx register
	int $0x80	# int stands for an interrupt, when we do a system call, we need to send an interrupt to the linux kernel, so that it will perform the system call.

# In $1, the $ sign before 1, tells it is immediate addressing, if we don't use it, the assembler will think it's direct addressing mode.
# In eax or ebx, the e before the register name, tells that it is the higher segment of that register it is usually used in the 32-bit CPUs, in 64-bit CPUs we use prefix r
