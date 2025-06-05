const sys = @import("lib/sys.zig");
const mem = @import("lib/mem.zig");
const io = @import("lib/io.zig");

fn handler(_: i32) callconv(.C) void {
    const msg = "handler called\n";
    _ = sys.write(2, msg, msg.len);
    sys.exit(0);
}

export fn main(_: usize, _: [*]const [*:0]const u8) void {
    // mem.GPA.init();

    // var stdout = io.BufferedWriter.new(io.STDOUT);

    // for (0..argc) |i| {
    //     var len: usize = 0;
    //     while (argv[i][len] != 0) : (len += 1) {}

    //     stdout.write(argv[i][0..len]);
    //     stdout.write("\n");
    // }

    // stdout.flush();

    // --------------- //

    var act = sys.Sigaction{
        .handler = &handler,
        .mask = 0,
        .flags = 0,
        .restorer = null,
    };

    // TODO: HERE: there is just too many bugs with the zig compiler here....
    // 1. cannot remove "unreachable".
    // 2. cannot check for the result of the syscall because zig removes the
    //      comparison and always executes the if body WTF
    // 3. if uncoment the above code, the print arg thing, this will segfault WTF.

    _ = sys.sigaction(11, &act); // SIGSEGV
    // if (sys.sigaction(11, &act) != 0) { // SIGSEGV
    //     io.STDERR.write("error: failed to set sigaction\n");
    //     sys.exit(1);
    // }

    const ptr: *u8 = @ptrFromInt(10);
    ptr.* = 0; // trigger SIGSEGV

    unreachable;

    // const page = mem.GPA.allocate(1);
    // @as(*volatile u8, &page[4097]).* = '\n';
    // @as(*volatile u8, &page[1]).* = 'x';
    // @as(*volatile u8, &page[2]).* = '\n';

    // --------------- //

    // {
    //     var f = io.File.open("example.th", .ReadOnly) orelse {
    //         io.STDERR.write("error: failed to open file\n");
    //         sys.exit(1);
    //     };
    //     defer f.close();

    //     var stat: sys.Stat = undefined;
    //     sys.fstat(f.fd, &stat);
    //     const size: usize = @intCast(stat.size);

    //     const addr = mem.GPA.reserve((size & ~@as(usize, mem.PAGE_SIZE - 1)) / mem.PAGE_SIZE);
    //     // PROT_READ, MAP_PRIVATE
    //     const mmap: [*]align(mem.PAGE_SIZE) const u8 = @ptrFromInt(sys.mmap(@intFromPtr(addr), size, 1, 2, f.fd, 0));
    //     if (@intFromPtr(mmap) != @intFromPtr(addr)) {
    //         io.STDERR.write("error: mmap failed\n");
    //         sys.exit(1);
    //     }
    //     defer sys.munmap(mmap, size);

    //     io.STDOUT.write(mmap[0..size]);
    // }

    // io.STDOUT.write(">> done\n");
}
