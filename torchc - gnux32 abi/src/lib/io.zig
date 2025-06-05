const sys = @import("sys.zig");
const mem = @import("mem.zig");

pub const STDOUT = File{ .fd = 1 };
pub const STDERR = File{ .fd = 2 };

pub const FileOpenFlags = enum(u32) {
    ReadOnly = 0,
    WriteOnly = 1,
    ReadWrite = 2,
};

pub const File = struct {
    fd: u8,

    const Self = @This();

    pub fn open(path: [*:0]const u8, flags: FileOpenFlags) ?Self {
        const fd = sys.open(path, @intFromEnum(flags), 0);
        // FIXME: this does not detect EACCES (permission denied).
        if (fd == 0xFE) {
            return null;
        }
        return Self{ .fd = fd };
    }

    pub fn close(self: Self) void {
        sys.close(self.fd);
    }

    pub fn write(self: Self, buf: []const u8) void {
        var count: usize = 0;
        while (count < buf.len) {
            const written = sys.write(self.fd, buf.ptr + count, buf.len);
            // check for negative values for an `usize`
            // FIXME: if the given buffer is too big, like usize max, this will not detect an error.
            if (written > buf.len) {
                const msg = "error: could not write to file\n";
                // Best effort to print a message. Note that the result is not check because there
                // is a possibility that trying to write to stderr is what is causing the error.
                _ = sys.write(2, msg, msg.len);
                sys.exit(0xFF);
            }
            count += written;
        }
    }
};

pub const BufferedWriter = struct {
    file: File,
    pos: u16,
    buf: [mem.PAGE_SIZE - @sizeOf(File) - @sizeOf(u16)]u8,

    const Self = @This();

    pub fn new(file: File) Self {
        return Self{ .file = file, .pos = 0, .buf = undefined };
    }

    pub fn write(self: *Self, buf: []const u8) void {
        // FIXME: check if buf.len > self.buf.len
        if (self.pos + buf.len > self.buf.len) {
            self.flush();
        }
        mem.copyUnsafe(@ptrCast(&self.buf[self.pos]), buf.ptr, buf.len);
        self.pos += @intCast(buf.len);
    }

    pub fn flush(self: *Self) void {
        self.file.write(self.buf[0..self.pos]);
        self.pos = 0;
    }
};
