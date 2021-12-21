const std = @import("std");
const expect = std.testing.expect;

const margin: u8 = 55;
const work: u8 = 100; // change to 15 when running on aoc20.input.sample
const size: u8 = work + margin * 2;
var rules: [512]u8 = undefined;
var map: [size][size]u8 = undefined;

fn pr() void {
    for (map) |row| {
        for (row) |val| {
            if (val == 1) {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
        }
        std.debug.print("\n", .{});
    }
}

fn step(default: u8) !void {
    var map2: [size][size]u8 = undefined;
    for (map) |_, i| {
        for (map) |_, j| {
            var temp: [9]u8 = undefined;
            temp[0] = if (i > 0 and j > 0) '0' + map[i - 1][j - 1] else default;
            temp[1] = if (i > 0) '0' + map[i - 1][j] else default;
            temp[2] = if (i > 0 and j < size - 1) '0' + map[i - 1][j + 1] else default;
            temp[3] = if (j > 0) '0' + map[i][j - 1] else default;
            temp[4] = '0' + map[i][j];
            temp[5] = if (j < size - 1) '0' + map[i][j + 1] else default;
            temp[6] = if (i < size - 1 and j > 0) '0' + map[i + 1][j - 1] else default;
            temp[7] = if (i < size - 1) '0' + map[i + 1][j] else default;
            temp[8] = if (i < size - 1 and j < size - 1) '0' + map[i + 1][j + 1] else default;
            const index = try std.fmt.parseInt(u16, temp[0..9], 2);
            const new_val = rules[index];
            map2[i][j] = new_val;
        }
    }
    map = map2;
}

fn countOnes() u16 {
    var cnt: u16 = 0;
    for (map) |r| {
        for (r) |v| {
            cnt += v;
        }
    }
    return cnt;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc20.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var rule_str = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    for (rule_str.?) |val, ind| {
        rules[ind] = if (val == '#') 1 else 0;
    }
    _ = try in_stream.readUntilDelimiterOrEof(&buf, '\n');

    for (map[0..margin]) |row, i| {
        for (row) |_, j| {
            map[i][j] = 0;
        }
    }
    for (map[size - margin .. size]) |row, i| {
        for (row) |_, j| {
            map[size - margin + i][j] = 0;
        }
    }
    var row: u16 = margin;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var col: u16 = 0;
        while (col < margin) {
            map[row][col] = 0;
            col += 1;
        }
        for (line) |d| {
            map[row][col] = if (d == '#') 1 else 0;
            col += 1;
        }
        while (col < size) {
            map[row][col] = 0;
            col += 1;
        }
        row += 1;
    }
    // pr();
    try step('0');
    // pr();
    try step('1');
    // pr();

    try std.io.getStdOut().writer().print("part1: {d}\n", .{countOnes()});

    var cnt: u16 = 48;
    while (cnt > 0) {
        if (cnt % 2 == 0) {
            try step('0');
        } else {
            try step('1');
        }
        cnt -= 1;
    }
    try std.io.getStdOut().writer().print("part2: {d}\n", .{countOnes()});
}
