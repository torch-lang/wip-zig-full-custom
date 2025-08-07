const sys = @import("sys.zig");
const panic = @import("panic.zig").panic;

// pub fn writev(fd: u8, parts: anytype) void {
//     const T = @TypeOf(parts);
//     if (@typeInfo(T) != .@"struct" or !@typeInfo(T).@"struct".is_tuple) {
//         @compileError("expected []const u8 or literal string");
//     }

//     var iov: [@typeInfo(T).@"struct".fields.len]sys.IOVec = undefined;
//     var total_len: usize = 0;
//     inline for (parts, 0..) |part, i| {
//         iov[i] = sys.IOVec.fromSlice(part);
//         total_len += part.len;
//     }

//     var count: usize = 0;
//     while (count < total_len) {
//         const written = sys.writev(fd, &iov);
//         // check for any errors
//         if (written == 0 or written > total_len) {
//             panic("error when trying to write to file");
//         }
//         count += written;
//     }
// }

pub fn fprint(fd: u8, comptime fmt: []const u8, args: anytype) void {
    const parts = comptime build_parts(fmt);
    var total_len: usize = 0;
    var iov: [parts.len]sys.IOVec = undefined;
    inline for (parts, 0..) |part, i| {
        if (part.is_placeholder) {
            const arg = args[part.arg_index];
            iov[i] = sys.IOVec.fromSlice(arg);
            total_len += arg.len;
        } else {
            iov[i] = sys.IOVec.fromSlice(fmt[part.start..part.end]);
            total_len += part.end - part.start;
        }
    }
    const written = sys.writev(fd, &iov);
    if (written == 0 or written > total_len) {
        panic("error when trying to write to file");
    }
}

const Part = struct {
    start: usize,
    end: usize,
    is_placeholder: bool,
    arg_index: usize, // only if `is_placeholder` is true
};

inline fn build_parts(comptime fmt: []const u8) [calculate_num_parts(fmt)]Part {
    var parts: [calculate_num_parts(fmt)]Part = undefined;
    var idx: usize = 0;
    var arg_idx: usize = 0;
    var i: usize = 0;
    while (i < fmt.len) {
        if (fmt[i] == '%') {
            parts[idx] = Part{ .start = i, .end = i + 1, .is_placeholder = true, .arg_index = arg_idx };
            idx += 1;
            arg_idx += 1;
            i += 1;
        } else {
            var j = i;
            while (j < fmt.len and fmt[j] != '%') {
                j += 1;
            }
            parts[idx] = Part{ .start = i, .end = j, .is_placeholder = false, .arg_index = 0 };
            idx += 1;
            i = j;
        }
    }
    return parts;
}

inline fn calculate_num_parts(comptime fmt: []const u8) usize {
    var part_count: usize = 0;
    var i: usize = 0;
    while (i < fmt.len) {
        if (fmt[i] == '%') {
            part_count += 1;
            i += 1;
        } else {
            var j = i;
            while (j < fmt.len and fmt[j] != '%') {
                j += 1;
            }
            part_count += 1;
            i = j;
        }
    }
    return part_count;
}
