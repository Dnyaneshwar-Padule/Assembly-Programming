# This file contains common linux definations

# System call numbers
.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6
.equ SYS_BRK, 45

# Interrupt
.equ LINUX_SYSCALL, 0x80

# Standard file descriptors
.equ STDIN, 0
.equ STDOUT, 1
.equ STDERR, 2

# Common status codes
.equ END_OF_FILE, 0

# File opening modes
.equ O_RDONLY, 0
.equ O_CREATE_WRONLY_TRUNC, 03101
.equ BASIC_FILE_PERMISSIONS, 0666
