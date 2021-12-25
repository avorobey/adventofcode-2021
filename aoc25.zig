const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

var map: [150][150]u8 = undefined;
var length: u32 = undefined;
var width: u32 = undefined;

var to_move: [150][150]bool = undefined;

fn moveLeft() u64 {
    for (map[0..length]) |row, i| {
        for (row[0..width]) |val, j| {
            var next = (j + 1) % width;
            if (val == '>' and map[i][next] == '.') {
                to_move[i][j] = true;
            } else {
                to_move[i][j] = false;
            }
        }
    }
    var cnt: u64 = 0;
    for (map[0..length]) |row, i| {
        for (row[0..width]) |_, j| {
            if (to_move[i][j]) {
                cnt += 1;
                var next = (j + 1) % width;
                map[i][next] = map[i][j];
                map[i][j] = '.';
            }
        }
    }
    return cnt;
}

fn moveDown() u64 {
    for (map[0..length]) |row, i| {
        for (row[0..width]) |val, j| {
            var next = (i + 1) % length;
            if (val == 'v' and map[next][j] == '.') {
                to_move[i][j] = true;
            } else {
                to_move[i][j] = false;
            }
        }
    }
    var cnt: u64 = 0;
    for (map[0..length]) |row, i| {
        for (row[0..width]) |_, j| {
            if (to_move[i][j]) {
                cnt += 1;
                var next = (i + 1) % length;
                map[next][j] = map[i][j];
                map[i][j] = '.';
            }
        }
    }
    return cnt;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc25.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var row: u32 = 0;
    var col: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        col = 0;
        for (line) |val| {
            map[row][col] = val;
            col += 1;
        }
        width = col;
        row += 1;
    }
    length = row;

    var steps: u64 = 0;
    while (true) {
        steps += 1;
        const moved_left = moveLeft();
        const moved_down = moveDown();
        if (moved_left == 0 and moved_down == 0) {
            break;
        }
    }
    try std.io.getStdOut().writer().print("part1: {d}\n", .{steps});
}
