# This program reads records from "test.dat" stored by "write-records.s"
.include "../linux.s"
.include "record-def.s"

.section .data
    msg_firstname:
        .ascii "First Name: \0" # 12
    
    msg_lastname:
        .ascii "Last Name: \0" # 11

    msg_address:
        .ascii "Address: \0" # 9

    msg_age:
        .ascii "Age: \0" # 5

    file_name:
        .ascii "test.dat\0" 
    
.equ MSG_FIRSTNAME_LENGTH, 12
.equ MSG_LASTNAME_LENGTH, 11
.equ MSG_ADDRESS_LENGTH, 9
.equ MSG_AGE_LENGTH, 5

.section .bss 
    .lcomm record_buffer, RECORD_SIZE


.equ ST_INPUT_FILE_DESCRIPTOR, -4
.EQU ST_OUTPUT_FILE_DESCRIPTOR, -8
.section .text
.globl _start
_start:
    movl %esp, %ebp
    subl $8, %esp

    open_files:
    open_input_file:
        movl $SYS_OPEN, %eax
        movl $file_name, %ebx
        movl $O_RDONLY, %ecx
        movl $BASIC_FILE_PERMISSIONS, %edx
        int $LINUX_SYSCALL

    save_file_descriptors:
        movl %eax, ST_INPUT_FILE_DESCRIPTOR(%ebp)
        movl $STDOUT, ST_OUTPUT_FILE_DESCRIPTOR(%ebp)

    record_reading_loop:
        pushl ST_INPUT_FILE_DESCRIPTOR(%ebp)
        pushl $record_buffer
        call read_record
        addl $8, %esp

        cmpl $RECORD_SIZE, %eax
        jne finished_reading

        # Print First Name
        print_first_name:
            movl $SYS_WRITE, %eax
            movl ST_OUTPUT_FILE_DESCRIPTOR(%ebp), %ebx
            movl $msg_firstname, %ecx
            movl $MSG_FIRSTNAME_LENGTH, %edx
            int $LINUX_SYSCALL

            pushl $RECORD_FIRSTNAME + record_buffer         # the record buffer contains the entire record, and the first name starts at location 0
            call count_characters
            addl $4, %esp
            # eax contains the length of the first name

            movl %eax, %edx
            movl $SYS_WRITE, %eax
            movl ST_OUTPUT_FILE_DESCRIPTOR(%ebp), %ebx
            movl $RECORD_FIRSTNAME + record_buffer, %ecx
            int $LINUX_SYSCALL

            pushl ST_OUTPUT_FILE_DESCRIPTOR(%ebp)
            call write_new_line
            addl $4, %esp

        # Print Last Name
        print_last_name:
            movl $SYS_WRITE, %eax
            movl ST_OUTPUT_FILE_DESCRIPTOR(%ebp), %ebx
            movl $msg_lastname, %ecx
            movl $MSG_LASTNAME_LENGTH, %edx
            int $LINUX_SYSCALL

            pushl $RECORD_LASTNAME + record_buffer
            call count_characters
            addl $4, %esp

            movl %eax, %edx
            movl $SYS_WRITE, %eax
            movl ST_OUTPUT_FILE_DESCRIPTOR(%ebp), %ebx
            movl $RECORD_LASTNAME + record_buffer, %ecx
            int $LINUX_SYSCALL

            pushl ST_OUTPUT_FILE_DESCRIPTOR(%ebp)
            call write_new_line
            addl $4, %esp


        # Print Address
        print_address:
            movl $SYS_WRITE, %eax
            movl ST_OUTPUT_FILE_DESCRIPTOR(%ebp), %ebx
            movl $msg_address, %ecx
            movl $MSG_ADDRESS_LENGTH, %edx
            int $LINUX_SYSCALL

            pushl $RECORD_ADDRESS + record_buffer
            call count_characters
            addl $4, %esp

            movl %eax, %edx
            movl $SYS_WRITE, %eax
            movl ST_OUTPUT_FILE_DESCRIPTOR(%ebp), %ebx
            movl $RECORD_ADDRESS + record_buffer, %ecx
            int $LINUX_SYSCALL

            pushl ST_OUTPUT_FILE_DESCRIPTOR(%ebp)
            call write_new_line
            addl $4, %esp

        jmp record_reading_loop


        # Print Age
            # movl $SYS_WRITE, %eax
            # movl ST_OUTPUT_FILE_DESCRIPTOR(%ebp), %ebx
            # movl $msg_age, %ecx
            # movl $MSG_AGE_LENGTH, %edx
            # int $LINUX_SYSCALL

            # pushl ST_OUTPUT_FILE_DESCRIPTOR(%ebp)
            # call write_new_line
            # addl $8, %esp


    finished_reading:
        movl $SYS_EXIT, %eax
        movl $0, %ebx
        int $LINUX_SYSCALL

