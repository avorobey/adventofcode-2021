const std = @import("std");
const expect = std.testing.expect;

pub const Data = struct {
  map: std.StringHashMap(u16),
  fn processLine(self: *Data, line: []const u8) anyerror!void {
    for (line) |_, index| {
      const key = line[0..index+1];
      const opt_value = self.map.get(line[0..index+1]);
      if (opt_value) |value| {
        try self.map.put(key, value+1);
      } else {
        try self.map.put(key, 1);
      }
    }
  }
  fn getResult(self: *Data, most: bool) !u64 {
    var done = false;
    var buf = [_]u8{0} ** 100;
    var end:usize = 0;  // buf[0..end] is the current bitstring
    while (!done) {
      buf[end] = '1'; const opt_1 = self.map.get(buf[0..end+1]);
      buf[end] = '0'; const opt_0 = self.map.get(buf[0..end+1]);
      var val_1 = opt_1 orelse 0;
      var val_0 = opt_0 orelse 0;
      if (val_1 == 0 and val_0 == 0) {
        done = true;
      } else {
        // if (val_0 == 0 or (val_1 != 0 and ((val_1 >= val_0) == most))) {
        // the above condition took care of when to append '1' in one if, but
        // isn't readable.
        if (val_0 == 0) {
          buf[end] = '1';
        } else if (val_1 == 0) {
          buf[end] = '0';
        } else {  // both nonzero
          if ((val_1 >= val_0) == most) {
            buf[end] = '1';
          } else {
            buf[end] = '0';
          }
        }
        end += 1;
      }
    }
    return try std.fmt.parseInt(u16, buf[0..end], 2);
  }
};

test "test part1" {
  var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
  var map = std.StringHashMap(u16).init(&gpalloc.allocator);
  defer map.deinit();
  var d1 = Data{
    .map = map,
  };
  try d1.processLine("001");
  try d1.processLine("000");
  try d1.processLine("110");
  try d1.processLine("011");
  try expect(d1.getResult(true) catch 0 == 1);
  try expect(d1.getResult(false) catch 0 == 6);
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc03.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;

  var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
  var map = std.StringHashMap(u16).init(&gpalloc.allocator);
  defer map.deinit();
  var data = Data{
    .map = map,
  };
  while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    // StringHashMap holds its keys as slices, so we need to make them unique.
    // In a proper program we'd keep track of these dupes and free them.
    var dline = try gpalloc.allocator.dupe(u8, line);
    try data.processLine(dline);
  }
  var most = data.getResult(true) catch 0;
  var least = data.getResult(false) catch 0;

  try std.io.getStdOut().writer().print("part2: {}\n", .{most*least});
}
