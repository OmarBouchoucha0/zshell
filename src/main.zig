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

        try writer.interface.print("cmd : {s}\n", .{read_buffer[0..n]});
        try writer.interface.flush();
    }
}

// pub fn handler(cmd: []u8) ![]u8 {
//     std.debug.print("not implemented");
// }
