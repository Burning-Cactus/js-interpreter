const shell = @import("shell.zig");

pub fn main() !void {
    try shell.commandLine();
}

