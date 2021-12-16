const std = @import("std");
const expect = std.testing.expect;

fn present(letter: u8, str: []const u8) bool {
    return std.mem.indexOfScalar(u8, str, letter) != null;
}

test "present" {
    try expect(present('a', "abc"));
    try expect(present('a', "cba"));
    try expect(!present('a', ""));
    try expect(!present('a', "   "));
    try expect(!present('d', "abc cba"));
}

const closers = ")]}>";
const openers = "([{<";

fn firstBadCloser(line: []const u8) ?u8 {
    var stack: [1024]u8 = undefined;
    var ind: usize = 0;
    for (line) |letter| {
        if (!present(letter, closers)) {
            stack[ind] = letter;
            ind += 1;
        } else {
            if (ind != 0 and present(stack[ind - 1], openers) and std.mem.indexOfScalar(u8, openers, stack[ind - 1]).? ==
                std.mem.indexOfScalar(u8, closers, letter).?)
            {
                ind -= 1;
            } else {
                return letter;
            }
        }
    }
    return null;
}

fn completeScore(line: []const u8) u64 {
    var stack: [1024]u8 = undefined;
    var ind: usize = 0;
    for (line) |letter| {
        if (!present(letter, closers)) {
            stack[ind] = letter;
            ind += 1;
        } else {
            if (ind != 0 and present(stack[ind - 1], openers) and std.mem.indexOfScalar(u8, openers, stack[ind - 1]).? ==
                std.mem.indexOfScalar(u8, closers, letter).?)
            {
                ind -= 1;
            } else {
                std.debug.print("Invalid corrupted line: {s}\n", .{line});
                return 0;
            }
        }
    }
    var score: u64 = 0;
    while (ind > 0) {
        ind -= 1;
        score = score * 5 + std.mem.indexOfScalar(u8, openers, stack[ind]).? + 1;
    }
    return score;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc10.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var sum: u32 = 0;
    var scores: [1000]u64 = undefined;
    var ind: usize = 0;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (firstBadCloser(line)) |closer| {
            if (closer == ')') {
                sum += 3;
            } else if (closer == ']') {
                sum += 57;
            } else if (closer == '}') {
                sum += 1197;
            } else if (closer == '>') {
                sum += 25137;
            }
        } else {
            scores[ind] = completeScore(line);
            ind += 1;
        }
    }
    try std.io.getStdOut().writer().print("part1: {d}\n", .{sum});
    std.sort.sort(u64, scores[0..ind], {}, comptime std.sort.asc(u64));
    try std.io.getStdOut().writer().print("part2: {d}\n", .{scores[ind / 2]});
}
