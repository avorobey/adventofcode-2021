const std = @import("std");
const expect = std.testing.expect;

fn advance(fish: *std.ArrayList(u16)) !void {
  var new:u64 = 0;
  for (fish.items) |val, index| {
    if (val == 0) {
      fish.items[index] = 6; new += 1;
    } else {
      fish.items[index] = val-1;
    }
  }
  while (new > 0) {
    try fish.append(8);
    new -= 1;
  }
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc06.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;
  var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};

  var fish = std.ArrayList(u16).init(&gpalloc.allocator);
  defer fish.deinit();

  var line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
  var iter = std.mem.tokenize(u8, line.?, ",");
  while (iter.next()) |token| {
    try fish.append(try std.fmt.parseInt(u16, token, 10));
  }
  var cnt:u16 = 80;
  while (cnt > 0) {
    try advance(&fish);
    cnt -= 1;
  }
  try std.io.getStdOut().writer().print("part1: {}\n", .{fish.items.len});
}
