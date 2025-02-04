const std = @import("std");

pub const Offset = u32;

pub const SourceOpenError = error{
    TooBig,
    NoEmptyLineAtEnd,
};

pub const Source = struct {
    path: [*:0]const u8,
    text: []align(std.mem.page_size) u8,

    pub fn open(path: [*:0]const u8) !Source {
        const fd = try std.posix.openZ(path, .{}, 0);
        defer std.posix.close(fd);

        const stats = try std.posix.fstat(fd);

        const len: usize = @intCast(stats.size);

        // check file size (max 2 MiB)
        if (len > 2 * 1024 * 1024) {
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

        // check file ends with '\n'
        if (mmap[len - 1] != '\n') {
            return SourceOpenError.NoEmptyLineAtEnd;
        }

        return Source{ .path = path, .text = mmap };
    }

    pub fn close(self: Source) void {
        std.posix.munmap(self.text);
    }
};
