const std = @import("std");

const Source = @import("source.zig").Source;
const Lexer = @import("syntax.zig").Lexer;
const Parser = @import("syntax.zig").Parser;
const semantics = @import("semantics/lower.zig");
// const ir = @import("ir.zig");
// const Rv64BinaryEmitter = @import("codegen/rv64.zig").Rv64BinaryEmitter;

pub fn main() !void {
    const argv = std.os.argv;
    if (argv.len != 2) {
        _ = try std.io.getStdErr().write("usage: torchc FILE\n");
        std.process.exit(1);
    }

    const source = try Source.open(argv[1]);
    defer source.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var lexer = Lexer.init(&source, allocator);
    defer lexer.deinit();
    var parser = Parser.new(&lexer);
    semantics.checkAndLower(&parser);

    // const pa = std.heap.page_allocator;
    // const SIZE: u16 = 4096;

    // const instructions_buf = try pa.alloc(ir.Instruction, SIZE);
    // const instruction_args_buf = try pa.alloc(ir.Value, SIZE);
    // const value_type_sizes_buf = try pa.alloc(i32, SIZE);
    // const value_last_uses_buf = try pa.alloc(u16, SIZE);
    // defer pa.free(instructions_buf);
    // defer pa.free(instruction_args_buf);
    // defer pa.free(value_type_sizes_buf);
    // defer pa.free(value_last_uses_buf);

    // var ir_func = ir.Function{
    //     .return_type_size = 4, // i32
    //     .instructions = instructions_buf.ptr,
    //     .instruction_args = instruction_args_buf.ptr,
    //     .value_type_sizes = value_type_sizes_buf.ptr,
    //     .value_last_uses = value_last_uses_buf.ptr,
    // };

    // var builder = ir.Builder.new(&ir_func);

    // {
    //     // fn add(a: i32, b: i32) i32 { return a + b; }

    //     _ = builder.addParam(4);
    //     const a = builder.addParam(4);
    //     const b = builder.addParam(4);
    //     builder.endParams();
    //     const sum = builder.createAdd(a, b);
    //     builder.createRet(sum);
    // }

    // var emitter = try Rv64BinaryEmitter.new(&ir_func);
    // defer emitter.finish();

    // const start = try std.time.Instant.now();
    // {
    //     emitter.emit();
    // }
    // const end = try std.time.Instant.now();
    // const elapsed: f64 = @floatFromInt(end.since(start));

    // // --release=fast 0.011-0.015ms
    // std.debug.print("emit() took {d:.3}ms\n", .{
    //     elapsed / std.time.ns_per_ms,
    // });
}
