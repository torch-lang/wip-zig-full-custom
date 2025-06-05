const std = @import("std");

const source_ = @import("source.zig");
const Source = source_.Source;
const SourceOpenError = source_.SourceOpenError;

const lexer_ = @import("front/lexer.zig");
const Lexer = lexer_.Lexer;
const TokenKind = lexer_.TokenKind;

const parser_ = @import("front/parser.zig");
const Parser = parser_.Parser;
const NodeKind = parser_.NodeKind;

pub fn main() !void {
    var stderr = std.io.getStdErr().writer();

    // 1. Read program arguments.
    const argv = std.os.argv;
    if (argv.len != 4 or argv[2][0] != '-' or argv[2][1] != 'o') {
        stderr.print("usage: torchc IN_FILE -o:FORMAT OUT_FILE\n", .{}) catch unreachable;
        std.process.exit(1);
    }

    const in_filepath_arg = argv[1];
    const out_format_arg = std.mem.span(argv[2]);
    const out_filepath_arg = argv[3];

    // 2. Create the `Source` from the input filepath.
    const source = Source.open(in_filepath_arg) catch |err| {
        stderr.print("{s}: {}\n", .{ in_filepath_arg, err }) catch unreachable;
        std.process.exit(1);
    };
    defer source.close();

    // 2. Create the output file from output filepath.
    var out_file = std.fs.cwd().createFileZ(out_filepath_arg, .{}) catch |err| {
        stderr.print("{s}: {}\n", .{ out_filepath_arg, err }) catch unreachable;
        std.process.exit(1);
    };
    defer out_file.close();

    // 2.1. Create a `BufferedWriter` for the output file.
    var out_buf = std.io.bufferedWriter(out_file.writer());
    defer out_buf.flush() catch unreachable;

    var w = out_buf.writer();

    // 3. Create the `Lexer` from the `Source`.
    var lexer = Lexer.new(&source);

    if (std.mem.eql(u8, out_format_arg, "-o:tok")) {
        var token = lexer.next();
        while (token.kind != 128) { // TokenKind.end
            w.print("{str}\n", .{TokenKind.str(token.kind)}) catch unreachable;
            token = lexer.next();
        }
        return; // NOTE: calling `std.process.exit(0)` here will not trigger `out_buf.flush()`.
    }

    // 4. Create the `Parser` from the `Lexer`.
    var parser = Parser.new(&lexer);

    if (std.mem.eql(u8, out_format_arg, "-o:par")) {
        var node = parser.next();
        while (node.kind != NodeKind.eof) {
            w.print("{any}\n", .{node.kind}) catch unreachable;
            node = parser.next();
        }
        return; // NOTE: calling `std.process.exit(0)` here will not trigger `out_buf.flush()`.
    }

    // NOTE: since providing an output format is mandatory, if we reach this point means the one provided didn't match any stages.
    stderr.print("error: unknown output format {s}\n", .{out_format_arg}) catch unreachable;
    std.process.exit(1);
}
