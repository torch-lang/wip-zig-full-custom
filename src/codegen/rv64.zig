const std = @import("std");

const ir = @import("../ir.zig");

const reg = u5;

const Rv64Registers = struct {
    const ARGS_BASE: reg = 10; // x10
    const TMPS_MAP: [7]reg = .{ 5, 6, 7, 28, 29, 30, 31 };

    tmps: u8, // bitmap for temporaries (t0-t6)

    pub fn reset(self: *Rv64Registers) void {
        self.tmps = 0b1000_0000;
    }

    pub fn allocTmp(self: *Rv64Registers) reg {
        if (self.tmps == 0xFF) {
            _ = std.io.getStdErr().write("no free registers left for temporary\n") catch unreachable;
            std.process.exit(1);
        }

        const idx = @ctz(~self.tmps);
        self.tmps |= @as(u32, 1) << idx;

        return .TMPS_MAP[idx];
    }
};

pub const Rv64BinaryEmitter = struct {
    // TODO: map/array of functions (for function calls).
    func: *ir.Function,
    out: std.io.BufferedWriter(512, std.fs.File.Writer) = std.io.BufferedWriter(512, std.fs.File.Writer){ .unbuffered_writer = std.io.getStdOut().writer() },

    regs: Rv64Registers,
    value_register_map: []reg, // value -> register

    pub fn new(func: *ir.Function) !Rv64BinaryEmitter {
        return Rv64BinaryEmitter{
            .func = func,
            .regs = Rv64Registers{ .tmps = 0 },
            // TODO: allocate less memory.
            .value_register_map = try std.heap.page_allocator.alloc(reg, ir.MAX_VALUE - 1),
        };
    }

    pub fn finish(self: *Rv64BinaryEmitter) void {
        std.heap.page_allocator.free(self.value_register_map);
        _ = self.out.flush() catch unreachable;
    }

    pub fn emit(self: *Rv64BinaryEmitter) void {
        self.regs.reset();

        // TODO: implement.

        // xori a0 (x10), a0 (x10), 19 (exit code)
        self.emitInstrTypeI(19, 10, 0b100, 10, 0b0010011);
        // addi a7 (x17), x0, 93 (exit syscall number)
        self.emitInstrTypeI(93, 0, 0b000, 17, 0b0010011);
        // ecall (perform syscall)
        _ = self.out.write(&.{ 0x73, 0x00, 0x00, 0x00 }) catch unreachable;
    }

    // ================================================================= //

    // R-type:
    //   func7[6:0] | rs2[4:0] | rs1[4:0] | func3[2:0] | rd[4:0] | opcode[6:0]
    fn emitInstrTypeR(self: *Rv64BinaryEmitter, func7: u7, rs2: u5, rs1: u5, func3: u3, rd: u5, opcode: u7) void {
        var instruction: u32 = 0;
        instruction |= @as(u32, @intCast(func7)) << 25; // func7[6:0]
        instruction |= @as(u32, @intCast(rs2)) << 20; // rs2[4:0]
        instruction |= @as(u32, @intCast(rs1)) << 15; // rs1[4:0]
        instruction |= @as(u32, @intCast(func3)) << 12; // func3[2:0]
        instruction |= @as(u32, @intCast(rd)) << 7; // rd[4:0]
        instruction |= @as(u32, @intCast(opcode)); // opcode[6:0]

        _ = self.out.writer().writeInt(u32, instruction, std.builtin.Endian.little) catch unreachable;
    }

    // I-type:
    //   imm[11:0]  | rs1[4:0] | func3[2:0] | rd[4:0] | opcode[6:0]
    fn emitInstrTypeI(self: *Rv64BinaryEmitter, imm: i12, rs1: u5, func3: u3, rd: u5, opcode: u7) void {
        var instruction: u32 = 0;
        instruction |= @as(u32, @intCast(imm)) << 20; // imm[11:0]
        instruction |= @as(u32, @intCast(rs1)) << 15; // rs1[4:0]
        instruction |= @as(u32, @intCast(func3)) << 12; // func3[2:0]
        instruction |= @as(u32, @intCast(rd)) << 7; // rd[4:0]
        instruction |= @as(u32, @intCast(opcode)); // opcode[6:0]

        _ = self.out.writer().writeInt(u32, instruction, std.builtin.Endian.little) catch unreachable;
    }

    // S-type:
    //   imm[11:5]  | rs2[4:0] | rs1[4:0] | func3[2:0] | imm[4:0] | opcode[6:0]
    fn emitInstrTypeS() void {}

    // U-type:
    //   imm[31:12] | rd[4:0] | opcode[6:0]
    fn emitInstrTypeU() void {}
};
