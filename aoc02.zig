const std = @import("std");
const expect = std.testing.expect;

const forward = "forward ";
const down = "down ";
const up = "up ";

pub const Data = struct {
  depth: u64,
  horiz: u64,
  fn processInstruction(self: *Data, ins: []const u8) anyerror!void {
    if (std.mem.startsWith(u8, ins, forward)) {
      self.horiz += try std.fmt.parseInt(u64, ins[forward.len..], 10);
    }
    if (std.mem.startsWith(u8, ins, down)) {
      self.depth += try std.fmt.parseInt(u64, ins[down.len..], 10);
    }
    if (std.mem.startsWith(u8, ins, up)) {
      self.depth -= try std.fmt.parseInt(u64, ins[up.len..], 10);
    }
  }
};

pub const DataPart2 = struct {
  depth: u64,
  horiz: u64,
  aim: u64,
  fn processInstruction(self: *DataPart2, ins: []const u8) anyerror!void {
    if (std.mem.startsWith(u8, ins, forward)) {
      const x = try std.fmt.parseInt(u64, ins[forward.len..], 10);
      self.horiz += x;
      self.depth += x*self.aim;
    }
    if (std.mem.startsWith(u8, ins, down)) {
      self.aim += try std.fmt.parseInt(u64, ins[down.len..], 10);
    }
    if (std.mem.startsWith(u8, ins, up)) {
      self.aim -= try std.fmt.parseInt(u64, ins[up.len..], 10);
    }
  }
};

test "test part1" {
  var d1 = Data{
    .depth = 0,
    .horiz = 0,
  };
  try d1.processInstruction("forward 13");
  try expect(d1.horiz == 13);
  try expect(d1.depth == 0);
  try d1.processInstruction("down 5");
  try expect(d1.horiz == 13);
  try expect(d1.depth == 5);
  try d1.processInstruction("forward 10");
  try expect(d1.horiz == 23);
  try expect(d1.depth == 5);
  try d1.processInstruction("up 4");
  try expect(d1.horiz == 23);
  try expect(d1.depth == 1);
}

test "test part2" {
  var d1 = DataPart2{
    .depth = 0,
    .horiz = 0,
    .aim = 0,
  };
  try d1.processInstruction("forward 13");
  try expect(d1.horiz == 13);
  try expect(d1.depth == 0);
  try expect(d1.aim == 0);
  try d1.processInstruction("down 5");
  try expect(d1.horiz == 13);
  try expect(d1.depth == 0);
  try expect(d1.aim == 5);
  try d1.processInstruction("forward 10");
  try expect(d1.horiz == 23);
  try expect(d1.depth == 50);
  try expect(d1.aim == 5);
  try d1.processInstruction("up 4");
  try expect(d1.horiz == 23);
  try expect(d1.depth == 50);
  try expect(d1.aim == 1);
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc02.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;

  var data = Data{
    .depth = 0,
    .horiz = 0,
  };
  var data_part_2 = DataPart2{
    .depth = 0,
    .horiz = 0,
    .aim = 0,
  };
  while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    try data.processInstruction(line);
    try data_part_2.processInstruction(line);
  }
  try std.io.getStdOut().writer().print("part1: {}\n", .{data.depth*data.horiz});
  try std.io.getStdOut().writer().print("part2: {}\n", .{data_part_2.depth*data_part_2.horiz});
}
