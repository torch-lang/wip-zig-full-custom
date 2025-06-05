// const s = @import("std").builtin.Type;

pub fn formatInto(comptime T: type, buf: []u8, value: T) void {
    switch (@typeInfo(T)) {
        .int => |int| {
            if (int.signedness == .signed and int.bits <= 64) {
                // handle i64 and smaller signed integers
                const num = @as(i64, value);
                if (num < 0) {
                    buf[0] = '-';
                    const abs_num: u64 = @intCast(-num);
                    formatInto(u64, buf[1..], abs_num);
                } else {
                    return formatInto(u64, buf, @intCast(num));
                }
            } else if (int.signedness == .unsigned and int.bits <= 64) {
                // handle u64 and smaller unsigned integers
                const num = @as(u64, value);
                if (num == 0) {
                    buf[0] = '0';
                } else {
                    var digits: [20]u8 = undefined; // enough for u64 max
                    var count: usize = 0;
                    var n = num;
                    while (n > 0) {
                        digits[count] = @intCast('0' + (n % 10));
                        n /= 10;
                        count += 1;
                    }
                    // write the digits in reverse order
                    var pos: usize = 0;
                    while (count > 0) {
                        count -= 1;
                        buf[pos] = digits[count];
                        pos += 1;
                    }
                }
            } else {
                @compileError("unsupported integer type");
            }
        },
        else => @compileError("unsupported type"),
    }
}
