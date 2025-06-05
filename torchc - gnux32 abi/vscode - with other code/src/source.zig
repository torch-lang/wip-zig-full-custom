const std = @import("std");

pub const SourceOpenError = error{
    Empty,
    TooBig,
    MissingEmptyLine,
};

pub const Source = struct {
    path: [*:0]const u8,
    data: []align(std.heap.page_size_min) u8,

    const Self = @This();

    pub fn open(path: [*:0]const u8) !Self {
        const fd = try std.posix.openZ(path, .{}, 0);
        defer std.posix.close(fd);

        const stats = try std.posix.fstat(fd);

        const len: usize = @intCast(stats.size);

        // check file is not empty
        if (len == 0) {
            return SourceOpenError.Empty;
        }

        // check file size (max 1 MiB)
        if (len > 1 * 1024 * 1024) {
            return SourceOpenError.TooBig;
        }

        const mmap = try std.posix.mmap(
            null,
            len,
            std.posix.PROT.READ,
            .{ .TYPE = .PRIVATE },
            fd,
            0,
        );

        // check empty line at the end
        if (mmap[len - 1] != '\n') {
            return SourceOpenError.MissingEmptyLine;
        }

        return Self{ .path = path, .data = mmap };
    }

    pub fn close(self: Self) void {
        std.posix.munmap(self.data);
    }
};
