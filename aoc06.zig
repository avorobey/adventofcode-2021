const std = @import("std");
const expect = std.testing.expect;

fn advance(fish: *[9]u64) !void {
  var mothers = fish[0];
  fish[0] = fish[1];
  fish[1] = fish[2];
  fish[2] = fish[3];
  fish[3] = fish[4];
  fish[4] = fish[5];
  fish[5] = fish[6];
  fish[6] = fish[7];
  fish[7] = fish[8];
  fish[6] += mothers;
  fish[8] = mothers;
}

fn sumfish(fish: *[9]u64) u64 {
  var index:u16 = 0; var sum:u64 = 0;
  while (index < 9) {
    sum += fish[index];
    index += 1;
  }
  return sum;
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc06.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;

  var fish = [_]u64{0} ** 9;

  var line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
  var iter = std.mem.tokenize(u8, line.?, ",");
  while (iter.next()) |token| {
    fish[try std.fmt.parseInt(u16, token, 10)] += 1;
  }
  var cnt:u16 = 80;
  while (cnt > 0) {
    try advance(&fish);
    cnt -= 1;
  }
  try std.io.getStdOut().writer().print("part1: {}\n", .{sumfish(&fish)});
  cnt = 256-80;
  while (cnt > 0) {
    try advance(&fish);
    cnt -= 1;
  }
  try std.io.getStdOut().writer().print("part2: {}\n", .{sumfish(&fish)});
}
