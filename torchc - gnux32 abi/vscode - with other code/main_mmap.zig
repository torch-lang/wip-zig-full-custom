const os = @import("os.zig");

const Stat = extern struct {
    __pad0: [48]u8,
    st_size: i64,
    __pad1: [88]u8,
};

extern const __heap_bottom: u8; // defined in link.ld

export fn main() noreturn {
    const stdout = 1;
    const msg = "Hello, World!\n";

    _ = os.syscall3(.write, stdout, @intFromPtr(msg), msg.len);

    // --------------- //

    {
        const path = "example.th";

        // 1. Open the file.
        const fd = os.syscall3(.open, @intFromPtr(path), 0, 0); // open read-only
        if (fd == 0xFFFFFFFFFFFFFFFE) {
            const err_msg = "error: could not open file\n";
            _ = os.syscall3(.write, stdout, @intFromPtr(err_msg), err_msg.len);
            _ = os.syscall1(.exit, fd);
            unreachable;
        }
        defer _ = os.syscall1(.close, fd);

        // 1. Get the file size.
        var stats: Stat = undefined;
        _ = os.syscall2(.fstat, fd, @intFromPtr(&stats));
        // TODO: check result.

        const file_size: usize = @intCast(stats.st_size);

        // PROT_READ, MAP_PRIVATE
        const mmap = os.syscall6(.mmap, @intFromPtr(&__heap_bottom), file_size, 1, 2, fd, 0);
        // TODO: check result.
        defer _ = os.syscall2(.munmap, mmap, file_size);

        _ = os.syscall3(.write, stdout, mmap, file_size);
    }

    // --------------- //

    _ = os.syscall1(.exit, 0);
    unreachable;
}
