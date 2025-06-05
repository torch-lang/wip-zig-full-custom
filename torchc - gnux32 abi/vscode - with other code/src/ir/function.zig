const Instruction = @import("instruction.zig").Instruction;

pub const Function = struct {
    instructions: [256]Instruction,
};
