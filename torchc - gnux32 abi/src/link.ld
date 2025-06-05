ENTRY(_entry)

SECTIONS
{
    . = 0x100000; /* 1 MiB */

    .text : ALIGN(4096) { *(.text .text.*) }

    .rodata : ALIGN(4096) { *(.rodata .rodata.*) }
    .data : ALIGN(4096) { *(.data .data.*) }
    .bss : ALIGN(4096) { *(.bss .bss.*) }

    ASSERT(. <= 0x100000000, "the program needs more than 4 GiB of address space")

    /DISCARD/ : {
        *(.eh_frame_hdr)
        *(.eh_frame)
        *(.comment)
    }
}
