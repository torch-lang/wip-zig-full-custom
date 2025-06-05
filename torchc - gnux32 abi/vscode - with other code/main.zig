const os = @import("os.zig");
const mem = @import("mem.zig");

const SigAction = extern struct {
    sa_handler: ?*const fn (i32) callconv(.C) void,
    sa_mask: u64,
    sa_flags: i32,
    sa_restorer: ?*const fn () callconv(.C) void,
};

fn handler(_: i32) callconv(.C) void {
    const msg = "Handler called\n";
    _ = os.syscall3(.write, 1, @intFromPtr(msg.ptr), msg.len);
    _ = os.syscall1(.exit, 2);
}

export fn main() noreturn {
    var act = SigAction{
        .sa_handler = &handler,
        .sa_mask = 0,
        .sa_flags = 0,
        .sa_restorer = null,
    };

    _ = os.syscall4(.rt_sigaction, 11, @intFromPtr(&act), 0, 8); // SIGSEGV
    //TODO: check result.

    const ptr: *u8 = @ptrFromInt(10);
    ptr.* = 0; // trigger SIGSEGV

    // var pa = mem.PageAllocator.new();

    // var page = pa.allocate(1);
    // @as(*volatile u8, &page[0]).* = '\n';
    // @as(*volatile u8, &page[1]).* = 'x';
    // @as(*volatile u8, &page[2]).* = '\n';

    // const ptr2: *u8 = @ptrFromInt(10);
    // ptr2.* = 0; // trigger SIGSEGV

    unreachable;
}
