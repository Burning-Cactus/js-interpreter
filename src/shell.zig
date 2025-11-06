const std = @import("std");
const lexer = @import("lexer.zig");

const Allocator = std.mem.Allocator;
const File = std.fs.File;

const allocator = std.heap.page_allocator;
const stdout = File.stdout();
const stdin = File.stdin();

pub fn commandLine() !void {
    var shell: Shell = try init(allocator);
    defer shell.deinit();


    try print("JavaScript Interpreter\n");
    while (true) {
        try print("> ");
        var buf: [64]u8 = undefined;
        const bytes = try stdin.read(&buf);
        // Take a slice of the command without the newline terminator
        const entry = buf[0..bytes-1];

        // Split command up by spaces or newlines
        var spliterator = std.mem.splitAny(u8, entry, " ");
        const comm = spliterator.first();

        try shell.dispatch(comm, undefined);
    }

    try print("Bye!\n");
}

fn init(gpa: Allocator) !Shell {
    var shell = Shell{};
    shell.commands = std.StringHashMap(Command).init(gpa);
    try shell.commands.put("help", Command{
        .description = "Display information about all commands",
        .handler = &help,

    });
    try shell.commands.put("exit", Command{
        .description = "Exit the shell",
        .handler = &exit,
    });
    try shell.commands.put("repl", Command{
        .description = "Open JavaScript repl",
        .handler = &repl,
    });
    return shell;
}

const Shell = struct {
    commands: std.StringHashMap(Command) = undefined,

    fn dispatch(shell: *Shell, command: []const u8, args: ?[][]u8) !void {
        _ = args;
        if (shell.commands.get(command)) |exec| {
            exec.handler(shell, "");
        } else {
            try print("Unknown command. Please use the \"help\" command for all available commands.\n");
        }
    }

    fn deinit(shell: *Shell) void {
        shell.commands.deinit();
    }
};

fn print(bytes: []const u8) !void {
    _ = try stdout.write(bytes);
}

const Command = struct {
    description: []const u8,
    handler: *const fn (*Shell, []u8) void,
};

// Print a description for all available commands.
fn help(shell: *Shell, args: []u8) void {
    _ = args;
    
    var keys = shell.commands.keyIterator();

    while (keys.next()) |key| {
        if (shell.commands.get(key.*)) |command| {
            std.debug.print("\t{s} - {s}\n", .{key.*, command.description});
        }
    }

}

fn exit(shell: *Shell, args: []u8) void {
    std.posix.exit(0);
    _ = args;
    _ = shell;
}

fn repl(shell: *Shell, args: []u8) void {
    print("Javascript\n") catch {};
    runInterpreter() catch return;
    _ = args;
    _ = shell;
}

fn runInterpreter() !void {
    var running: bool = true;

    var i: usize = 0;
    while (running) {
        try print("> ");
        var buf: [64]u8 = undefined;
        const bytes = try stdin.read(&buf);

        try print("\n");

        var tokens: std.ArrayList(lexer.Token) = try lexer.scanTokens(&buf[0..bytes]);

        std.debug.print("Token count: {d}\n", .{tokens.items.len});
        for (tokens.items) |token| {
            std.debug.print("Type: {s}\nLexeme: {s}\n\n", .{
                @tagName(token.type),
                token.lexeme,
            });
        }

        tokens.deinit(allocator);

        if (i > 3) {
            running = false;
        }
        i += 1;
    }
}

