const std = @import("std");
const expect = std.testing.expect;

pub const Number = struct {
    const Self = @This();
    buf: [4000]u8 = undefined,
    len: usize = 0,
    fn init(str: []const u8) Self {
        var o = Self{};
        std.mem.copy(u8, o.buf[0..], str);
        o.len = str.len;
        return o;
    }
    fn eql(self: *Number, str: []const u8) bool {
        return std.mem.eql(u8, self.buf[0..self.len], str);
    }

    fn isOpen(self: *Number, ind: usize) bool {
        return self.buf[ind] == '[';
    }
    fn isClose(self: *Number, ind: usize) bool {
        return self.buf[ind] == ']';
    }
    fn isComma(self: *Number, ind: usize) bool {
        return self.buf[ind] == ',';
    }
    fn isDigit(self: *Number, ind: usize) bool {
        return self.buf[ind] >= '0' and self.buf[ind] <= '9';
    }

    fn nextToken(self: *Number, ind: usize) ?usize {
        var ret = ind;
        if (self.isDigit(ret)) {
            ret += 1;
            while (ret < self.len and self.isDigit(ret)) {
                ret += 1;
            }
            if (ret == self.len) {
                return null;
            } else {
                return ret;
            }
        } else if (ret < self.len - 1) {
            return ret + 1;
        } else {
            return null;
        }
    }
    fn prevToken(self: *Number, ind: usize) ?usize {
        _ = self;
        var ret = ind;
        if (ret == 0) {
            return null;
        }
        ret -= 1;
        if (self.isDigit(ret)) {
            while (ret > 0 and self.isDigit(ret - 1)) {
                ret -= 1;
            }
        }
        return ret;
    }
    fn splitReplace(self: *Number, from: usize, to: usize, with: []const u8) void {
        var temp: [4000]u8 = undefined;
        std.mem.copy(u8, temp[0..], self.buf[0..from]);
        std.mem.copy(u8, temp[from..], with);
        std.mem.copy(u8, temp[from + with.len ..], self.buf[to..self.len]);
        const new_len = self.len - (to - from) + with.len;
        std.mem.copy(u8, self.buf[0..], temp[0..new_len]);
        self.len = new_len;
    }
    fn explode(self: *Number, ind: usize) !void {
        const open = ind;
        const first = self.nextToken(open).?;
        const comma = self.nextToken(first).?;
        const second = self.nextToken(comma).?;
        const close = self.nextToken(second).?;
        const first_num = try std.fmt.parseInt(u8, self.buf[first..comma], 10);
        const second_num = try std.fmt.parseInt(u8, self.buf[second..close], 10);
        self.splitReplace(open, close + 1, "0");
        var next = self.nextToken(ind).?;
        while (!self.isDigit(next)) {
            if (self.nextToken(next)) |n| {
                next = n;
            } else {
                break;
            }
        }
        if (self.isDigit(next)) {
            const next_1 = self.nextToken(next).?;
            const right = try std.fmt.parseInt(u8, self.buf[next..next_1], 10);
            var temp: [3]u8 = undefined;
            var printed = try std.fmt.bufPrint(temp[0..], "{d}", .{right + second_num});
            self.splitReplace(next, next_1, printed);
        }
        var prev = self.prevToken(ind).?;
        while (!self.isDigit(prev)) {
            if (self.prevToken(prev)) |p| {
                prev = p;
            } else {
                break;
            }
        }
        if (self.isDigit(prev)) {
            const next_1 = self.nextToken(prev).?;
            const left = try std.fmt.parseInt(u8, self.buf[prev..next_1], 10);
            var temp: [3]u8 = undefined;
            var printed = try std.fmt.bufPrint(temp[0..], "{d}", .{left + first_num});
            self.splitReplace(prev, next_1, printed);
        }
    }
    fn split(self: *Number, ind: usize) !void {
        const next = self.nextToken(ind).?;
        const num = try std.fmt.parseInt(u8, self.buf[ind..next], 10);
        const lower = @divTrunc(num, 2);
        const upper = @divTrunc(num + 1, 2);
        var temp: [100]u8 = undefined;
        var printed = try std.fmt.bufPrint(temp[0..], "[{d},{d}]", .{ lower, upper });
        self.splitReplace(ind, next, printed);
    }
    fn reduceOnce(self: *Number) !bool {
        // Look for explosions.
        var ind: usize = 0;
        var level: u8 = 0;
        while (true) {
            if (self.isOpen(ind) and level == 4) {
                try self.explode(ind);
                return true;
            }
            if (self.isOpen(ind)) {
                level += 1;
            }
            if (self.isClose(ind)) {
                level -= 1;
            }
            if (self.nextToken(ind)) |next| {
                ind = next;
            } else {
                break;
            }
        }
        ind = 0;
        while (true) {
            if (self.isDigit(ind) and ind < self.len - 1 and self.isDigit(ind + 1)) {
                try self.split(ind);
                return true;
            }
            if (self.nextToken(ind)) |next| {
                ind = next;
            } else {
                break;
            }
        }
        return false;
    }
    fn reduceAll(self: *Number) !void {
        while (try self.reduceOnce()) {}
    }

    fn add(self: *Number, other: *Number) !void {
        var temp: [4000]u8 = undefined;
        temp[0] = '[';
        std.mem.copy(u8, temp[1..], self.buf[0..self.len]);
        temp[self.len + 1] = ',';
        std.mem.copy(u8, temp[self.len + 2 ..], other.buf[0..other.len]);
        temp[self.len + 2 + other.len] = ']';
        const new_len = self.len + other.len + 3;
        std.mem.copy(u8, self.buf[0..], temp[0..new_len]);
        self.len = new_len;

        try self.reduceAll();
        return;
    }
};

test "test number" {
    var n1 = Number.init("[345,[3,4]]");
    try expect(n1.nextToken(0).? == 1);
    try expect(n1.prevToken(0) == null);
    try expect(n1.nextToken(1).? == 4);
    try expect(n1.prevToken(1).? == 0);
    try expect(n1.nextToken(10) == null);
    try expect(n1.prevToken(10).? == 9);
}

test "test add" {
    var n1 = Number.init("[1,2]");
    var n2 = Number.init("[3,4]");
    try n1.add(&n2);
    try expect(n1.eql("[[1,2],[3,4]]"));
}

test "test reduce" {
    var n1 = Number.init("[[1,2],[3,[4,[[8,9],6]]]]");
    _ = try n1.reduceOnce();
    try expect(n1.eql("[[1,2],[3,[12,[0,15]]]]"));
    var n2 = Number.init("[[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]");
    _ = try n2.reduceOnce();
    try expect(n2.eql("[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]"));
    var n3 = Number.init("[[[[0,7],4],[15,[0,13]]],[1,1]]");
    _ = try n3.reduceOnce();
    try expect(n3.eql("[[[[0,7],4],[[7,8],[0,13]]],[1,1]]"));
    var n4 = Number.init("[[[[0,7],4],[16,[0,13]]],[1,1]]");
    _ = try n4.reduceOnce();
    try expect(n4.eql("[[[[0,7],4],[[8,8],[0,13]]],[1,1]]"));

    var n5 = Number.init("[[[[[6,6],[6,6]],[[6,0],[6,7]]],[[[7,7],[8,9]],[8,[8,1]]]],[2,9]]");
    try n5.reduceAll();
    try expect(n5.eql("[[[[6,6],[7,7]],[[0,7],[7,7]]],[[[5,5],[5,6]],9]]"));
}

const MagnitudeErrors = error{
    InvalidCharacter,
    Overflow,
};
fn magnitude(str: []const u8) MagnitudeErrors!u64 {
    if (str[0] == '[') {
        var level: u8 = 0;
        var comma_ind: usize = 0;
        for (str[0..]) |val, ind| {
            if (val == '[') {
                level += 1;
            }
            if (val == ']') {
                level -= 1;
            }
            if (val == ',' and level == 1) {
                comma_ind = ind;
                break;
            }
        }
        if (comma_ind == 0) {
            @panic("didn't find comma");
        }
        const first = try magnitude(str[1..comma_ind]);
        const second = try magnitude(str[comma_ind + 1 .. str.len - 1]);
        return 3 * first + 2 * second;
    } else {
        return try std.fmt.parseInt(u64, str, 10);
    }
}

test "magnitude" {
    const m = try magnitude("[[[[8,7],[7,7]],[[8,6],[7,7]]],[[[0,7],[6,6]],[8,7]]]");
    try expect(m == 3488);
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc18.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    var nums = std.ArrayList(Number).init(&gpalloc.allocator);
    defer nums.deinit();

    var opt_first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var acc = Number.init(opt_first_line.?);
    try nums.append(acc);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var new_num = Number.init(line);
        try nums.append(new_num);
        // std.debug.print("  {s}\n+  {s}\n=  ", .{ acc.buf[0..acc.len], new_num.buf[0..new_num.len] });
        try acc.add(&new_num);
        // std.debug.print("{s}\n", .{acc.buf[0..acc.len]});
    }
    // std.debug.print("{s}\n", .{acc.buf[0..acc.len]});
    try std.io.getStdOut().writer().print("part1: {}\n", .{magnitude(acc.buf[0..acc.len])});

    var best_mag: u64 = 0;
    for (nums.items) |_, i| {
        for (nums.items) |_, j| {
            if (i != j) {
                var acc1 = Number.init(nums.items[i].buf[0..nums.items[i].len]);
                try acc1.add(&nums.items[j]);
                const mag = try magnitude(acc1.buf[0..acc1.len]);
                if (mag > best_mag) {
                    best_mag = mag;
                }
            }
        }
    }
    try std.io.getStdOut().writer().print("part2: {}\n", .{best_mag});
}
