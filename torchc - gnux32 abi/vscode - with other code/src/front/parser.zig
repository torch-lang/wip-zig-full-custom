const lexer_ = @import("lexer.zig");
const Lexer = lexer_.Lexer;
const Token = lexer_.Token;

pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,

    state_stack_len: u8,
    // state_stack: [64]ParseState,

    const Self = @This();

    pub fn new(lexer: *Lexer) Self {
        const parser = Self{
            .lexer = lexer,
            .current_token = lexer.next(),
            .state_stack_len = 1,
        };

        return parser;
    }

    pub fn next(_: *Self) Node {
        // TODO: implement.
        return Node{ .kind = NodeKind.eof };
    }
};

pub const Node = struct {
    kind: NodeKind,
};

pub const NodeKind = enum(u8) {
    eof = 0,
};
