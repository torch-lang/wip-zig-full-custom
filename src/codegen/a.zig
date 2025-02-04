const std = @import("std");

const ir = @import("../../ir.zig");

// TODO: emit generic instructions and use another struct to receive that info and emit asm or binary.
pub const Rv64AsmEmitter = struct {
    func: *ir.Function,
    func_count: usize = 0,
    out: std.io.BufferedWriter(512, std.fs.File.Writer) = std.io.BufferedWriter(512, std.fs.File.Writer){ .unbuffered_writer = std.io.getStdOut().writer() },

    // NOTE: use index for registers 0..8, then name them on emit (can be x0..x6, x17, x18).
    // NOTE: how to handle ** float ** types?
    // NOTE: save types when build, like alloca -> ** associate with value **

    value_registers: [*]u5, // value -> register, set on every call to `emit()`
    register_bitmap: u32 = 1, // x0 (zero) is always "used"

    pub fn new(func: *ir.Function) !Rv64AsmEmitter {
        return Rv64AsmEmitter{
            .func = func,
            // TODO: allocate less memory.
            .value_registers = (try std.heap.page_allocator.alloc(u5, ir.MAX_VALUE - 1)).ptr,
        };
    }

    pub fn emit(self: *Rv64AsmEmitter) void {
        _ = self.out.write("<rv64 asm emitter>\n") catch unreachable;

        const func_id = self.func_count;
        self.func_count += 1;
        _ = std.fmt.format(self.out.writer(), "_F{d}:\n", .{func_id}) catch unreachable;

        var instr_count: u16 = 0;
        var instr_arg_count: u16 = 0;

        //
        //
        // TODO: correct ABI.
        //
        //

        // this reserves one register for every argument starting at x1
        while (self.func.instruction_args[instr_arg_count] != ir.MAX_VALUE) : (instr_arg_count += 1) {
            const register = instr_arg_count + 1; // skip x0

            self.register_bitmap |= @as(u32, 1) << @as(u5, @intCast(register));
            self.value_registers[instr_arg_count] = @intCast(register);
        }

        instr_arg_count += 1; // skip MAX_VALUE

        while (instr_count < self.func.instructions_len) : (instr_count += 1) {
            switch (self.func.instructions[instr_count]) {
                .blank => {}, // ignore on purpose
                .ret => {
                    const ret_value_id = self.func.instruction_args[instr_arg_count];
                    instr_arg_count += 1;
                    const ret_register = self.value_registers[ret_value_id];
                    // return value in x1
                    if (ret_register != 1) {
                        _ = std.fmt.format(self.out.writer(), "\tadd\tx1, x0, x{d}\n", .{ret_register}) catch unreachable;
                    }
                    _ = self.out.write("\tret\n") catch unreachable;
                },
                .ret_void => _ = self.out.write("\tret\n") catch unreachable,
                .call => unreachable, // TODO: implement.
                .call_void => unreachable, // TODO: implement.
                .add => {
                    // i += 1; // skip instr
                    // const lhs_value_id = func.buf[i];
                    // const lhs_value_register = self.value_registers[lhs_value_id];
                    // const lhs_free = self.func.last_uses[lhs_value_id] == i;
                    // i += 1; // skip lhs_value_id
                    // const rhs_value_id = func.buf[i];
                    // const rhs_value_register = self.value_registers[rhs_value_id];
                    // const rhs_free = self.func.last_uses[rhs_value_id] == i;

                    // const target_register: u8 =
                    //     if (lhs_free) lhs_value_register else if (rhs_free) rhs_value_register else self.findFreeRegister();

                    // self.value_registers[self.value_count] = target_register;
                    // self.value_count += 1;

                    // _ = std.fmt.format(self.out.writer(), "\tadd\tx{d}, x{d}, x{d}\n", .{
                    //     target_register,
                    //     lhs_value_register,
                    //     rhs_value_register,
                    // }) catch unreachable;
                },
            }
        }

        _ = self.out.flush() catch unreachable;
    }

    fn findFreeRegister(self: *Rv64AsmEmitter) u8 {
        if (self.register_bitmap == 0xFFFF) {
            _ = std.io.getStdErr().write("no free registers left\n") catch unreachable;
            std.process.exit(1);
        }
        return @ctz(~self.register_bitmap);
    }
};
