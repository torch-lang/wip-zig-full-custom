const std = @import("std");

const source_ = @import("../source.zig");

const Source = source_.Source;
const Offset = source_.Offset;

pub const Lexer = struct {
    source: *const Source,
    offset: Offset = 0,
    identifiers: std.StringArrayHashMap(void), // TODO: use custom HashSet.

    pub fn init(source: *const Source, allocator: std.mem.Allocator) Lexer {
        return Lexer{
            .source = source,
            .identifiers = std.StringArrayHashMap(void).init(allocator),
        };
    }

    pub fn deinit(self: *Lexer) void {
        self.identifiers.deinit();
    }

    pub fn next(self: *Lexer) Token {
        const text = self.source.text;

        // whitespace: [ \t]+
        while (text[self.offset] == ' ' or text[self.offset] == '\t') {
            self.offset += 1;
        }

        // comment: //[^\n]*
        if (text[self.offset] == '/' and text[self.offset + 1] == '/') {
            self.offset += 2;

            while (text[self.offset] != '\n') {
                self.offset += 1;
            }
        }

        // handle '\n'
        if (text[self.offset] == '\n') {
            self.offset += 1;

            // check EOF
            if (text.len == self.offset) {
                return Token{ .kind = @intFromEnum(TokenKind.end), .offset = self.offset - 1 };
            }

            return self.next();
        }

        // identifier: [a-zA-Z_][a-zA-Z0-9_]*
        if (Lexer.isalpha(text[self.offset]) or text[self.offset] == '_') {
            const lexeme_offset = self.offset;
            self.offset += 1;

            while (Lexer.isalnum(text[self.offset]) or text[self.offset] == '_') {
                self.offset += 1;
            }

            const lexeme = text[lexeme_offset..self.offset];

            if (std.mem.eql(u8, lexeme, "struct"))
                return Token{ .kind = @intFromEnum(TokenKind.struct_), .offset = lexeme_offset };
            if (std.mem.eql(u8, lexeme, "fn"))
                return Token{ .kind = @intFromEnum(TokenKind.fn_), .offset = lexeme_offset };
            if (std.mem.eql(u8, lexeme, "return"))
                return Token{ .kind = @intFromEnum(TokenKind.return_), .offset = lexeme_offset };
            if (std.mem.eql(u8, lexeme, "var"))
                return Token{ .kind = @intFromEnum(TokenKind.var_), .offset = lexeme_offset };
            if (std.mem.eql(u8, lexeme, "mut"))
                return Token{ .kind = @intFromEnum(TokenKind.mut), .offset = lexeme_offset };

            const res = self.identifiers.getOrPut(lexeme) catch unreachable;
            return Token{ .kind = @intFromEnum(TokenKind.identifier), .identifier_id = @intCast(res.index), .offset = lexeme_offset };
        }

        // number: [0-9]+
        if (Lexer.isdigit(text[self.offset])) {
            const lexeme_offset = self.offset;

            while (Lexer.isdigit(text[self.offset])) {
                self.offset += 1;
            }

            return Token{ .kind = @intFromEnum(TokenKind.number), .offset = lexeme_offset };
        }

        const symbol_offset = self.offset;
        self.offset += 1;

        // return the character as its ascii value
        return Token{ .kind = text[symbol_offset], .offset = symbol_offset };
    }

    pub fn isalpha(c: u8) bool {
        return (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z');
    }
    pub fn isdigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }
    pub fn isalnum(c: u8) bool {
        return isalpha(c) or isdigit(c);
    }
};

pub const Token = struct {
    kind: u8, // if > 127 TokenKind else ascii
    identifier_id: u16 = 0, // only when .kind == .identifier
    offset: Offset,
};

pub const TokenKind = enum(u8) {
    // end of file
    end = 128,

    // primary
    identifier,
    number,

    // keywords
    struct_,
    fn_,
    return_,
    var_,
    mut,

    pub fn str(kind: u8) []const u8 {
        const Static = struct {
            var c: u8 = undefined;
            const str_map = [@typeInfo(TokenKind).@"enum".fields.len][]const u8{
                "<EOF>", "<identifier>", "<number>", "struct", "fn", "return", "var", "mut",
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
