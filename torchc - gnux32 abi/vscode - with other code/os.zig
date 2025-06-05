pub const SYS = enum(u64) {
    read = 0,
    write = 1,
    open = 2,
    close = 3,
    fstat = 5,
    mmap = 9,
    munmap = 11,
    rt_sigaction = 13,
    exit = 60,
};

// pub fn syscall0(number: SYS) u64 {
//     return asm volatile ("syscall"
//         : [ret] "={rax}" (-> u64),
//         : [number] "{rax}" (@intFromEnum(number)),
//         : "rcx", "r11", "memory"
//     );
// }

pub fn syscall1(number: SYS, arg1: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (@intFromEnum(number)),
          [arg1] "{rdi}" (arg1),
        : "rcx", "r11", "memory"
    );
}

pub fn syscall2(number: SYS, arg1: u64, arg2: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (@intFromEnum(number)),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
        : "rcx", "r11", "memory"
    );
}

pub fn syscall3(number: SYS, arg1: u64, arg2: u64, arg3: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (@intFromEnum(number)),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
        : "rcx", "r11", "memory"
    );
}

pub fn syscall4(number: SYS, arg1: u64, arg2: u64, arg3: u64, arg4: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (@intFromEnum(number)),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
          [arg4] "{r10}" (arg4),
        : "rcx", "r11", "memory"
    );
}

// pub fn syscall5(number: SYS, arg1: u64, arg2: u64, arg3: u64, arg4: u64, arg5: u64) u64 {
//     return asm volatile ("syscall"
//         : [ret] "={rax}" (-> u64),
//         : [number] "{rax}" (@intFromEnum(number)),
//           [arg1] "{rdi}" (arg1),
//           [arg2] "{rsi}" (arg2),
//           [arg3] "{rdx}" (arg3),
//           [arg4] "{r10}" (arg4),
//           [arg5] "{r8}" (arg5),
//         : "rcx", "r11", "memory"
//     );
// }

pub fn syscall6(number: SYS, arg1: u64, arg2: u64, arg3: u64, arg4: u64, arg5: u64, arg6: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (@intFromEnum(number)),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
          [arg4] "{r10}" (arg4),
          [arg5] "{r8}" (arg5),
          [arg6] "{r9}" (arg6),
        : "rcx", "r11", "memory"
    );
}
