const std = @import("std");
const expect = std.testing.expect;

fn countIncreases(ar: []i16) u16 {
  var prev:i16 = 0;
  var cnt:u16 = 0;
  for (ar) |depth, index| {
    if (index != 0 and depth > prev) {
      cnt += 1;
    }
    prev = depth;
  }
  return cnt;
}

test "test" {
  var a1 = [_]i16{1,2,3};
  var a2 = [_]i16{100, 95, 93, 98, 200, 1};
  var a3 = [_]i16{0, 0, 0};
  var a4 = [_]i16{12, 14, 12, 14};
  try expect(countIncreases(a1[0..])==2);
  try expect(countIncreases(a2[0..])==2);
  try expect(countIncreases(a3[0..])==0);
  try expect(countIncreases(a4[0..])==2);
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc01.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;
  var depths  = [_]i16{0} ** 3000;
  var cur:u16 = 0;
  while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    const num:i16 = try std.fmt.parseInt(i16, line, 10);
    depths[cur] = num;
    cur += 1;
  }
  const res:u16 = countIncreases(depths[0..cur]);
  try std.io.getStdOut().writer().print("{}\n", .{res});
}
