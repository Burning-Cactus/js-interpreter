const std = @import("std");
const allocator = std.heap.page_allocator;

const Allocator = std.mem.Allocator;
const StringHashMap = std.hash_map.StringHashMap;

// Returns a new array list which must be deallocated.
pub fn scanTokens(source: *const []u8) !std.ArrayList(Token) {
    std.debug.print("{s} {d}\n", .{source.*, source.len});
    var scanner = try Scanner.init(allocator, source);
    const tokens: std.ArrayList(Token) = try scanner.scanTokens(allocator);
    return tokens;
}

// Scanner is an object so that the data can easily be cleaned up when leaving
// the lexer code.
const Scanner = struct {
    source: *const []u8,
    tokens: std.ArrayList(Token),
    start: u32 = 0,
    current: u32 = 0,
    line: u32 = 1,

    fn init(gpa: Allocator, source: *const []u8) Allocator.Error!Scanner {
        const tokens = try std.ArrayList(Token).initCapacity(gpa, 1);
        const self = Scanner{ 
            .source = source,
            .tokens = tokens,
        };
        return self;
    }

    fn scanTokens(scanner: *Scanner, gpa: Allocator) Allocator.Error!std.ArrayList(Token) {
        var keywords = StringHashMap(TokenType).init(gpa);
        defer keywords.deinit();
        while (scanner.current < scanner.source.len) {
            scanner.scanToken(keywords);
        }
        return scanner.tokens;
    }

    fn scanToken(scanner: *Scanner, keywords: StringHashMap(TokenType)) void {
        scanner.start = scanner.current;
        const c = scanner.nextChar();
        switch (c) {
            '(' => scanner.addToken(TokenType.LEFT_PAREN),
            ')' => scanner.addToken(TokenType.RIGHT_PAREN),
            '[' => scanner.addToken(TokenType.LEFT_BRACKET),
            ']' => scanner.addToken(TokenType.RIGHT_BRACKET),
            '{' => scanner.addToken(TokenType.LEFT_BRACE),
            '}' => scanner.addToken(TokenType.RIGHT_BRACE),
            ';' => scanner.addToken(TokenType.SEMICOLON),
            ':' => scanner.addToken(TokenType.COLON),
            '=' => {
                // Assignment operator
                if (!scanner.match('=')) {
                    scanner.addToken(TokenType.EQUAL);
                }
                // Equality
                else if (!scanner.match('=')) {
                    scanner.addToken(TokenType.DOUBLE_EQUAL);
                }
                // Strict equality
                else {
                    scanner.addToken(TokenType.TRIPLE_EQUAL);
                }

            },
            '+' => scanner.addToken(TokenType.PLUS),
            '-' => scanner.addToken(TokenType.MINUS),
            ' ', '\r', '\t' => {},
            '\n' => {
                scanner.line += 1;
            },

            else => {
                while (scanner.current < scanner.source.len and isAlpha(scanner.source.*[scanner.current])) {
                    scanner.current += 1;
                }
                const literal: []u8 = scanner.source.*[scanner.start..scanner.current];
                if (keywords.get(literal)) |tokenType| {
                    scanner.addTokenLexeme(tokenType, literal);
                } else {
                    scanner.addTokenLexeme(TokenType.IDENTIFIER, literal);
                }
            },
        }
    }

    fn isAlpha(char: u8) bool {
        return (char >= 'a' and char <= 'z') or
            (char >= 'A' and char <= 'Z') or
            char == '_';
    }

    fn nextChar(scanner: *Scanner) u8 {
        const c = scanner.source.*[scanner.current];
        scanner.current += 1;
        return c;
    }

    fn match(self: *Scanner, char: u8) bool {
        if (self.current >= self.source.len) {
            return false;
        }
        if (self.source.*[self.current] != char) {
            return false;
        }
        self.current += 1;
        return true;
    }

    fn addTokenLexeme(self: *Scanner, tokType: TokenType, lexeme: []u8) void {
        const token = Token{
            .type = tokType,
            .lexeme = lexeme,
            .line = self.line,
        };
        self.tokens.append(allocator, token) catch return;
    }

    fn addToken(self: *Scanner, tokType: TokenType) void {
        const literal: []u8 = self.source.*[self.start..self.current];
        addTokenLexeme(self, tokType, literal);
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

