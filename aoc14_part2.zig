const std = @import("std");
const expect = std.testing.expect;

var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
var rules = std.AutoHashMap(u16, u8).init(&gpalloc.allocator);

var pairs = [_][256]u64{[_]u64{0} ** 256} ** 256;
var start: u8 = 0;
var end: u8 = 0;

fn step() void {
    var new_pairs = [_][256]u64{[_]u64{0} ** 256} ** 256;
    for (pairs) |_, i| {
        for (pairs) |_, j| {
            if (pairs[i][j] > 0) {
                var k = rules.get(@intCast(u16, i) * 256 + @intCast(u16, j)).?;
                new_pairs[i][k] += pairs[i][j];
                new_pairs[k][j] += pairs[i][j];
            }
        }
    }
    pairs = new_pairs;
}

fn counts() u64 {
    var cnts = [_]u64{0} ** 256;
    for (pairs) |_, i| {
        for (pairs) |_, j| {
            if (pairs[i][j] > 0) {
                cnts[i] += pairs[i][j];
                cnts[j] += pairs[i][j];
            }
        }
    }
    cnts[start] += 1;
    cnts[end] += 1;

    for (cnts) |val, i| {
        cnts[i] = val / 2;
    }
    var least: u64 = 0;
    var most: u64 = 0;
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

    var opt_initial = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var initial = opt_initial.?;
    start = initial[0];
    end = initial[initial.len - 1];
    for (initial) |_, i| {
        if (i < initial.len - 1) {
            pairs[initial[i]][initial[i + 1]] += 1;
        }
    }
    _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n');

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try rules.put(@intCast(u16, line[0]) * 256 + line[1], line[6]);
    }
    var cnt: u8 = 40;
    while (cnt > 0) {
        step();
        cnt -= 1;
        if (cnt == 30) {
            try std.io.getStdOut().writer().print("part1: {d}\n", .{counts()});
        }
    }
    try std.io.getStdOut().writer().print("part2: {d}\n", .{counts()});
}
