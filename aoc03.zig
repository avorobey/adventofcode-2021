const std = @import("std");
const expect = std.testing.expect;

pub const Data = struct {
  counters: []i16,  // counters.len must start out correct
  fn processLine(self: *Data, line: []const u8) void {
    for (line) |char, index| {
      if (char == '1') {
        self.counters[index] += 1;
      } else {
        self.counters[index] -= 1;
      }
    }
  }
  fn getResult(self: *Data) u64 {
    var buf_most = [_]u8{0} ** 1000;
    var buf_least = [_]u8{0} ** 1000;
    var slice_most = buf_most[buf_most.len-self.counters.len..buf_most.len];
    var slice_least = buf_least[buf_most.len-self.counters.len..buf_most.len];
    for (self.counters) |value, index| {
      if (value > 0) {
        slice_most[index] = '1';
        slice_least[index] = '0';
      } else {
        slice_most[index] = '0';
        slice_least[index] = '1';
      }
    }
    const most = std.fmt.parseInt(u64, slice_most, 2) catch 0;
    const least = std.fmt.parseInt(u64, slice_least, 2) catch 0;
    return most*least;
  }
};

test "test part1" {
  var counters = [_]i16{0} ** 3;
  var d1 = Data{
    .counters = counters[0..],
  };
  d1.processLine("001");
  d1.processLine("110");
  d1.processLine("011");
  try expect(d1.getResult() == 12);
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc03.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;

  var data = Data {
    .counters = undefined,
  };
  var data_buf = [_]i16{0} ** 1000;
  var defined = false;
  while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    if (!defined) {
      data.counters = data_buf[data_buf.len-line.len..data_buf.len];
      defined = true;
    }
    data.processLine(line);
  }
  try std.io.getStdOut().writer().print("part1: {}\n", .{data.getResult()});
}
