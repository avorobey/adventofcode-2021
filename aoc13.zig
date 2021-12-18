const std = @import("std");
const expect = std.testing.expect;

var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
var pts = std.AutoHashMap(u32, bool).init(&gpalloc.allocator);

pub const Point = struct {
    x: u16,
    y: u16,
    fn encode(self: *const Point) u32 {
        return @intCast(u32, self.x) * 10000 + self.y;
    }
    fn decode(code: u32) Point {
        return Point{
            .x = @intCast(u16, code / 10000),
            .y = @intCast(u16, code % 10000),
        };
    }
};

fn fold(xfold: bool, border: u16) !void {
    var temp_pts: [1000]Point = undefined;
    var temp_ind: usize = 0;

    var iter = pts.iterator();
    while (iter.next()) |entry| {
        var p = Point.decode(entry.key_ptr.*);
        if ((xfold and p.x > border) or (!xfold and p.y > border)) {
            temp_pts[temp_ind] = p;
            temp_ind += 1;
        }
    }
    for (temp_pts[0..temp_ind]) |p| {
        var new_p = Point{ .x = p.x, .y = p.y };
        if (xfold) {
            new_p.x = 2 * border - p.x;
        } else {
            new_p.y = 2 * border - p.y;
        }
        _ = pts.remove(p.encode());
        try pts.put(new_p.encode(), true);
    }
    return;
}

fn printPts(x_len: u16, y_len: u16) void {
    var x: u16 = 0;
    var y: u16 = 0;
    while (y < y_len) {
        x = 0;
        while (x < x_len) {
            var p = Point{ .x = x, .y = y };
            if (pts.get(p.encode())) |_| {
                std.debug.print("#", .{});
            } else {
                std.debug.print(".", .{});
            }
            x += 1;
        }
        std.debug.print("\n", .{});
        y += 1;
    }
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc13.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (std.mem.eql(u8, line, "")) {
            break;
        }
        var iter = std.mem.tokenize(u8, line, ",");
        var p = Point{
            .x = try std.fmt.parseInt(u16, iter.next().?, 10),
            .y = try std.fmt.parseInt(u16, iter.next().?, 10),
        };
        try pts.put(p.encode(), true);
    }
    const fold_along = "fold along ";
    var first_run = true;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (!std.mem.eql(u8, line[0..fold_along.len], fold_along)) {
            @panic("bad format");
        } else {
            var xfold = true;
            if (line[fold_along.len] == 'x') {
                // Nothing.
            } else if (line[fold_along.len] == 'y') {
                xfold = false;
            } else {
                @panic("bad fold letter");
            }
            if (line[fold_along.len + 1] != '=') {
                @panic("bad =");
            }
            var border = try std.fmt.parseInt(u16, line[fold_along.len + 2 ..], 10);
            try fold(xfold, border);
            if (first_run) {
                try std.io.getStdOut().writer().print("part1: {d}\n", .{pts.count()});
            }
        }
        first_run = false;
    }
    printPts(40, 6);
}
