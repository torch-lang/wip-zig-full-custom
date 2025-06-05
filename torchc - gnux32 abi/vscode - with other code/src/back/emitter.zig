const Function = @import("../ir/function.zig").Function;

pub const Emitter = struct {
    ptr: *anyopaque,
    emitFn: *const fn (ptr: *anyopaque, f: *const Function) void,

    fn emit(self: Emitter, f: *const Function) void {
        return self.emitFn(self.ptr, f);
    }
};
