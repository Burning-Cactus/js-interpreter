const std = @import("std");
const lexer = @import("lexer.zig");

const allocator = std.heap.page_allocator;
const File = std.fs.File;
const stdout = File.stdout();
const stdin = File.stdin();


fn runInterpreter() !void {
    var running: bool = true;

    var i: usize = 0;
    while (running) {
        try print("> ");
        var buf: [64]u8 = undefined;
        const bytes = try stdin.read(&buf);

        try print("\n");

        var tokens: std.ArrayList(lexer.Token) = try lexer.scanTokens(&buf[0..bytes]);

        std.debug.print("{d}\n", .{tokens.items.len});
        for (tokens.items) |token| {
            std.debug.print("{s}\n", .{@tagName(token.type)});
        }

        tokens.deinit(allocator);

        if (i > 3) {
            running = false;
        }
        i += 1;
    }
}

// Alternate screen buffer
fn setupScreen() !void {
    try print("\x1b[?1049l\x1b[2J");
    try print("\x1b[1;1H");
}

fn tearDownScreen() !void {
    try print("\x1b[?1049h");
}

fn handleSigInt(signal: c_int) callconv(.c) void {
    tearDownScreen() catch @panic("Screen teardown failed!");
    std.debug.print("Handled interrupt signal {d}\n", .{signal});
    std.posix.exit(2);
}

fn print(bytes: []const u8) !void {
    _ = try stdout.write(bytes);
}

pub fn main() !void {
    // Setup keyboard interrupt handler
    const action: std.posix.Sigaction = .{
        .handler = .{ .handler = handleSigInt, },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(std.posix.SIG.INT, &action, null);

    try setupScreen();

    try runInterpreter();

    try tearDownScreen();
}

