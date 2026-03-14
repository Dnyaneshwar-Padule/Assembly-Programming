.section .data
    string:
        .ascii "Hello ! My name is %s, and I am %d years old.\n\0"
    
    name:
        .ascii "Dnyaneshwar Padule\0"

    age:
        .long 20
    
.section .text
.globl main
main:

    # Call printf
    pushl $age          # third argument
    pushl $name         # second argument
    pushl $string       # first argument
    call printf

    # call exit function
    pushl $0        # first argument
    call exit
