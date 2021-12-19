const std = @import("std");
const expect = std.testing.expect;

var edges: [500][500]u8 = undefined;
var length: u32 = undefined;
var width: u32 = undefined;
var distances = [_][500]u16{[_]u16{0} ** 500} ** 500;
var visited = [_][500]bool{[_]bool{false} ** 500} ** 500;

// Poor man's priority table.
// priorities[3] is a linear least of all points with current best distance 3.
// pr_lengths[3] is the length of priorities[3].
// pr_indices[i][j] is the index, within distances[i][j], of the point i,j.
var priorities: [2000][1000][2]u8 = undefined;
var pr_lengths = [_]u16{0} ** 2000;
var pr_indices = [_][500]u16{[_]u16{0} ** 500} ** 500;

fn updatePriority(x: u8, y: u8, pr: u16) void {
    var old_pr = distances[x][y];
    if (old_pr > 0 and old_pr <= pr) {
        return;
    }
    if (old_pr > 0) {
        // Remove from current priority.
        var ind = pr_indices[x][y];
        // Swap with last
        priorities[old_pr][ind] = priorities[old_pr][pr_lengths[old_pr] - 1];
        pr_lengths[old_pr] -= 1;
    }
    priorities[pr][pr_lengths[pr]] = [2]u8{ x, y };
    pr_indices[x][y] = pr_lengths[pr];
    pr_lengths[pr] += 1;
    distances[x][y] = pr;
}

fn getLeastPriority() [2]u8 {
    for (pr_lengths) |val, ind| {
        if (val > 0) {
            var coord = priorities[ind][val - 1];
            pr_lengths[ind] = val - 1;
            pr_indices[coord[0]][coord[1]] = 0;
            return coord;
        }
    }
    @panic("didn't find");
}

fn prDist() void {
    for (distances[0..length]) |row| {
        for (row[0..width]) |val| {
            std.debug.print("{d} ", .{val});
        }
        std.debug.print("\n", .{});
    }
}

fn prEdges() void {
    for (edges[0..length]) |row| {
        for (row[0..width]) |val| {
            std.debug.print("{d} ", .{val});
        }
        std.debug.print("\n", .{});
    }
}

fn dijkstra() void {
    while (true) {
        // prDist();
        var coord = getLeastPriority();
        var x = coord[0];
        var y = coord[1];
        visited[x][y] = true;
        if (x == width - 1 and y == length - 1) {
            return;
        }
        // Go over neighours.
        if (x > 0 and !visited[x - 1][y]) {
            updatePriority(x - 1, y, distances[x][y] + edges[x - 1][y]);
        }
        if (x < width - 1 and !visited[x + 1][y]) {
            updatePriority(x + 1, y, distances[x][y] + edges[x + 1][y]);
        }
        if (y > 0 and !visited[x][y - 1]) {
            updatePriority(x, y - 1, distances[x][y] + edges[x][y - 1]);
        }
        if (y < length - 1 and !visited[x][y + 1]) {
            updatePriority(x, y + 1, distances[x][y] + edges[x][y + 1]);
        }
    }
}

pub fn main() anyerror!void {
    // for part2, run with "zig run aoc15.zig -- part2"
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    var args = std.process.args();
    var part2 = false;
    if (args.next(&gpalloc.allocator)) |_| {
        if (args.next(&gpalloc.allocator)) |arg| {
            if (std.mem.eql(u8, try arg, "part2")) {
                part2 = true;
            }
        }
    }
    var file = try std.fs.cwd().openFile("aoc15.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var row: u32 = 0;
    var col: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        col = 0;
        for (line) |_, index| {
            edges[row][col] = try std.fmt.parseInt(u8, line[index .. index + 1], 10);
            col += 1;
        }
        width = col;
        row += 1;
    }
    length = row;

    if (part2) {
        for (edges[0..length]) |r, x| {
            for (r[0..width]) |val, y| {
                var i: u8 = 0;
                while (i < 5) {
                    var j: u8 = 0;
                    while (j < 5) {
                        if (i == 0 and j == 0) {
                            j += 1;
                            continue;
                        }
                        var newval = val + i + j;
                        if (newval > 9) {
                            newval -= 9;
                        }
                        edges[x + i * length][y + j * width] = newval;
                        j += 1;
                    }
                    i += 1;
                }
            }
        }
        length *= 5;
        width *= 5;
    }
    // prEdges();

    // Set things up.
    priorities[0][0] = [2]u8{ 0, 0 };
    pr_lengths[0] = 1;
    pr_indices[0][0] = 0;

    dijkstra();

    try std.io.getStdOut().writer().print("answer: {d}\n", .{distances[length - 1][width - 1]});
}
