const os = @import("os.zig");

extern const __heap_bottom: u8; // defined in link.ld

pub const PAGE_SIZE = 4096;

const max_guards = 100;
var guard_pages: [max_guards]struct { addr: usize, handler: ?fn () void } = undefined;
var guard_count: usize = 0;
var handler_set: bool = false;

const siginfo_t = extern struct {
    si_signo: i32,
    si_errno: i32,
    si_code: i32,
    _pad: [4]u8,
    si_addr: *anyopaque,
};

const sigaction_t = extern struct {
    sa_sigaction: ?fn (i32, *siginfo_t, *anyopaque) callconv(.C) void,
    sa_mask: [16]u64,
    sa_flags: i32,
    sa_restorer: ?fn () callconv(.C) void,
};

fn segfaultHandler(signum: i32, info: *siginfo_t, context: *anyopaque) callconv(.C) void {
    _ = signum;
    _ = context;
    const fault_addr = @intFromPtr(info.si_addr);
    for (0..guard_count) |i| {
        const guard = guard_pages[i];
        if (fault_addr >= guard.addr and fault_addr < guard.addr + PAGE_SIZE) {
            if (guard.handler) |h| {
                h();
            }
            return;
        }
    }
    // Default action: terminate
    _ = os.syscall1(.exit, 1);
}

pub const PageAllocator = struct {
    cursor: usize,

    const Self = @This();

    pub fn new() Self {
        return Self{ .cursor = @intFromPtr(&__heap_bottom) };
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

    pub fn allocateWithGuard(self: *Self, count: usize, handler: fn () void) [*]u8 {
        if (!handler_set) {
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
            handler_set = true;
        }

        if (guard_count >= max_guards) {
            const err_msg = "error: too many guard pages\n";
            _ = os.syscall3(.write, 2, @intFromPtr(err_msg), err_msg.len);
            _ = os.syscall1(.exit, 1);
            unreachable;
        }

        const addr = self.cursor;
        const size = count * PAGE_SIZE;
        const guard_addr = addr + size;

        // Map [addr, addr + size)
        const mmap = os.syscall6(.mmap, addr, size, 1 | 2, 2 | 32, 0xffffffffffffffff, 0);
        if (mmap != addr) {
            const err_msg = "error: mmap failed for allocation\n";
            _ = os.syscall3(.write, 2, @intFromPtr(err_msg), err_msg.len);
            _ = os.syscall1(.exit, 1);
            unreachable;
        }

        // Leave [guard_addr, guard_addr + PAGE_SIZE) unmapped
        guard_pages[guard_count] = .{ .addr = guard_addr, .handler = handler };
        guard_count += 1;

        self.cursor = guard_addr + PAGE_SIZE;
        return @ptrFromInt(addr);
    }
};
