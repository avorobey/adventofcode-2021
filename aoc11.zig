const std = @import("std");
const expect = std.testing.expect;

fn oneStep(board: *[10][10]u8) u32 {
    var flashed = [_][10]bool{[_]bool{false} ** 10} ** 10;
    for (board.*) |row, ind_row| {
        for (row) |_, ind_col| {
            board[ind_row][ind_col] += 1;
        }
    }
    var flashes: u32 = 0;
    while (true) {
        var found = false;
        for (board.*) |row, ind_row| {
            for (row) |_, ind_col| {
                if (board[ind_row][ind_col] > 9 and !flashed[ind_row][ind_col]) {
                    found = true;
                    flashed[ind_row][ind_col] = true;
                    flashes += 1;
                    if (ind_row > 0) {
                        board[ind_row - 1][ind_col] += 1;
                        if (ind_col > 0) {
                            board[ind_row - 1][ind_col - 1] += 1;
                        }
                        if (ind_col < 9) {
                            board[ind_row - 1][ind_col + 1] += 1;
                        }
                    }
                    if (ind_row < 9) {
                        board[ind_row + 1][ind_col] += 1;
                        if (ind_col > 0) {
                            board[ind_row + 1][ind_col - 1] += 1;
                        }
                        if (ind_col < 9) {
                            board[ind_row + 1][ind_col + 1] += 1;
                        }
                    }
                    if (ind_col > 0) {
                        board[ind_row][ind_col - 1] += 1;
                    }
                    if (ind_col < 9) {
                        board[ind_row][ind_col + 1] += 1;
                    }
                }
            }
        }
        if (!found) {
            break;
        }
    }
    for (board.*) |row, ind_row| {
        for (row) |_, ind_col| {
            if (flashed[ind_row][ind_col]) {
                board[ind_row][ind_col] = 0;
            }
        }
    }
    return flashes;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc11.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var sum: u32 = 0;
    var board: [10][10]u8 = undefined;
    var row: usize = 0;
    var col: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        col = 0;
        for (line) |_, index| {
            board[row][col] = try std.fmt.parseInt(u8, line[index .. index + 1], 10);
            col += 1;
        }
        row += 1;
    }
    var cnt: u16 = 100;
    while (cnt > 0) {
        sum += oneStep(&board);
        cnt -= 1;
    }
    while (true) {
        cnt += 1;
        if (oneStep(&board) == 100) {
            break;
        }
    }
    try std.io.getStdOut().writer().print("part1: {d}\n", .{sum});
    try std.io.getStdOut().writer().print("part1: {d}\n", .{cnt + 100});
}
