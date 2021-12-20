const std = @import("std");
const expect = std.testing.expect;

fn low(row: u32, col: u32, length: u32, width: u32, map: *[100][100]u8) bool {
    if (row > 0) {
        if (map[row - 1][col] <= map[row][col]) {
            return false;
        }
    }
    if (row < length - 1) {
        if (map[row + 1][col] <= map[row][col]) {
            return false;
        }
    }
    if (col > 0) {
        if (map[row][col - 1] <= map[row][col]) {
            return false;
        }
    }
    if (col < width - 1) {
        if (map[row][col + 1] <= map[row][col]) {
            return false;
        }
    }
    return true;
}

fn basin_size(map: *[100][100]u8, row: u32, col: u32, length: u32, width: u32) u16 {
    var visited = [_][100]bool{[_]bool{false} ** 100} ** 100;
    var stack_row: [10000]u32 = undefined;
    var stack_col: [10000]u32 = undefined;
    var stack_ind: u32 = 0;
    stack_row[stack_ind] = row;
    stack_col[stack_ind] = col;
    stack_ind += 1;
    var cnt: u16 = 0;
    while (stack_ind > 0) {
        var r = stack_row[stack_ind - 1];
        var c = stack_col[stack_ind - 1];
        stack_ind -= 1;
        if (visited[r][c]) { // may have been added independently later.
            continue;
        }
        visited[r][c] = true;
        cnt += 1;
        if (r > 0 and !visited[r - 1][c] and map[r - 1][c] != 9) {
            stack_row[stack_ind] = r - 1;
            stack_col[stack_ind] = c;
            stack_ind += 1;
        }
        if (r < length - 1 and !visited[r + 1][c] and map[r + 1][c] != 9) {
            stack_row[stack_ind] = r + 1;
            stack_col[stack_ind] = c;
            stack_ind += 1;
        }
        if (c > 0 and !visited[r][c - 1] and map[r][c - 1] != 9) {
            stack_row[stack_ind] = r;
            stack_col[stack_ind] = c - 1;
            stack_ind += 1;
        }
        if (c < width - 1 and !visited[r][c + 1] and map[r][c + 1] != 9) {
            stack_row[stack_ind] = r;
            stack_col[stack_ind] = c + 1;
            stack_ind += 1;
        }
    }
    return cnt;
}
pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc09.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var sum: u32 = 0;
    var map: [100][100]u8 = undefined;
    var row: u32 = 0;
    var col: u32 = 0;
    var length: u32 = undefined;
    var width: u32 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        col = 0;
        for (line) |_, index| {
            map[row][col] = try std.fmt.parseInt(u8, line[index .. index + 1], 10);
            col += 1;
        }
        width = col;
        row += 1;
    }
    length = row;

    row = 0;
    col = 0;
    var basins: [10000]u16 = undefined;
    var basin_ind: u32 = 0;
    while (row < length) {
        col = 0;
        while (col < width) {
            if (low(row, col, length, width, &map)) {
                sum += map[row][col] + 1;
                basins[basin_ind] = basin_size(&map, row, col, length, width);
                basin_ind += 1;
            }
            col += 1;
        }
        row += 1;
    }
    std.sort.sort(u16, basins[0..basin_ind], {}, comptime std.sort.desc(u16));
    var product: u64 = basins[0];
    product *= basins[1];
    product *= basins[2];

    try std.io.getStdOut().writer().print("part1: {d}\n", .{sum});
    try std.io.getStdOut().writer().print("part2: {d}\n", .{product});
}
