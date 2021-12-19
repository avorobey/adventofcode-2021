const std = @import("std");
const expect = std.testing.expect;

var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
var rules = std.AutoHashMap(u16, u8).init(&gpalloc.allocator);

var polymer: [65000]u8 = undefined;
var len: usize = 0;

fn step() void {
    //std.debug.print("{s}\n", .{polymer[0..len]});
    var ind: usize = len;
    while (ind > 0) {
        ind -= 1;
        if (ind > 0) {
            polymer[ind * 2] = polymer[ind];
            polymer[ind * 2 - 1] = rules.get(@intCast(u16, polymer[ind - 1]) * 256 + polymer[ind]).?;
        }
    }
    len = len * 2 - 1;
}

fn counts() u16 {
    var cnts = [_]u16{0} ** 256;
    for (polymer[0..len]) |letter| {
        cnts[letter] += 1;
    }
    var least: u16 = 0;
    var most: u16 = 0;
    for (cnts) |val| {
        if (val > most) {
            most = val;
        }
        if (val > 0 and (least == 0 or val < least)) {
            least = val;
        }
    }
    return most - least;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc14.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var initial = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    std.mem.copy(u8, polymer[0..], initial.?);
    len = initial.?.len;
    _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n');

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try rules.put(@intCast(u16, line[0]) * 256 + line[1], line[6]);
    }
    var cnt: u8 = 10;
    while (cnt > 0) {
        step();
        cnt -= 1;
    }
    try std.io.getStdOut().writer().print("part1: {d}\n", .{counts()});
}
