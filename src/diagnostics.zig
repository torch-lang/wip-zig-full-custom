const std = @import("std");

const Source = @import("source.zig").Source;
const syntax = @import("syntax.zig");

pub fn generic(source: *const Source, token: syntax.Token, message: []const u8) noreturn {
    var stderr = std.io.getStdErr().writer();
    // TODO: line and column.
    stderr.print("{s}:{d}: {s}\n", .{
        source.path,
        token.offset,
        message,
    }) catch unreachable;
    std.process.exit(1);
}

pub fn expected(source: *const Source, token: syntax.Token, expected_: u8) noreturn {
    var stderr = std.io.getStdErr().writer();
    // TODO: line and column.
    // FIXME: need 2 different calls to `print()` because `TokenKind.str()` returns a reference to the same string if < 128.
    stderr.print("{s}:{d}: expected `{s}`", .{
        source.path,
        token.offset,
        syntax.TokenKind.str(expected_),
    }) catch unreachable;
    stderr.print(", got `{s}`\n", .{syntax.TokenKind.str(token.kind)}) catch unreachable;
    std.process.exit(1);
}

pub fn expectedOneOf(source: *const Source, token: syntax.Token, expected_: []const u8) noreturn {
    var stderr = std.io.getStdErr().writer();
    // TODO: line and column.
    stderr.print("{s}:{d}: expected one of [ ", .{ source.path, token.offset }) catch unreachable;
    for (expected_) |kind| {
        stderr.print("`{s}` ", .{syntax.TokenKind.str(kind)}) catch unreachable;
    }
    stderr.print("], got `{s}`\n", .{syntax.TokenKind.str(token.kind)}) catch unreachable;
    std.process.exit(1);
}
