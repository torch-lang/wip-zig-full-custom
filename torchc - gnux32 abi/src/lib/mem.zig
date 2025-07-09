const sys = @import("sys.zig");

pub const PAGE_SIZE = 4096;

pub fn copyUnsafe(dest: [*]u8, src: [*]const u8, count: usize) void {
    for (0..count) |i| {
        dest[i] = src[i];
    }
}

pub const PageAllocator = struct {
    cursor: usize,
    guard_count: usize,
    // pointer to a page in memory that stores an array of guard page addresses and their handler messages.
    // !!! NOTE: addr is NOT necessary. !!!
    guards: [*]align(PAGE_SIZE) struct { addr: usize, message: []const u8 },

    const Self = @This();

    pub fn init(self: *Self) void {
        const heap_bottom = sys.brk(0);
        self.cursor = heap_bottom;
        self.guard_count = 0;
        self.guards = @ptrFromInt(heap_bottom);

        _ = self.allocate(1); // allocate the "guards" page
        _ = self.reserve(1); // reserve 1 guard page after the "guards" page
    }

    pub fn reserve(self: *Self, count: usize) [*]align(PAGE_SIZE) u8 {
        const addr = self.cursor;
        self.cursor += count * PAGE_SIZE;
        return @ptrFromInt(addr);
    }

    pub fn allocate(self: *Self, count: usize) [*]align(PAGE_SIZE) u8 {
        const addr = self.cursor;

        // PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS
        _ = sys.mmap(addr, count * PAGE_SIZE, 1 | 2, 2 | 32, 0xFF, 0);
        // if (mmap != addr) {
        //     const err_msg = "error: mmap failed\n";
        //     _ = os.syscall3(.write, 2, @intFromPtr(err_msg), err_msg.len);
        //     _ = os.syscall1(.exit, 1);
        //     unreachable;
        // }

        self.guards[self.guard_count] = .{ .addr = addr, .message = "guard" };

        self.cursor += count * PAGE_SIZE;
        return @ptrFromInt(addr);
    }
};

// NOTE: GPA stands for "Global Page Allocator". This should be initialized in `main`.
pub var GPA: PageAllocator = undefined;
