.include "../linux.s"
.include "record-def.s"
# .include "wr-rec.s"     # file which contains function to write the record

# This program write some hardcoded records into a file
# .rept is used to pad a item. 
# .rept tell the assembler to repeat the section between .rept and .endr
.section .data
    record_1:
        # First name
        .ascii "Dnyaneshwar\0"
        .rept 28      # Padding to 40 bytes
        .byte 0
        .endr

        # last name
        .ascii "Padule\0"
        .rept 33
        .byte 0
        .endr

        # address
        .ascii "Pune, Maharashtra\0" # 18
        .rept 222
        .byte 0
        .endr

        # age
        .long 20

    record_2:
        .ascii "Athrva\0"
        .rept 33
        .byte 0
        .endr

        .ascii "Gheware\0"
        .rept 32
        .byte 0
        .endr 

        .ascii "Sangli, Maharashtra\0"
        .rept 220
        .byte 0
        .endr

        .long 20

    record_3:
        .ascii "Prasad\0"
        .rept 33
        .byte 0
        .endr

        .ascii "Mandavkar\0"
        .rept 30
        .byte 0
        .endr

        .ascii "Lonere, Maharashtra\0"
        .rept 220
        .byte 0
        .endr

        .long 21

    file_name:
        .ascii "test.dat\0" # 8

    
.section .text
.equ ST_FILE_DESCRIPTOR, -4

.globl _start
_start:
    movl %esp, %ebp
    subl $4, %esp

    # Open file
    open_file:
        movl $SYS_OPEN, %eax
        movl $file_name, %ebx
        movl $O_CREATE_WRONLY_TRUNC, %ecx
        movl $BASIC_FILE_PERMISSIONS, %edx
        int $LINUX_SYSCALL

    # Store the file descriptor
    store_fd_out:
        movl %eax, ST_FILE_DESCRIPTOR(%ebp)

    write_records:
        # Write first record
        pushl ST_FILE_DESCRIPTOR(%ebp)
        pushl $record_1
        call write_record
        sub $8, %esp

        pushl ST_FILE_DESCRIPTOR(%ebp)
        pushl $record_2
        call write_record
        sub $8, %esp

        # Write third record
        pushl ST_FILE_DESCRIPTOR(%ebp)
        pushl $record_3
        call write_record
        sub $8, %esp

    
    close_file:
        movl $SYS_CLOSE, %eax
        movl ST_FILE_DESCRIPTOR(%ebp), %ebx
        int $LINUX_SYSCALL

    exit:
        movl $SYS_EXIT, %eax
        movl $0, %ebx
        int $LINUX_SYSCALL


# This is a function writes a record to a file
# Parameters
#       The buffer to write a record from
#       The File Descriptor to read a record from
# Return:
#   The status code
# .section .text
# .globl write_record

# .equ ST_WR_BUFFER, 8
# .equ ST_WR_FILE_DESCRIPTOR, 12
# .type write_record, @function

# write_record:
#     pushl %ebp
#     movl %esp, %ebp

#     pushl %ebx
    
#     movl $SYS_WRITE, %eax
#     movl ST_WR_FILE_DESCRIPTOR(%ebp), %ebx
#     movl ST_WR_BUFFER(%ebp), %ecx
#     movl $RECORD_SIZE, %edx
#     int $LINUX_SYSCALL

#     popl %ebx

#     movl %ebp, %esp
#     popl %ebp
#     ret 
    