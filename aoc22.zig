const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

var arr: [101][101][101]bool = undefined;

fn processLinePart1(x1: i32, x2: i32, y1: i32, y2: i32, z1: i32, z2: i32, on: bool) void {
    if (x1 < -50 or x2 > 50 or y1 < -50 or y2 > 50 or z1 < -50 or z2 > 50) {
        return;
    }
    // std.debug.print("{d}:{d} {d}:{d} {d}:{d} {}\n", .{ x1, x2, y1, y2, z1, z2, on });
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

pub const Brick = struct {
    const Self = @This();
    // left bottom x,y,z right upper x,y,z
    lbx: i32,
    lby: i32,
    lbz: i32,
    rux: i32,
    ruy: i32,
    ruz: i32,
    fn maybeInit(lbx: i32, lby: i32, lbz: i32, rux: i32, ruy: i32, ruz: i32) ?Self {
        if (lbx > rux or lby > ruy or lbz > ruz) {
            return null;
        } else {
            return Self{ .lbx = lbx, .lby = lby, .lbz = lbz, .rux = rux, .ruy = ruy, .ruz = ruz };
        }
    }
    fn intersect(self: *const Brick, other: *const Brick) ?Brick {
        var lbx = @maximum(self.lbx, other.lbx);
        var lby = @maximum(self.lby, other.lby);
        var lbz = @maximum(self.lbz, other.lbz);
        var rux = @minimum(self.rux, other.rux);
        var ruy = @minimum(self.ruy, other.ruy);
        var ruz = @minimum(self.ruz, other.ruz);
        return Brick.maybeInit(lbx, lby, lbz, rux, ruy, ruz);
    }
    // Subtract other from self - intersection must be nonempty - and adds pieces to list.
    fn subtractAndAppend(self: *const Brick, other: *const Brick, list: *std.ArrayList(Brick)) !void {
        var inter = self.intersect(other).?;
        //print("subtractAndAppend, intersection: ", .{});
        //inter.pr();
        //print("self: ", .{});
        //self.pr();
        //print("list: ", .{});
        //dumpBricks(list);
        if (maybeInit(self.lbx, self.lby, self.lbz, inter.lbx - 1, self.ruy, self.ruz)) |brick| {
            try list.append(brick);
            //print("first brick: ", .{});
            //brick.pr();
        }
        if (maybeInit(inter.rux + 1, self.lby, self.lbz, self.rux, self.ruy, self.ruz)) |brick| {
            try list.append(brick);
            //print("second brick: ", .{});
            //brick.pr();
        }
        if (maybeInit(inter.lbx, self.lby, self.lbz, inter.rux, self.ruy, inter.lbz - 1)) |brick| {
            try list.append(brick);
            //print("third brick: ", .{});
            //brick.pr();
        }
        if (maybeInit(inter.lbx, self.lby, inter.ruz + 1, inter.rux, self.ruy, self.ruz)) |brick| {
            try list.append(brick);
            //print("fourth brick: ", .{});
            //brick.pr();
        }
        if (maybeInit(inter.lbx, self.lby, inter.lbz, inter.rux, inter.lby - 1, inter.ruz)) |brick| {
            try list.append(brick);
            //print("fifth brick: ", .{});
            //brick.pr();
        }
        if (maybeInit(inter.lbx, inter.ruy + 1, inter.lbz, inter.rux, self.ruy, inter.ruz)) |brick| {
            try list.append(brick);
            //print("sixth brick: ", .{});
            //brick.pr();
        }
    }
    fn volume(self: *const Brick) i64 {
        return @as(i64, self.rux - self.lbx + 1) * @as(i64, self.ruy - self.lby + 1) * @as(i64, self.ruz - self.lbz + 1);
    }
    fn pr(self: *const Brick) void {
        std.debug.print("{}:{}:{}->{}:{}:{}\n", .{ self.lbx, self.lby, self.lbz, self.rux, self.ruy, self.ruz });
    }
};

fn dumpBricks(list: *std.ArrayList(Brick)) void {
    for (list.items) |brick| {
        std.debug.print("{}:{}:{}->{}:{}:{} |", .{ brick.lbx, brick.lby, brick.lbz, brick.rux, brick.ruy, brick.ruz });
    }
    std.debug.print("\n", .{});
}

fn volBricks(list: *std.ArrayList(Brick)) i64 {
    var vol: i64 = 0;
    for (list.items) |brick| {
        vol += brick.volume();
    }
    return vol;
}

test "basic Brick" {
    var b1 = Brick.maybeInit(1, 1, 1, 3, 3, 3).?;
    try expect(b1.volume() == 27);
    var b2 = Brick.maybeInit(1, 1, 1, 13, 1, 1).?;
    try expect(b2.volume() == 13);
    var b3 = Brick.maybeInit(5, 1, 1, 5, 10, 1).?;
    try expect(b3.volume() == 10);
    try expect(b2.intersect(&b3).?.volume() == 1);
}

test "subtract" {
    var bricks = std.ArrayList(Brick).init(std.testing.allocator);
    defer bricks.deinit();
    var b1 = Brick.maybeInit(1, 1, 1, 3, 3, 3).?;
    var b2 = Brick.maybeInit(2, 2, 2, 2, 2, 2).?;
    try b1.subtractAndAppend(&b2, &bricks);
    try expect(volBricks(&bricks) == 26);
}

fn addToDisjointList(list: *std.ArrayList(Brick), new: *std.ArrayList(Brick), on: bool) !void {
    //std.debug.print("Starting addToDisjointList\n", .{});
    //dumpBricks(list);
    //dumpBricks(new);
    var i: usize = 0;
    while (i < new.items.len) {
        var j: usize = 0;
        var advance_i = true;
        while (j < list.items.len) {
            if (i >= new.items.len) {
                break;
            }
            //std.debug.print("i={}, j={}\n", .{ i, j });
            //std.debug.print("bricks: ", .{});
            //dumpBricks(list);
            //std.debug.print("new_bricks: ", .{});
            //dumpBricks(new);
            if (list.items[j].intersect(&new.items[i])) |inter| {
                var olditem = list.items[j];
                var newitem = new.items[i];
                //std.debug.print("intersection between old {d} and new {d}:\n", .{ j, i });
                //print("old: ", .{});
                //olditem.pr();
                //print("new: ", .{});
                //newitem.pr();
                //print("intersection: ", .{});
                //inter.pr();
                try olditem.subtractAndAppend(&inter, list);
                //std.debug.print("old after sAA:\n", .{});
                //dumpBricks(list);
                if (on) {
                    try list.append(inter);
                }
                _ = list.swapRemove(j);
                try newitem.subtractAndAppend(&inter, new);
                _ = new.swapRemove(i);
                //std.debug.print("new after sAA:\n", .{});
                //dumpBricks(new);
                advance_i = false;
            } else {
                j += 1;
            }
        }
        if (advance_i) {
            i += 1;
        }
    }
    if (on) {
        try list.appendSlice(new.items);
    }
}

test "addToDisjoint" {
    var bricks = std.ArrayList(Brick).init(std.testing.allocator);
    defer bricks.deinit();
    var new_bricks = std.ArrayList(Brick).init(std.testing.allocator);
    defer new_bricks.deinit();
    var b1 = Brick.maybeInit(1, 1, 1, 3, 3, 3).?;
    try bricks.append(b1);
    var b2 = Brick.maybeInit(2, 2, 2, 2, 2, 2).?;
    try new_bricks.append(b2);
    try addToDisjointList(&bricks, &new_bricks, false);
    try expect(volBricks(&bricks) == 26);

    bricks.clearAndFree();
    new_bricks.clearAndFree();

    try bricks.append(b1);
    try new_bricks.append(b2);
    try addToDisjointList(&bricks, &new_bricks, true);
    try expect(volBricks(&bricks) == 27);
}

var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
var on_bricks = std.ArrayList(Brick).init(&gpalloc.allocator);

fn processLinePart2(x1: i32, x2: i32, y1: i32, y2: i32, z1: i32, z2: i32, on: bool) !void {
    // Uncomment to only deal with the small bricks (part 1).
    // if (x1 < -50 or x2 > 50 or y1 < -50 or y2 > 50 or z1 < -50 or z2 > 50) {
    //     return;
    // }
    // std.debug.print("{d}:{d} {d}:{d} {d}:{d} {}\n", .{ x1, x2, y1, y2, z1, z2, on });
    var new_bricks = std.ArrayList(Brick).init(&gpalloc.allocator);
    var brick = Brick.maybeInit(x1, y1, z1, x2, y2, z2).?;
    try new_bricks.append(brick);
    try addToDisjointList(&on_bricks, &new_bricks, on);
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
        processLinePart1(x1, x2, y1, y2, z1, z2, on);
        try processLinePart2(x1, x2, y1, y2, z1, z2, on);
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
    try std.io.getStdOut().writer().print("part2: {d}\n", .{volBricks(&on_bricks)});
    // dumpBricks(&on_bricks);
}
