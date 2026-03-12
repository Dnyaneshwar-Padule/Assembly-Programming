.include "../linux.s"
.include "record-def.s"

# This is a function writes a record to a file
# Parameters
#       The buffer to write a record from
#       The File Descriptor to read a record from
# Return:
#   The status code
.section .text
.globl write_record

.equ ST_WR_BUFFER, 8
.equ ST_WR_FILE_DESCRIPTOR, 12
.type write_record, @function

write_record:
    pushl %ebp
    movl %esp, %ebp

    pushl %ebx
    
    movl $SYS_WRITE, %eax
    movl ST_WR_FILE_DESCRIPTOR(%ebp), %ebx
    movl ST_WR_BUFFER(%ebp), %ecx
    movl $RECORD_SIZE, %edx
    int $LINUX_SYSCALL

    popl %ebx

    movl %ebp, %esp
    popl %ebp
    ret

