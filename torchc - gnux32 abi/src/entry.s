.section .text

.extern main

.global _entry
_entry:
    movl (%rsp), %edi  // `argc` as first parameter to `main()`
    leal 4(%rsp), %esi // `argv` as second parameter to `main()`

    call main               // jump into zig code

    // `exit(0)` syscall
    movl $60, %eax
    movl $0, %edi
    syscall
