const os = @import("os.zig");

extern const __heap_bottom: u8; // defined in link.ld

pub const PAGE_SIZE = 4096;

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

pub const PageAllocator = struct {
    cursor: usize,
    // pointer to a page in memory that stores an array of guard page addresses and their handler messages.
    guards: *[*]struct { addr: usize, message: []u8 },

    const Self = @This();

    pub fn new() Self {
        var act = SigAction{
            .sa_handler = &handler,
            .sa_mask = 0,
            .sa_flags = 0,
            .sa_restorer = null,
        };

        // NOTE: what happens if multiple `PageAllocator` objects are created?
        _ = os.syscall4(.rt_sigaction, 11, @intFromPtr(&act), 0, 8); // SIGSEGV
        // TODO: check result.

        const addr = @intFromPtr(&__heap_bottom);

        // PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS
        const mmap = os.syscall6(.mmap, addr, PAGE_SIZE, 1 | 2, 2 | 32, 0xffffffffffffffff, 0);
        if (mmap != addr) {
            const err_msg = "error: failed to mmap page with guards\n";
            _ = os.syscall3(.write, 2, @intFromPtr(err_msg), err_msg.len);
            _ = os.syscall1(.exit, 1);
            unreachable;
        }

        return Self{
            .cursor = addr + PAGE_SIZE * 2, // leave room for a guard page after the page that stores the guards
            .guards = @ptrFromInt(addr),
        };
    }

    pub fn reserve(self: *Self, count: usize) [*]u8 {
        const addr = self.cursor;
        self.cursor += count * PAGE_SIZE;
        return @ptrFromInt(addr);
    }

    pub fn allocate(self: *Self, count: usize) [*]u8 {
        const addr = self.cursor;

        // PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS
        const mmap = os.syscall6(.mmap, addr, count * PAGE_SIZE, 1 | 2, 2 | 32, 0xffffffffffffffff, 0);
        if (mmap != addr) {
            const err_msg = "error: mmap failed\n";
            _ = os.syscall3(.write, 2, @intFromPtr(err_msg), err_msg.len);
            _ = os.syscall1(.exit, 1);
            unreachable;
        }

        self.cursor += count * PAGE_SIZE;
        return @ptrFromInt(addr);
    }
};
