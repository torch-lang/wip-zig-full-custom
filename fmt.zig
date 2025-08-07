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

const Part = struct {
    start: usize,
    end: usize,
    is_placeholder: bool,
    arg_index: usize, // Only meaningful if is_placeholder is true
};

inline fn calculate_num_parts(comptime fmt: []const u8) usize {
    var count: usize = 0;
    var i: usize = 0;
    while (i < fmt.len) {
        if (fmt[i] == '%') {
            count += 1; // Count each '%' as a placeholder
            i += 1;
        } else {
            var j = i;
            while (j < fmt.len and fmt[j] != '%') {
                j += 1; // Find the next '%' or end of string
            }
            count += 1; // Count the literal segment
            i = j;
        }
    }
    return count;
}

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
            parts[idx] = Part{ .start = i, .end = j, .is_placeholder = false, .arg_index = 0 }; // Dummy value for non-placeholders
            idx += 1;
            i = j;
        }
    }
    return parts;
}

pub fn write_formatted(fd: u8, comptime fmt: []const u8, args: anytype) void {
    const parts = comptime build_parts(fmt);
    var iov: [parts.len]sys.IOVec = undefined;
    inline for (parts, 0..) |part, i| {
        if (part.is_placeholder) {
            iov[i] = sys.IOVec.fromSlice(args[part.arg_index]);
        } else {
            iov[i] = sys.IOVec.fromSlice(fmt[part.start..part.end]);
        }
    }
    _ = sys.writev(fd, &iov);
}
