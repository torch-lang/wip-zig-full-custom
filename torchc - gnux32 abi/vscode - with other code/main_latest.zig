const os = @import("os.zig");
const mem = @import("mem.zig");

const Stat = extern struct {
    __pad0: [48]u8,
    st_size: i64,
    __pad1: [88]u8,
};

export fn main(argc: usize, argv: [*]const [*:0]const u8) noreturn {
    var act: sigaction_t = .{
        .sa_sigaction = segfaultHandler,
        .sa_mask = [16]u64{0},
        .sa_flags = os.SA_SIGINFO,
        .sa_restorer = null,
    };
    const ret = os.syscall4(.rt_sigaction, os.SIGSEGV, @intFromPtr(&act), 0, @sizeOf([16]u64));
    if (ret != 0) {
        const err_msg = "error: failed to set sigaction\n";
        _ = os.syscall3(.write, 2, @intFromPtr(err_msg), err_msg.len);
        _ = os.syscall1(.exit, 1);
        unreachable;
    }

    // -----

    for (0..argc) |i| {
        const arg = argv[i];
        var len: usize = 0;
        while (arg[len] != 0) : (len += 1) {}
        _ = os.syscall3(.write, 1, @intFromPtr(&argv[i][0]), len);
    }

    // -----

    var pa = mem.PageAllocator.new();

    var page = pa.allocate(1);
    @as(*volatile u8, &page[0]).* = '\n';
    @as(*volatile u8, &page[1]).* = 'x';
    @as(*volatile u8, &page[2]).* = '\n';

    _ = os.syscall3(.write, 1, @intFromPtr(page), 3);

    // -----

    const stdout = 1;
    const stderr = 2;

    {
        const path = "example.th";

        const fd = os.syscall3(.open, @intFromPtr(path), 0, 0); // open read-only
        if (fd == 0xfffffffffffffffe) {
            const err_msg = "error: could not open file\n";
            _ = os.syscall3(.write, stderr, @intFromPtr(err_msg), err_msg.len);
            _ = os.syscall1(.exit, 1);
            unreachable;
        }
        defer _ = os.syscall1(.close, fd);

        var stats: Stat = undefined;
        if (os.syscall2(.fstat, fd, @intFromPtr(&stats)) != 0) {
            const err_msg = "error: could not fstat file\n";
            _ = os.syscall3(.write, stderr, @intFromPtr(err_msg), err_msg.len);
            _ = os.syscall1(.exit, 1);
            unreachable;
        }

        const file_size: usize = @intCast(stats.st_size);

        const addr = pa.reserve((file_size & ~@as(usize, 4095)) / 4096);
        const mmap = os.syscall6(.mmap, @intFromPtr(addr), file_size, 1, 2, fd, 0); // PROT_READ, MAP_PRIVATE
        if (mmap != @intFromPtr(addr)) {
            const err_msg = "error: could not mmap file\n";
            _ = os.syscall3(.write, stderr, @intFromPtr(err_msg), err_msg.len);
            _ = os.syscall1(.exit, 1);
            unreachable;
        }
        defer _ = os.syscall2(.munmap, mmap, file_size);

        _ = os.syscall3(.write, stdout, mmap, file_size);
    }

    _ = os.syscall1(.exit, 0);
    unreachable;
}
