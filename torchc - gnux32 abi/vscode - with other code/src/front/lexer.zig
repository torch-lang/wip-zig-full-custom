const std = @import("std");

const Source = @import("../source.zig").Source;

pub const Lexer = struct {
    text: [*]const u8,
    length: u32,
    offset: u32 = 0,

    const Self = @This();

    // NOTE: `Source` ensures that there is a '\n' character at the end.
    pub fn new(source: *const Source) Self {
        return Self{ .text = source.data.ptr, .length = @intCast(source.data.len) };
    }

    pub fn next(self: *Self) Token {
        const source = self.text;

        // whitespace: [ \t]+
        while (source[self.offset] == ' ' or source[self.offset] == '\t') {
            self.offset += 1;
        }

        // comment: //[^\n]*
        if (source[self.offset] == '/' and source[self.offset + 1] == '/') {
            self.offset += 2;

            while (source[self.offset] != '\n') {
                self.offset += 1;
            }
        }

        // handle '\n'
        if (source[self.offset] == '\n') {
            self.offset += 1;

            // check EOF
            if (self.length == self.offset) {
                return Token{ .kind = @intFromEnum(TokenKind.eof), .offset = self.offset - 1 };
            }

            return self.next();
        }

        // identifier: [a-zA-Z_][a-zA-Z0-9_]*
        if (Self.isAlpha(source[self.offset]) or source[self.offset] == '_') {
            const lexeme_offset = self.offset;
            self.offset += 1;

            while (Self.isAlNum(source[self.offset]) or source[self.offset] == '_') {
                self.offset += 1;
            }

            const lexeme = source[lexeme_offset..self.offset];

            if (std.mem.eql(u8, lexeme, "fn"))
                return Token{ .kind = @intFromEnum(TokenKind.fn_), .offset = lexeme_offset };

            return Token{ .kind = @intFromEnum(TokenKind.identifier), .offset = lexeme_offset };
        }

        // number: [0-9]+
        if (Self.isDigit(source[self.offset])) {
            const lexeme_offset = self.offset;

            while (Self.isDigit(source[self.offset])) {
                self.offset += 1;
            }

            return Token{ .kind = @intFromEnum(TokenKind.number), .offset = lexeme_offset };
        }

        const symbol_offset = self.offset;
        self.offset += 1;

        // return the character as its ascii value
        return Token{ .kind = source[symbol_offset], .offset = symbol_offset };
    }

    pub fn isAlpha(c: u8) bool {
        return (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z');
    }
    pub fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }
    pub fn isAlNum(c: u8) bool {
        return isAlpha(c) or isDigit(c);
    }
};

pub const Token = struct {
    kind: u8, // if <= 127 then ascii, else TokenKind
    offset: u32,
};

pub const TokenKind = enum(u8) {
    eof = 128,

    // primary
    identifier,
    number,

    // keywords
    fn_,
    return_,

    pub fn str(kind: u8) []const u8 {
        const Static = struct {
            var c: u8 = undefined;
            const str_map = [@typeInfo(TokenKind).@"enum".fields.len][]const u8{
                "<EOF>", "<ident>", "<num>", "fn", "return",
            };
        };

        if (kind < 128) {
            Static.c = kind;
            return @as([*]u8, @ptrCast(&Static.c))[0..1];
        } else {
            return Static.str_map[kind - 128];
        }
    }
};
