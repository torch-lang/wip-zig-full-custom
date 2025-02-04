pub const Instruction = enum(u8) {
    blank = 0, // placeholder for removed instructions

    ret,
    ret_void,
    call,
    call_void,

    add,
};

pub const Value = u16;
pub const MAX_VALUE: u16 = 0xFFFF;

pub const Function = struct {
    return_type_size: i32,

    instructions_len: u16 = 0,
    instructions: [*]Instruction, // IR instructions

    instruction_args_len: u16 = 0,
    instruction_args: [*]Value, // instruction arguments

    value_count: u16 = 0,
    value_type_sizes: [*]i32, // size in bytes of the type of every value
    value_last_uses: [*]u16, // the offset of the last instruction that uses the value

    pub fn clear(self: *Function) void {
        self.instructions_len = 0;
        self.instruction_args_len = 0;
        self.value_count = 0;
    }
};

pub const Builder = struct {
    func: *Function,

    pub fn new(func: *Function) Builder {
        return Builder{ .func = func };
    }

    // ----------------------------------- //

    // NOTE: params must be created before any other instruction and `endParams()` must be call afterwards.

    pub fn addParam(self: *Builder, param_type_size: i32) u16 {
        const param_value = self.newValue(param_type_size);
        self.pushInstructionArg(param_value);
        return param_value;
    }

    pub fn endParams(self: *Builder) void {
        self.pushEndInstructionArg();
    }

    // ----------------------------------- //

    pub fn createRet(self: *Builder, value: Value) void {
        self.pushInstructionArg(value);
        self.pushInstruction(.ret);
    }

    pub fn createRetVoid(self: *Builder) void {
        self.pushInstruction(.ret_void);
    }

    pub fn createCall(self: *Builder, return_type_size: i32, arg_values: []const Value) Value {
        for (arg_values) |arg_value| {
            self.pushInstructionArg(arg_value);
        }
        self.pushEndInstructionArg();
        self.pushInstruction(.call);
        return self.newValue(return_type_size);
    }

    pub fn createCallVoid(self: *Builder, arg_values: []const Value) void {
        for (arg_values) |arg_value| {
            self.pushInstructionArg(arg_value);
        }
        self.pushEndInstructionArg();
        self.pushInstruction(.call_void);
    }

    // ----------------------------------- //

    pub fn createAdd(self: *Builder, lhs_value: Value, rhs_value: Value) Value {
        self.pushInstructionArg(lhs_value);
        self.pushInstructionArg(rhs_value);
        self.pushInstruction(.add);

        // `lhs` and `rhs` should have the same type
        return self.newValue(self.func.value_type_sizes[lhs_value]);
    }

    // ================================================================= //

    fn pushInstruction(self: *Builder, instr: Instruction) void {
        self.func.instructions[self.func.instructions_len] = instr;
        self.func.instructions_len += 1;
    }

    fn pushInstructionArg(self: *Builder, arg_value: Value) void {
        self.func.instruction_args[self.func.instruction_args_len] = arg_value;
        self.func.instruction_args_len += 1;

        // update last use
        self.func.value_last_uses[arg_value] = self.func.instructions_len;
    }

    fn pushEndInstructionArg(self: *Builder) void {
        self.func.instruction_args[self.func.instruction_args_len] = MAX_VALUE;
        self.func.instruction_args_len += 1;
    }

    fn newValue(self: *Builder, type_size: i32) Value {
        const value = self.func.value_count;
        self.func.value_count += 1;

        self.func.value_type_sizes[value] = type_size;
        // init last_value as its current instruction offset
        self.func.value_last_uses[value] = self.func.instructions_len;

        return value;
    }
};
