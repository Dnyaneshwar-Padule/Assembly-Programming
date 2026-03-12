.include "../linux.s"
.include "record-def.s"

.section .text
.globl read_record

# This funnction reads a record from a file
# parameters
#   1. The buffer location to store the retrieved data
#   2. The File descriptor to read record from
# return
#   status code

.equ ST_RD_BUFFER, 8
.equ ST_RD_FILE_DESCRIPTOR, 12

.type read_record, @function
read_record:
    pushl %ebp
    movl %esp, %ebp

    pushl %ebx

    movl $SYS_READ, %eax
    movl ST_RD_FILE_DESCRIPTOR(%ebp), %ebx
    movl ST_RD_BUFFER(%ebp), %ecx
    movl $RECORD_SIZE, %edx
    int $LINUX_SYSCALL

    popl %ebx

    movl %ebp, %esp
    popl %ebp
    ret
