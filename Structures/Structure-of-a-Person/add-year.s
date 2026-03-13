# This programs reads all the records from test.dat increment the age of persons and write the records to the testout.dat file

.include "../linux.s"
.include "record-def.s"

.section .data
    input_File_name:
        .ascii "test.dat\0"

    output_file_name:
        .ascii "testout.dat\0"

    error_code:
        .ascii "0001\0"

    error_msg:
        .ascii "Can't open the file for reading !\0"
    
.section .bss
    .lcomm record_buffer, RECORD_SIZE

.section .text
.equ ST_FD_IN, -4
.equ ST_FD_OUT, -8

.globl _start
_start:
    movl %esp, %ebp
    subl $8, %esp

    open_files:
    open_input_file:
        movl $SYS_OPEN, %eax
        movl $input_File_name, %ebx
        movl $O_RDONLY, %ecx
        movl $BASIC_FILE_PERMISSIONS, %edx
        int $LINUX_SYSCALL

    # Check if the file is opened
    cmpl $0, %eax
    jge save_fd_in

    # Else exit with error
    pushl $error_msg
    pushl $error_code
    call error_exit

    save_fd_in:
        movl %eax, ST_FD_IN(%ebp)

    open_output_file:
        movl $SYS_OPEN, %eax
        movl $output_file_name, %ebx
        movl $O_CREATE_WRONLY_TRUNC, %ecx
        movl $BASIC_FILE_PERMISSIONS, %edx
        int $LINUX_SYSCALL

    save_fd_out:
        movl %eax, ST_FD_OUT(%ebp)

    start_reading_file:
        # Read file
        pushl ST_FD_IN(%ebp)
        pushl $record_buffer
        call read_record
        addl $8, %esp

        cmp $RECORD_SIZE, %eax
        jne stop_reading_file

        # Increment age
        incl record_buffer + RECORD_AGE

        # write the record
        pushl ST_FD_OUT(%ebp)
        pushl $record_buffer
        call write_record
        addl $8, %esp

        jmp start_reading_file
    
    
    stop_reading_file:
    # Close files
    movl $SYS_CLOSE, %eax
    movl ST_FD_OUT(%ebp), %ebx
    int $LINUX_SYSCALL

    movl $SYS_CLOSE, %eax
    movl ST_FD_IN(%ebp), %ebx
    int $LINUX_SYSCALL

    # EXIT
    movl $SYS_EXIT, %eax
    movl $0, %ebx
    int $LINUX_SYSCALL

