const os = @import("os.zig");

// const r = @import("std").os.linux.open(path: [*:0]const u8, flags: O, perm: mode_t)

export fn main() noreturn {
    const stdout = 1;
    const msg = "Hello, World!\n";

    _ = os.syscall3(.write, stdout, @intFromPtr(msg), msg.len);

    // --------------- //

    const path = "example.txt";

    // open(path, O_RDWR | O_CREAT, 0644)
    const fd = os.syscall3(.open, @intFromPtr(path), 2 | 64, 0o0644);
    const res = os.syscall3(.write, fd, @intFromPtr(msg), msg.len);
    if (res != msg.len) {
        _ = os.syscall1(.exit, res);
    }
    _ = os.syscall1(.close, fd);

    // --------------- //

    _ = os.syscall1(.exit, 0);

    unreachable;
}
