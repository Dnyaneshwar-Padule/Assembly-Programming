# This program prints hello world with shared library

.section .data
    hello_world:
        .ascii "Hello World !\n\0"
    
.section .text
.globl main
.extern printf
.extern exit
main:
    pushl $hello_world
    call printf

    pushl $0
    call exit
