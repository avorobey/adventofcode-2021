const std = @import("std");
const expect = std.testing.expect;

var arr: [101][101][101]bool = undefined;

fn processLine(x1: i32, x2: i32, y1: i32, y2: i32, z1: i32, z2: i32, on: bool) void {
    if (x1 < -50 or x2 > 50 or y1 < -50 or y2 > 50 or z1 < -50 or z2 > 50) {
        return;
    }
    std.debug.print("{d}:{d} {d}:{d} {d}:{d} {}\n", .{ x1, x2, y1, y2, z1, z2, on });
    for (arr) |row, i| {
        for (row) |col, j| {
            for (col) |_, k| {
                const x = @intCast(i32, i) - 50;
                const y = @intCast(i32, j) - 50;
                const z = @intCast(i32, k) - 50;
                if (x1 <= x and x <= x2 and y1 <= y and y <= y2 and z1 <= z and z <= z2) {
                    arr[i][j][k] = on;
                }
            }
        }
    }
    return;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc22.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    for (arr) |r1, i| {
        for (r1) |r2, j| {
            for (r2) |_, k| {
                arr[i][j][k] = false;
            }
        }
    }
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var on = false;
        if (std.mem.eql(u8, line[0..2], "on")) {
            on = true;
        }
        var iter = std.mem.tokenize(u8, line, ",=");
        _ = iter.next();
        var xs = iter.next().?;
        _ = iter.next();
        var ys = iter.next().?;
        _ = iter.next();
        var zs = iter.next().?;
        iter = std.mem.tokenize(u8, xs, ".");
        var x1 = try std.fmt.parseInt(i32, iter.next().?, 10);
        var x2 = try std.fmt.parseInt(i32, iter.next().?, 10);
        iter = std.mem.tokenize(u8, ys, ".");
        var y1 = try std.fmt.parseInt(i32, iter.next().?, 10);
        var y2 = try std.fmt.parseInt(i32, iter.next().?, 10);
        iter = std.mem.tokenize(u8, zs, ".");
        var z1 = try std.fmt.parseInt(i32, iter.next().?, 10);
        var z2 = try std.fmt.parseInt(i32, iter.next().?, 10);
        processLine(x1, x2, y1, y2, z1, z2, on);
    }

    var cnt: u32 = 0;
    for (arr) |r1| {
        for (r1) |r2| {
            for (r2) |val| {
                if (val) {
                    cnt += 1;
                }
            }
        }
    }
    try std.io.getStdOut().writer().print("part1: {d}\n", .{cnt});
}
