const std = @import("std");
const expect = std.testing.expect;

pub const Die = struct {
    rolls: u16 = 0,
    pos: u16 = 0,
    fn roll(self: *Die) u16 {
        self.rolls += 1;
        self.pos += 1;
        if (self.pos > 100) {
            self.pos -= 100;
        }
        return self.pos;
    }
};

pub const Board = struct {
    p1: u16 = 0,
    p2: u16 = 0,
    score1: u16 = 0,
    score2: u16 = 0,
    die: Die = Die{},
    fn step(self: *Board) void {
        // std.debug.print("before {d} {d}\n", .{ self.score1, self.score2 });
        // std.debug.print("old self.p1 is {d}\n", .{self.p1});
        self.p1 += self.die.roll() + self.die.roll() + self.die.roll();
        // std.debug.print("new self.p1 is {d}\n", .{self.p1});
        self.p1 = (self.p1 - 1) % 10 + 1;
        self.score1 += self.p1;
        if (self.score1 >= 1000) {
            return;
        }
        self.p2 += self.die.roll() + self.die.roll() + self.die.roll();
        self.p2 = (self.p2 - 1) % 10 + 1;
        self.score2 += self.p2;
        // std.debug.print("after {d} {d}\n", .{ self.score1, self.score2 });
    }
};

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc21.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var opt_line1 = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var line1 = opt_line1.?;
    var pos1 = try std.fmt.parseInt(u16, line1[line1.len - 1 .. line1.len], 10);
    var opt_line2 = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    var line2 = opt_line2.?;
    var pos2 = try std.fmt.parseInt(u16, line2[line2.len - 1 .. line2.len], 10);
    var board = Board{ .p1 = pos1, .p2 = pos2 };

    var loser: u16 = 0;
    while (true) {
        board.step();
        if (board.score1 >= 1000) {
            loser = board.score2;
            break;
        } else if (board.score2 >= 1000) {
            loser = board.score1;
            break;
        }
    }
    var score = @intCast(u32, loser) * board.die.rolls;
    try std.io.getStdOut().writer().print("part1: {}\n", .{score});
}
