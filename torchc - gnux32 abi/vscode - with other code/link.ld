ENTRY(_entry)

/* Flags:
 *     4 == R
 *     5 == RX
 *     6 == RW
 */
PHDRS
{
    r  PT_LOAD FLAGS(4);
    rx PT_LOAD FLAGS(5);
    rw PT_LOAD FLAGS(6);
}

SECTIONS
{
    . = 0x100000; /* 1 MiB */

    .text : ALIGN(4096) { *(.text .text.*) } :rx

    .rodata : ALIGN(4096) { *(.rodata .rodata.*) } :r
    .data : ALIGN(4096) { *(.data .data.*) } :rw
    .bss : ALIGN(4096) { *(.bss .bss.*) } :rw

    . = ALIGN(4096);
    . += 4096; /* guard page */

    .stack (NOLOAD) : {
        . += 0x10000; /* 64 KiB of stack */
        __stack_top = .;
    } :rw

    . = ALIGN(4096);
    . += 4096; /* guard page */

    __heap_bottom = .;

    ASSERT(. <= 0x100000000, "the program needs more than 4 GiB of address space")

    /DISCARD/ : {
        *(.eh_frame_hdr)
        *(.eh_frame)
        *(.comment)
    }
}
