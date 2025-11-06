const std = @import("std");
const allocator = std.heap.page_allocator;

// Returns a new array list which must be deallocated.
pub fn scanTokens(source: *const []u8) !std.ArrayList(Token) {
    std.debug.print("{s} {d}\n", .{source.*, source.len});
    const list = try std.ArrayList(Token).initCapacity(allocator, 1);
    var scanner: Scanner = .{
        .source = source,
        .tokens = list,
    };

    while (scanner.current < source.len) {
        scanner.scanToken();
    }

    return scanner.tokens;
}

// Scanner is an object so that the data can easily be cleaned up when leaving
// the lexer code.
const Scanner = struct {
    source: *const []u8,
    tokens: std.ArrayList(Token),
    start: u32 = 0,
    current: u32 = 0,
    line: u32 = 1,

    fn scanToken(self: *Scanner) void {
        self.start = self.current;
        const c = self.source.*[self.current];
        switch (c) {
            '(' => self.addToken(TokenType.LEFT_PAREN),
            ')' => self.addToken(TokenType.RIGHT_PAREN),
            '[' => self.addToken(TokenType.LEFT_BRACKET),
            ']' => self.addToken(TokenType.RIGHT_BRACKET),
            '{' => self.addToken(TokenType.LEFT_BRACE),
            '}' => self.addToken(TokenType.RIGHT_BRACE),
            ';' => self.addToken(TokenType.SEMICOLON),
            ':' => self.addToken(TokenType.COLON),
            '=' => {
                // Assignment operator
                if (!self.match('=')) {
                    self.addToken(TokenType.EQUAL);
                    return;
                }
                // Equality
                if (!self.match('=')) {
                    self.addToken(TokenType.DOUBLE_EQUAL);
                }
                // Strict equality
                else {
                    self.addToken(TokenType.TRIPLE_EQUAL);
                }

            },
            '+' => self.addToken(TokenType.PLUS),
            '-' => self.addToken(TokenType.MINUS),

            else => self.addToken(TokenType.IDENTIFIER),
        }
        self.current = self.current + 1;
    }

    fn match(self: *Scanner, char: u8) bool {
        if (self.current == self.source.len) {
            return false;
        }
        if (self.source.*[self.current] != char) {
            return false;
        }
        self.current += 1;
        return true;
    }

    fn addToken(self: *Scanner, tokType: TokenType) void {
        const literal: []u8 = self.source.*[self.start..self.current];
        const token = Token{
            .type = tokType,
            .lexeme = literal,
            .line = self.line,
        };
        self.tokens.append(allocator, token) catch return;
    }
};



pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: u32,
};

pub const TokenType = enum {
    // Single character
    LEFT_PAREN, RIGHT_PAREN,
    LEFT_BRACE, RIGHT_BRACE,
    LEFT_BRACKET, RIGHT_BRACKET,
    SEMICOLON, COLON,
    AMPERSAND, VERTICAL_LINE,
    QUESTION_MARK,

    // Operators
    COMMA, DOT,
    PLUS, MINUS,
    STAR, SLASH,
    MODULO, EQUAL,
    BANG, BANG_EQUAL,
    DOUBLE_EQUAL, TRIPLE_EQUAL,
    GREATER, GREATER_EQUAL,
    LESS, LESS_EQUAL,

    // Literals
    IDENTIFIER, STRING, NUMBER,

    // Keywords
    ASYNC, AWAIT,

    CLASS,
    THIS, SUPER,
    NEW, DELETE,

    FUNCTION,
    TYPEOF,

};

