const std = @import("std");

const syntax = @import("../syntax.zig");

pub fn checkAndLower(parser: *syntax.Parser, allocator: std.mem.Allocator) void {
    var lowerer = Lowerer{
        .allocator = allocator,
        .parser = parser,
        .current_node = parser.next(),
    };
    lowerer.run(allocator);
}

const Lowerer = struct {
    allocator: std.mem.Allocator,

    parser: *syntax.Parser,
    current_node: syntax.ParseNode,

    scopes_len: u8 = 0,
    scopes: [64]std.AutoArrayHashMap(u16, void) = undefined,

    pub fn run(self: *Lowerer) void {
        // global scope
        self.scopes[0] = std.AutoArrayHashMap(u16, void).init(self.allocator);
        self.scopes_len = 1;

        while (self.current_node.kind != .end) {
            self.handleGlobal();
        }
    }

    fn handleGlobal(self: *Lowerer) void {
        switch (self.current_node.kind) {
            .struct_introducer => self.handleFunction(),
            .function_introducer => self.handleFunction(),
            else => unreachable,
        }
    }

    // struct_introducer
    fn handleStruct(self: *Lowerer) void {
        self.consume(); // struct_introducer
        // const name_id = self.current_node.identifier_id;
        // TODO: scopes.
    }

    fn handleFunction(self: *Lowerer) void {
        self.consume(); // function_introducer
    }

    // ================================================================= //

    fn consume(self: *Lowerer) void {
        self.current_node = self.parser.next();
    }
};
