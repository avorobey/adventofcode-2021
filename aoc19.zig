const std = @import("std");
const expect = std.testing.expect;

pub const Point = struct {
    x: i16,
    y: i16,
    z: i16,
    fn pr(self: *const Point) void {
        std.debug.print("point: {d},{d},{d}\n", .{ self.x, self.y, self.z });
    }
};

fn compPoint(_: void, p1: Point, p2: Point) bool {
    return ((p1.x < p2.x) or
        ((p1.x == p2.x) and (p1.y < p2.y)) or
        ((p1.x == p2.x) and (p1.y == p2.y) and (p1.z < p2.z)));
}

pub const Scanner = struct {
    buf: [60]Point = undefined,
    len: usize = 0,
    scanner_pov: Point = undefined,
    fn pr(self: *const Scanner) void {
        std.debug.print("\n", .{});
        for (self.buf[0..self.len]) |p| {
            p.pr();
        }
        std.debug.print("\n", .{});
    }
    fn rotateInto(self: *const Scanner, rotation: [9]i8) Scanner {
        var s = Scanner{};
        // std.debug.print("rotating {d} points\n", .{self.len});
        for (self.buf[0..self.len]) |val, ind| {
            s.buf[ind] = Point{
                .x = val.x * rotation[0] + val.y * rotation[1] + val.z * rotation[2],
                .y = val.x * rotation[3] + val.y * rotation[4] + val.z * rotation[5],
                .z = val.x * rotation[6] + val.y * rotation[7] + val.z * rotation[8],
            };
            // std.debug.print("val: {d} {d} {d}  s.buf: {d} {d} {d}\n", .{ val.x, val.y, val.z, s.buf[ind].x, s.buf[ind].y, s.buf[ind].z });
        }
        s.len = self.len;
        return s;
    }
    fn shiftInto(self: *Scanner, from: Point, to: Point) Scanner {
        var s = Scanner{};
        for (self.buf[0..self.len]) |val, ind| {
            s.buf[ind] = Point{
                .x = val.x + to.x - from.x,
                .y = val.y + to.y - from.y,
                .z = val.z + to.z - from.z,
            };
        }
        s.len = self.len;
        return s;
    }
    fn countDups(self: *Scanner, other: *Scanner) u16 {
        var join = Scanner{};
        for (self.buf[0..self.len]) |val, ind| {
            join.buf[ind] = val;
        }
        for (other.buf[0..other.len]) |val, ind| {
            join.buf[ind + self.len] = val;
        }
        join.len = self.len + other.len;
        std.sort.sort(Point, join.buf[0..join.len], {}, compPoint);
        var cnt: u16 = 0;
        for (join.buf[0..join.len]) |val, ind| {
            if (ind > 0 and val.x == join.buf[ind - 1].x and val.y == join.buf[ind - 1].y and val.z == join.buf[ind - 1].z) {
                cnt += 1;
            }
        }
        // std.debug.print("cnt:{d} \n", .{cnt});
        return cnt;
    }
};

fn countGlobalUniques(scanners: []Scanner) u16 {
    var buf: [100000]Point = undefined;
    var len: u16 = 0;
    var cnt: u16 = 0;
    for (scanners) |s| {
        for (s.buf[0..s.len]) |p| {
            buf[len] = p;
            len += 1;
        }
    }
    std.sort.sort(Point, buf[0..len], {}, compPoint);
    for (buf[0..len]) |val, ind| {
        if (ind > 0 and val.x == buf[ind - 1].x and val.y == buf[ind - 1].y and val.z == buf[ind - 1].z) {
            cnt += 1;
        }
    }
    return len - cnt;
}

const rotations = [24][9]i8{
    [_]i8{ 1, 0, 0, 0, 1, 0, 0, 0, 1 },
    [_]i8{ 0, -1, 0, 1, 0, 0, 0, 0, 1 },
    [_]i8{ -1, 0, 0, 0, -1, 0, 0, 0, 1 },
    [_]i8{ 0, 1, 0, -1, 0, 0, 0, 0, 1 },
    [_]i8{ 1, 0, 0, 0, -1, 0, 0, 0, -1 },
    [_]i8{ 0, 1, 0, 1, 0, 0, 0, 0, -1 },
    [_]i8{ -1, 0, 0, 0, 1, 0, 0, 0, -1 },
    [_]i8{ 0, -1, 0, -1, 0, 0, 0, 0, -1 },
    [_]i8{ 1, 0, 0, 0, 0, -1, 0, 1, 0 },
    [_]i8{ 0, 0, 1, 1, 0, 0, 0, 1, 0 },
    [_]i8{ -1, 0, 0, 0, 0, -1, 0, -1, 0 },
    [_]i8{ 0, 0, 1, -1, 0, 0, 0, -1, 0 },
    [_]i8{ 1, 0, 0, 0, 0, 1, 0, -1, 0 },
    [_]i8{ 0, 0, -1, 1, 0, 0, 0, -1, 0 },
    [_]i8{ -1, 0, 0, 0, 0, 1, 0, 1, 0 },
    [_]i8{ 0, 0, -1, -1, 0, 0, 0, 1, 0 },
    [_]i8{ 0, 0, -1, 0, 1, 0, 1, 0, 0 },
    [_]i8{ 0, 1, 0, 0, 0, 1, 1, 0, 0 },
    [_]i8{ 0, 0, -1, 0, -1, 0, -1, 0, 0 },
    [_]i8{ 0, -1, 0, 0, 0, 1, -1, 0, 0 },
    [_]i8{ 0, 0, 1, 0, -1, 0, 1, 0, 0 },
    [_]i8{ 0, 0, 1, 0, 1, 0, -1, 0, 0 },
    [_]i8{ 0, -1, 0, 0, 0, -1, 1, 0, 0 },
    [_]i8{ 0, 1, 0, 0, 0, -1, -1, 0, 0 },
};

fn match(first: *Scanner, second: *const Scanner) ?Scanner {
    for (rotations) |rot| {
        var rotated = second.rotateInto(rot);
        for (first.buf[0..first.len]) |val1| {
            // val1.pr();
            for (rotated.buf[0..rotated.len]) |val2| {
                var shifted = rotated.shiftInto(val2, val1);
                if (first.countDups(&shifted) >= 12) {
                    shifted.scanner_pov = Point{ .x = val1.x - val2.x, .y = val1.y - val2.y, .z = val1.z - val2.z };
                    return shifted;
                }
            }
        }
    }
    return null;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc19.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var scanners: [50]Scanner = undefined;
    var scan_num: usize = 0;
    var done = [_]bool{false} ** 50;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        _ = line; // header line
        scanners[scan_num] = Scanner{};
        var s = &scanners[scan_num];
        scan_num += 1;
        while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |l| {
            if (l.len == 0) {
                break;
            }
            var iter = std.mem.tokenize(u8, l, ",");
            s.buf[s.len] = Point{
                .x = try std.fmt.parseInt(i16, iter.next().?, 10),
                .y = try std.fmt.parseInt(i16, iter.next().?, 10),
                .z = try std.fmt.parseInt(i16, iter.next().?, 10),
            };
            s.len += 1;
        }
    }

    var adjusted: [50]Scanner = undefined;
    var adj_num: usize = 0;
    var adj_ind: usize = 0;

    adjusted[0] = scanners[0];
    adjusted[0].scanner_pov = Point{ .x = 0, .y = 0, .z = 0 };
    adj_num = 1;
    adj_ind = 0;
    done[0] = true;

    while (true) {
        var scan1 = &adjusted[adj_ind];
        for (scanners[0..scan_num]) |scan, ind| {
            if (!done[ind]) {
                // std.debug.print("Trying to match adj num {d} with scan num {d}...\n", .{ adj_ind, ind });
                if (match(scan1, &scan)) |result| {
                    adjusted[adj_num] = result;
                    adj_num += 1;
                    done[ind] = true;
                    // std.debug.print("Matched!\n", .{});
                } else {
                    // std.debug.print("Unmatched.\n", .{});
                }
            }
        }
        adj_ind += 1;
        if (adj_ind >= adj_num) {
            break;
        }
    }
    // std.debug.print("adjusted scanners: {d}\n", .{adj_num});

    try std.io.getStdOut().writer().print("part1: {}\n", .{countGlobalUniques(adjusted[0..adj_num])});

    var max_dist: i16 = 0;
    for (adjusted[0..adj_num]) |val1| {
        for (adjusted[0..adj_num]) |val2| {
            const x_dist = try std.math.absInt(val1.scanner_pov.x - val2.scanner_pov.x);
            const y_dist = try std.math.absInt(val1.scanner_pov.y - val2.scanner_pov.y);
            const z_dist = try std.math.absInt(val1.scanner_pov.z - val2.scanner_pov.z);
            const dist = x_dist + y_dist + z_dist;
            if (dist > max_dist) {
                max_dist = dist;
            }
        }
    }
    try std.io.getStdOut().writer().print("part2: {}\n", .{max_dist});
}
