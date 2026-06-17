const std = @import("std");
const Io = std.Io;
const stdout = std.Io.File.stdout();
const stdin = std.Io.File.stdin();

const zshell = @import("zshell");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = std.heap.ArenaAllocator;
    while (true) {
        var arena = gpa.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const read_buffer: []u8 = try allocator.alloc(u8, 1000);
        const write_buffer: []u8 = try allocator.alloc(u8, 1000);

        var writer = std.Io.File.writer(stdout, io, write_buffer);
        try writer.interface.print("$: ", .{});
        try writer.interface.flush();

        var reader = std.Io.File.reader(stdin, io, read_buffer);
        const n: usize = try reader.interface.discardDelimiterExclusive('\n');
        const output = try handler(allocator, read_buffer[0..n]);
        try writer.interface.print("{s}\n", .{output});
        try writer.interface.flush();
    }
}

const BuiltinCmd = enum {
    exit,
};

pub fn handler(allocator: std.mem.Allocator, cmd: []const u8) ![]const u8 {
    const output: []u8 = try allocator.alloc(u8, cmd.len);
    const lower_cmd = std.ascii.lowerString(output, cmd);
    const cmd_enum = std.meta.stringToEnum(BuiltinCmd, lower_cmd) orelse {
        const warning_msg: []const u8 = "Unknown command";
        return warning_msg;
    };
    switch (cmd_enum) {
        .exit => std.process.exit(0),
    }
}
