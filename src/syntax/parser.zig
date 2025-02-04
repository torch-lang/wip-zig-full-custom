const std = @import("std");

const source_ = @import("../source.zig");
const lexer_ = @import("lexer.zig");
const diag = @import("../diagnostics.zig");

const Source = source_.Source;
const Offset = source_.Offset;

const Lexer = lexer_.Lexer;
const Token = lexer_.Token;
const TokenKind = lexer_.TokenKind;

// const print = @import("std").debug.print;

pub const Parser = struct {
    lexer: *Lexer,
    current_token: Token,

    state_stack_len: u8,
    state_stack: [64]ParseState,

    pub fn new(lexer: *Lexer) Parser {
        var parser = Parser{
            .lexer = lexer,
            .current_token = lexer.next(),
            .state_stack_len = 1,
            .state_stack = undefined,
        };
        parser.state_stack[0] = ParseState.global_loop;
        return parser;
    }

    pub fn next(self: *Parser) ParseNode {
        return switch (self.state_stack[self.state_stack_len - 1]) {
            ParseState.global_loop => self.handleGlobalLoop(),

            ParseState.struct_after_introducer => self.handleStructAfterIntroducer(),
            ParseState.struct_after_name => self.handleStructAfterName(),
            ParseState.struct_fields_loop => self.handleStructFieldsLoop(),

            ParseState.function_after_introducer => self.handleFunctionAfterIntroducer(),
            ParseState.function_after_name => self.handleFunctionAfterName(),
            ParseState.function_params_loop => self.handleFunctionParamsLoop(),
            ParseState.function_after_params => self.handleFunctionAfterParams(),
            ParseState.function_after_type => self.handleFunctionAfterType(),
            ParseState.function_body_loop => self.handleFunctionBodyLoop(),

            ParseState.statement => self.handleStatement(),
            ParseState.statement_end => self.handleStatementEnd(),
            ParseState.statement_expr => self.handleStatementExpr(),

            ParseState.return_after_introducer => self.handleReturnAfterIntroducer(),
            ParseState.var_after_introducer => self.handleVarAfterIntroducer(),
            ParseState.mut_after_introducer => self.handleMutAfterIntroducer(),

            ParseState.assign_opt_and_statement_end => self.handleAssignOptAndStatementEnd(),
            ParseState.assign => self.handleAssign(),

            ParseState.expression => self.handleExpression(),
            ParseState.expression_post_opt_loop => self.handleExpressionPostOptLoop(),

            ParseState.args_loop => self.handleArgsLoop(),
            ParseState.after_dot => self.handleAfterDot(),

            ParseState.type => self.handleType(),

            ParseState.binding => self.handleBinding(),
            ParseState.binding_after_name => self.handleBindingAfterName(),

            ParseState.mut_opt => self.handleMutOpt(),

            ParseState.consume_comma_or_accept_rparen => self.handleConsumeCommaOrAcceptRParen(),
            ParseState.consume_comma_or_accept_rbrace => self.handleConsumeCommaOrAcceptRBrace(),
        };
    }

    // ================================================================= //

    fn handleGlobalLoop(self: *Parser) ParseNode {
        // print("  > inside handleGlobalLoop\n", .{});
        switch (self.current_token.kind) {
            // 'struct' struct_after_introducer
            @intFromEnum(TokenKind.struct_) => {
                self.pushState(ParseState.struct_after_introducer);
                return self.makeNodeAndConsume(ParseNodeKind.struct_introducer);
            },
            // 'fn' function_after_introducer
            @intFromEnum(TokenKind.fn_) => {
                self.pushState(ParseState.function_after_introducer);
                return self.makeNodeAndConsume(ParseNodeKind.function_introducer);
            },
            // <end>
            @intFromEnum(TokenKind.end) => return self.makeNode(ParseNodeKind.end),
            else => {
                diag.expectedOneOf(self.lexer.source, self.current_token, &.{
                    @intFromEnum(TokenKind.fn_),
                    @intFromEnum(TokenKind.end),
                });
            },
        }
    }

    // ----------------------------------- //

    // <identifier> struct_after_name
    fn handleStructAfterIntroducer(self: *Parser) ParseNode {
        // print("  > inside handleStructAfterIntroducer\n", .{});
        self.popState();
        self.pushState(ParseState.struct_after_name);
        return self.makeIdentifierNodeAndConsumeToken();
    }

    // '{' struct_fields_loop
    fn handleStructAfterName(self: *Parser) ParseNode {
        // print("  > inside handleStructAfterName\n", .{});
        self.popState();
        self.pushState(ParseState.struct_fields_loop);
        self.consumeChar('{');
        return self.handleStructFieldsLoop();
    }

    // (binding ',')* '}'
    fn handleStructFieldsLoop(self: *Parser) ParseNode {
        // print("  > inside handleStructFieldsLoop\n", .{});
        if (self.current_token.kind == '}') {
            self.popState();
            return self.makeNodeAndConsume(ParseNodeKind.end); // fields end
        }

        self.pushState(ParseState.consume_comma_or_accept_rbrace);
        self.pushState(ParseState.binding);
        return self.handleBinding();
    }

    // ----------------------------------- //

    // <identifier> function_after_name
    fn handleFunctionAfterIntroducer(self: *Parser) ParseNode {
        // print("  > inside handleFunctionAfterIntroducer\n", .{});
        self.popState();
        self.pushState(ParseState.function_after_name);
        return self.makeIdentifierNodeAndConsumeToken();
    }

    // '(' function_params_loop
    fn handleFunctionAfterName(self: *Parser) ParseNode {
        // print("  > inside handleFunctionAfterName\n", .{});
        self.popState();
        self.pushState(ParseState.function_params_loop);
        self.consumeChar('(');
        return self.handleFunctionParamsLoop();
    }

    // (mut_opt binding ',')* ')' function_after_params
    fn handleFunctionParamsLoop(self: *Parser) ParseNode {
        // print("  > inside handleFunctionParamsLoop\n", .{});
        if (self.current_token.kind == ')') {
            self.popState();
            self.pushState(ParseState.function_after_params);
            return self.makeNodeAndConsume(ParseNodeKind.end); // params end
        }

        self.pushState(ParseState.consume_comma_or_accept_rparen);
        self.pushState(ParseState.binding);
        self.pushState(ParseState.mut_opt);
        return self.handleMutOpt();
    }

    // type? function_after_type
    fn handleFunctionAfterParams(self: *Parser) ParseNode {
        // print("  > inside handleFunctionAfterParams\n", .{});
        self.popState();
        self.pushState(ParseState.function_after_type);
        if (self.current_token.kind != '{') {
            self.pushState(ParseState.type);
            return self.handleType();
        } else {
            return self.handleFunctionAfterType();
        }
    }

    // '{' function_body_loop
    fn handleFunctionAfterType(self: *Parser) ParseNode {
        // print("  > inside handleFunctionAfterType\n", .{});
        self.popState();
        self.pushState(ParseState.function_body_loop);
        return self.makeNodeAndConsumeChar(ParseNodeKind.end, '{'); // function signature end
    }

    // statement* '}'
    fn handleFunctionBodyLoop(self: *Parser) ParseNode {
        // print("  > inside handleFunctionBodyLoop\n", .{});
        if (self.current_token.kind == '}') {
            self.popState();
            return self.makeNodeAndConsume(ParseNodeKind.end); // body end
        }

        self.pushState(ParseState.statement);
        return self.handleStatement();
    }

    // ----------------------------------- //
    // ----------------------------------- //
    // ----------------------------------- //

    fn handleStatement(self: *Parser) ParseNode {
        // print("  > inside handleStatement\n", .{});
        self.popState();
        switch (self.current_token.kind) {
            // 'return' return_after_introducer
            @intFromEnum(TokenKind.return_) => {
                self.pushState(ParseState.return_after_introducer);
                return self.makeNodeAndConsume(ParseNodeKind.return_introducer);
            },
            // 'var' var_after_introducer
            @intFromEnum(TokenKind.var_) => {
                self.pushState(ParseState.var_after_introducer);
                return self.makeNodeAndConsume(ParseNodeKind.var_introducer);
            },
            // 'mut' mut_after_introducer
            @intFromEnum(TokenKind.mut) => {
                self.pushState(ParseState.mut_after_introducer);
                return self.makeNodeAndConsume(ParseNodeKind.mut_introducer);
            },
            else => {
                self.pushState(ParseState.statement_expr);
                return self.handleStatementExpr();
            },
        }
    }

    // ';'
    fn handleStatementEnd(self: *Parser) ParseNode {
        // print("  > inside handleStatementEnd\n", .{});
        self.popState();
        return self.makeNodeAndConsumeChar(ParseNodeKind.end, ';'); // statement end
    }

    // expression assign_opt_and_statement_end
    fn handleStatementExpr(self: *Parser) ParseNode {
        // print("  > inside handleStatementExpr\n", .{});
        self.popState();
        self.pushState(ParseState.assign_opt_and_statement_end);
        self.pushState(ParseState.expression);
        return self.handleExpression();
    }

    // ----------------------------------- //

    // expression? statement_end
    fn handleReturnAfterIntroducer(self: *Parser) ParseNode {
        // print("  > inside handleReturnAfterIntroducer\n", .{});
        self.popState();
        self.pushState(ParseState.statement_end);
        if (self.current_token.kind != ';') {
            self.pushState(ParseState.expression);
            return self.handleExpression();
        }
        return self.handleStatementEnd();
    }

    // ----------------------------------- //

    // binding assign statement_end
    fn handleVarAfterIntroducer(self: *Parser) ParseNode {
        // print("  > inside handleVarAfterIntroducer\n", .{});
        self.popState();
        self.pushState(ParseState.statement_end);
        self.pushState(ParseState.assign);
        self.pushState(ParseState.binding);
        return self.handleBinding();
    }

    // binding assign_opt_and_statement_end
    fn handleMutAfterIntroducer(self: *Parser) ParseNode {
        // print("  > inside handleMutAfterIntroducer\n", .{});
        self.popState();
        self.pushState(ParseState.assign_opt_and_statement_end);
        self.pushState(ParseState.binding);
        return self.handleBinding();
    }

    // ----------------------------------- //

    // assign? statement_end
    fn handleAssignOptAndStatementEnd(self: *Parser) ParseNode {
        // print("  > inside handleAssignOptAndStatementEnd\n", .{});
        self.popState();
        self.pushState(ParseState.statement_end);
        if (self.current_token.kind != ';') {
            self.pushState(ParseState.assign);
            return self.handleAssign();
        }
        return self.handleStatementEnd();
    }

    // '=' expression
    fn handleAssign(self: *Parser) ParseNode {
        // print("  > inside handleAssign\n", .{});
        self.popState();
        self.consumeChar('=');
        self.pushState(ParseState.expression);
        return self.handleExpression();
    }

    // ----------------------------------- //
    // ----------------------------------- //
    // ----------------------------------- //

    fn handleExpression(self: *Parser) ParseNode {
        // print("  > inside handleExpression\n", .{});
        self.popState();
        self.pushState(ParseState.expression_post_opt_loop);
        switch (self.current_token.kind) {
            // <number>
            @intFromEnum(TokenKind.number) => return self.makeNodeAndConsume(ParseNodeKind.number),
            // <identifier>
            @intFromEnum(TokenKind.identifier) => return self.makeIdentifierNodeAndConsume(),
            // '&' mut_opt expression
            '&' => {
                self.pushState(ParseState.expression);
                self.pushState(ParseState.mut_opt);
                return self.makeNodeAndConsume(ParseNodeKind.ampersand);
            },
            else => {
                diag.expectedOneOf(self.lexer.source, self.current_token, &.{
                    @intFromEnum(TokenKind.number),
                    @intFromEnum(TokenKind.identifier),
                });
            },
        }
    }

    fn handleExpressionPostOptLoop(self: *Parser) ParseNode {
        // print("  > inside handleExpressionPostOptLoop\n", .{});
        switch (self.current_token.kind) {
            // expression '*'
            '*' => return self.makeNodeAndConsume(ParseNodeKind.star),
            // expression '('
            '(' => {
                self.pushState(ParseState.args_loop);
                return self.makeNodeAndConsume(ParseNodeKind.args_start);
            },
            // expression '.' after_dot
            '.' => {
                self.popState();
                self.pushState(ParseState.after_dot);
                return self.makeNodeAndConsume(ParseNodeKind.dot);
            },
            else => {
                self.popState();
                return self.next();
            },
        }
    }

    // (expression ',')* ')'
    fn handleArgsLoop(self: *Parser) ParseNode {
        // print("  > inside handleArgsLoop\n", .{});
        if (self.current_token.kind == ')') {
            self.popState();
            return self.makeNodeAndConsume(ParseNodeKind.end); // args end
        }

        self.pushState(ParseState.consume_comma_or_accept_rparen);
        self.pushState(ParseState.expression);
        return self.handleExpression();
    }

    // <identifier>
    fn handleAfterDot(self: *Parser) ParseNode {
        // print("  > inside handleAfterDot\n", .{});
        self.popState();
        return self.makeIdentifierNodeAndConsumeToken();
    }

    // ----------------------------------- //
    // ----------------------------------- //
    // ----------------------------------- //

    // <identifier> binding_after_name
    fn handleBinding(self: *Parser) ParseNode {
        // print("  > inside handleBinding\n", .{});
        self.popState();
        self.pushState(ParseState.binding_after_name);
        return self.makeIdentifierNodeAndConsumeToken();
    }

    // ':' type
    fn handleBindingAfterName(self: *Parser) ParseNode {
        // print("  > inside handleBindingAfterName\n", .{});
        self.popState();
        self.consumeChar(':');
        self.pushState(ParseState.type);
        return self.handleType();
    }

    fn handleType(self: *Parser) ParseNode {
        // print("  > inside handleType\n", .{});
        switch (self.current_token.kind) {
            // <identifier>
            @intFromEnum(TokenKind.identifier) => {
                self.popState();
                return self.makeNodeAndConsume(ParseNodeKind.identifier);
            },
            // '*' mut_opt type
            '*' => {
                self.pushState(ParseState.mut_opt);
                return self.makeNodeAndConsume(ParseNodeKind.star);
            },
            else => {
                diag.expectedOneOf(self.lexer.source, self.current_token, &.{
                    @intFromEnum(TokenKind.identifier),
                    '*',
                });
            },
        }
    }

    // 'mut'?
    fn handleMutOpt(self: *Parser) ParseNode {
        // print("  > inside handleMutOpt\n", .{});
        self.popState();
        if (self.current_token.kind == @intFromEnum(TokenKind.mut)) {
            return self.makeNodeAndConsume(ParseNodeKind.mut);
        }
        return self.next();
    }

    // consume ',' | accept ')'
    fn handleConsumeCommaOrAcceptRParen(self: *Parser) ParseNode {
        // print("  > inside handleConsumeCommaOrAcceptRParen\n", .{});
        self.popState();
        if (self.current_token.kind == ',') {
            self.consume();
        } else if (self.current_token.kind != ')') {
            diag.expectedOneOf(self.lexer.source, self.current_token, &.{ ',', ')' });
        }
        return self.next();
    }

    // consume ',' | accept '}'
    fn handleConsumeCommaOrAcceptRBrace(self: *Parser) ParseNode {
        // print("  > inside handleConsumeCommaOrAcceptRBrace\n", .{});
        self.popState();
        if (self.current_token.kind == ',') {
            self.consume();
        } else if (self.current_token.kind != '}') {
            diag.expectedOneOf(self.lexer.source, self.current_token, &.{ ',', '}' });
        }
        return self.next();
    }

    // ================================================================= //

    fn consume(self: *Parser) void {
        self.current_token = self.lexer.next();
    }

    fn consumeChar(self: *Parser, expected: u8) void {
        if (self.current_token.kind != expected) {
            diag.expected(self.lexer.source, self.current_token, expected);
        }
        self.consume();
    }

    fn pushState(self: *Parser, state: ParseState) void {
        if (self.state_stack_len == self.state_stack.len) {
            diag.generic(self.lexer.source, self.current_token, "parser.state_stack is full");
        }

        self.state_stack[self.state_stack_len] = state;
        self.state_stack_len += 1;
    }

    fn popState(self: *Parser) void {
        self.state_stack_len -= 1;
    }

    fn makeNode(self: *Parser, kind: ParseNodeKind) ParseNode {
        return ParseNode{ .kind = kind, .offset = self.current_token.offset };
    }

    fn makeIdentifierNode(self: *Parser) ParseNode {
        return ParseNode{
            .kind = ParseNodeKind.identifier,
            .identifier_id = self.current_token.identifier_id,
            .offset = self.current_token.offset,
        };
    }

    fn makeNodeAndConsume(self: *Parser, kind: ParseNodeKind) ParseNode {
        const node = self.makeNode(kind);
        self.consume();
        return node;
    }

    fn makeIdentifierNodeAndConsume(self: *Parser) ParseNode {
        const node = self.makeIdentifierNode();
        self.consume();
        return node;
    }

    fn makeNodeAndConsumeChar(self: *Parser, kind: ParseNodeKind, expected: u8) ParseNode {
        if (self.current_token.kind != expected) {
            diag.expected(self.lexer.source, self.current_token, expected);
        }
        return self.makeNodeAndConsume(kind);
    }

    fn makeIdentifierNodeAndConsumeChar(self: *Parser, expected: u8) ParseNode {
        if (self.current_token.kind != expected) {
            diag.expected(self.lexer.source, self.current_token, expected);
        }
        return self.makeIdentifierNodeAndConsume();
    }

    fn makeNodeAndConsumeToken(self: *Parser, kind: ParseNodeKind, expected: TokenKind) ParseNode {
        return self.makeNodeAndConsumeChar(kind, @intFromEnum(expected));
    }

    fn makeIdentifierNodeAndConsumeToken(self: *Parser) ParseNode {
        return self.makeIdentifierNodeAndConsumeChar(@intFromEnum(TokenKind.identifier));
    }
};

pub const ParseNode = struct {
    kind: ParseNodeKind,
    identifier_id: u16 = 0, // only when .kind == .identifier
    offset: Offset,
};

pub const ParseNodeKind = enum(u8) {
    end = 0,

    identifier,
    number,

    struct_introducer,
    function_introducer,
    return_introducer,
    var_introducer,
    mut_introducer,

    mut,
    dot,
    star,
    ampersand,
    args_start,
};

const ParseState = enum(u8) {
    global_loop,

    struct_after_introducer,
    struct_after_name,
    struct_fields_loop,

    function_after_introducer,
    function_after_name,
    function_params_loop,
    function_after_params,
    function_after_type,
    function_body_loop,

    statement,
    statement_end,
    statement_expr,

    return_after_introducer,
    var_after_introducer,
    mut_after_introducer,

    assign_opt_and_statement_end,
    assign,

    expression,
    expression_post_opt_loop,

    args_loop,
    after_dot,

    type,

    binding,
    binding_after_name,

    mut_opt,

    consume_comma_or_accept_rparen,
    consume_comma_or_accept_rbrace,
};
