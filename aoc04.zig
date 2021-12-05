const std = @import("std");
const expect = std.testing.expect;

pub const Board = struct {
  nums: [25]?u16,
  fn processNum(self: *Board, num: u16) void {
    for (self.nums) |val, index| {
      if (val == num) {
        self.nums[index] = null;
      }
    }
  }
  fn isBingo(self: *Board) bool {
    var i:usize = 0;
    while (i < 5) {
      var j:usize = 0;
      var bingo = true;
      while (j < 5) {
        if (self.nums[i*5+j] != null) { bingo = false; }
        j += 1;
      }
      if (bingo) { return true; }
      bingo = true;
      j = 0;
      while (j < 5) {
        if (self.nums[i+5*j] != null) { bingo = false; }
        j += 1;
      }
      if (bingo) { return true; }
      i += 1;
    }
    return false;
  }
  fn unmarkedSum(self: *Board) u16 {
    var sum:u16 = 0;
    for (self.nums) |val| {
      if (val) |v| {
        sum += v;
      }
    }
    return sum;
  }
};

test "test part1" {
  var b1 = Board{
    .nums = .{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25},
  };
  b1.processNum(1);
  try expect(b1.isBingo() == false);
  b1.processNum(2);
  b1.processNum(3);
  b1.processNum(4);
  try expect(b1.isBingo() == false);
  b1.processNum(5);
  try expect(b1.isBingo() == true);
  var b2 = Board{
    .nums = .{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25},
  };
  b2.processNum(3);
  b2.processNum(8);
  b2.processNum(13);
  b2.processNum(18);
  try expect(b2.isBingo() == false);
  b2.processNum(23);
  try expect(b2.isBingo() == true);
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc04.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;
  var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};

  const opt_first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
  const first_line = try gpalloc.allocator.dupe(u8, opt_first_line orelse "");

  var boards = std.ArrayList(Board).init(&gpalloc.allocator);
  defer boards.deinit();

  while (true) {
    const empty_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    if (empty_line == null) {
      break;
    } else {
      var nums = [_]?u16{0}**25; 
      var index:usize = 0;
      var linecount:usize = 0;
      while (linecount < 5) {
        const opt_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
        const line = opt_line orelse "";
        var iter = std.mem.tokenize(u8, line, " ");
        while (iter.next()) |token| {
          const num = try std.fmt.parseInt(u16, token, 10);
          nums[index] = num;
          index += 1;
        }
        linecount += 1;
      }
      var board = Board{.nums = nums};
      try boards.append(board);
    }
  }

  var iter = std.mem.tokenize(u8, first_line, ",");
  var done = false;
  while (iter.next()) |token| {
    const num = try std.fmt.parseInt(u16, token, 10);
    for (boards.items) |_, index| {
      boards.items[index].processNum(num);
      if (boards.items[index].isBingo()) {
        std.debug.print("part1: {}\n", .{boards.items[index].unmarkedSum()*num});
        done = true;
        break;
      }
    }
    if (done) {
      break;
    }
  }
}
