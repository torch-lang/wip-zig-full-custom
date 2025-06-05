const Emitter = @import("../emitter.zig").Emitter;
const Function = @import("../../ir/function.zig").Function;

pub const PrintEmitter = struct {
    const Self = @This();

    pub fn emit(_: *Self, _: *const Function) void {
        // TODO: implement.
    }

    pub fn emitter(self: *Self) Emitter {
        return .{
            .ptr = self,
            .emitFn = emit,
        };
    }
};
