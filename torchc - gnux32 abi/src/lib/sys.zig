const mem = @import("mem.zig");

pub fn read(fd: u8, buf: [*]u8, count: usize) usize {
    return @intCast(syscall3(0, fd, @intFromPtr(buf), count));
}

pub fn write(fd: u8, buf: [*]const u8, count: usize) usize {
    return @intCast(syscall3(1, fd, @intFromPtr(buf), count));
}

pub fn open(path: [*:0]const u8, flags: u32, perm: u32) u8 {
    return @intCast(syscall3(2, @intFromPtr(path), flags, perm));
}

pub fn close(fd: u8) void {
    _ = syscall1(3, fd);
}

pub const Stat = extern struct {
    __pad0: [48]u8,
    size: u64,
    __pad1: [88]u8,
};

pub fn fstat(fd: u8, stat_buf: *Stat) void {
    _ = syscall2(5, fd, @intFromPtr(stat_buf));
}

pub fn mmap(addr: usize, len: usize, prot: u32, flags: u32, fd: u8, offset: usize) usize {
    return @intCast(syscall6(9, addr, len, prot, flags, fd, offset));
}

pub fn munmap(addr: [*]align(mem.PAGE_SIZE) const u8, len: usize) void {
    _ = syscall2(11, @intFromPtr(addr), len);
}

pub fn brk(addr: usize) usize {
    return @intCast(syscall1(12, addr));
}

pub const Sigaction = extern struct {
    handler: ?*const fn (i32) callconv(.C) void,
    mask: u64,
    flags: u32,
    restorer: ?*const fn () callconv(.C) void,
};

pub fn sigaction(signal: u8, act: *const Sigaction) usize {
    return @intCast(syscall4(13, signal, @intFromPtr(act), 0, 8));
}

pub fn exit(status: u8) noreturn {
    _ = syscall1(60, status);
    unreachable;
}

fn syscall1(number: u64, arg1: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
        : "rcx", "r11", "memory"
    );
}

fn syscall2(number: u64, arg1: u64, arg2: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
        : "rcx", "r11", "memory"
    );
}

fn syscall3(number: u64, arg1: u64, arg2: u64, arg3: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
        : "rcx", "r11", "memory"
    );
}

fn syscall4(number: u64, arg1: u64, arg2: u64, arg3: u64, arg4: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
          [arg4] "{r10}" (arg4),
        : "rcx", "r11", "memory"
    );
}

fn syscall6(number: u64, arg1: u64, arg2: u64, arg3: u64, arg4: u64, arg5: u64, arg6: u64) u64 {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> u64),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
          [arg4] "{r10}" (arg4),
          [arg5] "{r8}" (arg5),
          [arg6] "{r9}" (arg6),
        : "rcx", "r11", "memory"
    );
}
