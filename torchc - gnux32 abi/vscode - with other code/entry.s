.section .text

.extern __stack_top // defined in link.ld
.extern main

.global _entry
_entry:
    movl (%rsp), %edi  // argc
    leal 4(%rsp), %esi // argv

    movq $__stack_top, %rsp // set the stack pointer
    call main               // call zig code

    // exit(0), just in case `main` returns.
    movl $60, %eax
    movl $0, %edi
    syscall
