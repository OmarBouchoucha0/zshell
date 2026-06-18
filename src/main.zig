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
        const pwd = try prompt(allocator, io);
        try writer.interface.print("{s}> ", .{pwd});
        try writer.interface.flush();

        var reader = std.Io.File.reader(stdin, io, read_buffer);
        const n: usize = try reader.interface.discardDelimiterExclusive('\n');
        const output = try handler(allocator, read_buffer[0..n]);
        try writer.interface.print("{s}\n", .{output});
        try writer.interface.flush();
    }
}

pub fn prompt(allocator: std.mem.Allocator, io: std.Io) ![]const u8 {
    const pwd: []u8 = try allocator.alloc(u8, 1000);
    const n = try std.process.currentPath(io, pwd);
    return pwd[0..n];
}

const Input = struct {
    cmd: []const u8,
    args: []const u8,
};

const BuiltinCmd = enum {
    exit,
    echo,
};

pub fn handler(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    const output: []u8 = try allocator.alloc(u8, input.len);
    const input_lower_case = std.ascii.lowerString(output, input);
    const input_parsed = parseInput(input_lower_case);
    var cmd_output: []const u8 = undefined;
    const cmd_enum = std.meta.stringToEnum(BuiltinCmd, input_parsed.cmd) orelse {
        const warning_msg: []const u8 = "Unknown command";
        return warning_msg;
    };

    switch (cmd_enum) {
        .exit => exit(),
        .echo => {
            cmd_output = echo(input_parsed.args);
        },
    }
    return cmd_output;
}

pub fn parseInput(input: []const u8) Input {
    const trimmed_input = std.mem.trimEnd(u8, input, " \n\r\t");
    var parsed_input: Input = Input{
        .cmd = trimmed_input,
        .args = "",
    };
    const space_index = std.mem.indexOfAny(u8, trimmed_input, " \t\n\r") orelse {
        return parsed_input;
    };
    parsed_input.cmd = input[0..space_index];
    parsed_input.args = input[space_index + 1 ..];
    return parsed_input;
}

pub fn exit() void {
    std.process.exit(0);
}

pub fn echo(args: []const u8) []const u8 {
    return args;
}
