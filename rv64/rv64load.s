.section .text
.global _start
_start:
    # Open file (syscall openat)
    li a7, 56        # syscall number for openat
    li a0, -100      # AT_FDCWD (relative to current directory)
    la a1, filename  # filename
    li a2, 0         # O_RDONLY
    ecall
    bltz a0, exit1   # If open fails, exit

    mv s0, a0        # Save file descriptor

    # Get file size (syscall fstat)
    li a7, 80        # syscall fstat
    mv a0, s0        # file descriptor
    la a1, statbuf   # struct stat buffer
    ecall
    bltz a0, exit2   # If fstat fails, exit

    ld a2, 48(a1)    # Get file size (st_size at offset 48)
    beqz a2, exit    # Exit if file size is 0

    # mmap file (syscall mmap)
    li a7, 222       # syscall mmap
    li a0, 0         # addr = 0 (kernel chooses)
    mv a1, a2        # length = file size
    li a2, 7         # PROT_READ | PROT_WRITE | PROT_EXEC
    li a3, 2         # MAP_PRIVATE
    mv a4, s0        # file descriptor
    li a5, 0         # offset
    ecall
    bltz a0, exit3   # If mmap fails, exit

    mv t0, a0        # Save mmap address

    # Close file (syscall close)
    li a7, 57        # syscall close
    mv a0, s0        # file descriptor
    ecall

    # Jump to mapped file and execute it
    jalr t0            # Jump to the mapped address

    # Exit (syscall exit)
    li a7, 93        # syscall exit
    # li a0, 0         # status code (will be return value from mmap code)
    ecall

exit:
    # Exit (syscall exit)
    li a7, 93        # syscall exit
    li a0, 0         # status code
    ecall

exit1:
    # Exit (syscall exit)
    li a7, 93        # syscall exit
    li a0, 1         # status code
    ecall

exit2:
    # Exit (syscall exit)
    li a7, 93        # syscall exit
    li a0, 2         # status code
    ecall

exit3:
    # Exit (syscall exit)
    li a7, 93        # syscall exit
    li a0, 3         # status code
    ecall

.section .data
filename: .asciz "program.bin"  # File to load
statbuf:  .skip 128             # Buffer for fstat (larger than needed)
