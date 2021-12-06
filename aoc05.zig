const std = @import("std");
const expect = std.testing.expect;

pub const Rect = struct {
  const Self = @This();
  // left bottom x,y, right upper x,y
  lbx: u16,
  lby: u16,
  rux: u16, 
  ruy: u16,
  fn init(x1:u16, y1:u16, x2:u16, y2:u16) Self {
    return Self{
      .lbx = @minimum(x1, x2),
      .lby = @minimum(y1, y2),
      .rux = @maximum(x1, x2),
      .ruy = @maximum(y1, y2),
    };
  }
  fn intersect(self: *const Rect, other: *const Rect) ?Rect {
    var lbx = @maximum(self.lbx, other.lbx);
    var lby = @maximum(self.lby, other.lby);
    var rux = @minimum(self.rux, other.rux);
    var ruy = @minimum(self.ruy, other.ruy);
    if (lbx <= rux and lby <= ruy) {
      return Rect{.lbx=lbx, .lby=lby, .rux=rux, .ruy=ruy};
    } else {
      return null;
    }
  }
  fn area(self: *const Rect) u64 {
    return @as(u64, self.rux-self.lbx+1)*@as(u64, self.ruy-self.lby+1);
  }
}; 

test "test part1" {
  var b1 = Rect.init(1,1,3,3);
  try expect(b1.area() == 9);
  var b2 = Rect.init(1,1,13,1);
  try expect(b2.area() == 13);
  var b3 = Rect.init(5,1,5,10);
  try expect(b3.area() == 10);
  try expect(b2.intersect(&b3).?.area() == 1);
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc05.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;
  var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};

  var rects = std.ArrayList(Rect).init(&gpalloc.allocator);
  defer rects.deinit();
  var intersects = std.ArrayList(Rect).init(&gpalloc.allocator);
  defer intersects.deinit();
  var sum:u64 = 0;
  while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    var iter = std.mem.tokenize(u8, line, " ,->");
    var rect = Rect.init(
      try std.fmt.parseInt(u16, iter.next().?, 10),
      try std.fmt.parseInt(u16, iter.next().?, 10),
      try std.fmt.parseInt(u16, iter.next().?, 10),
      try std.fmt.parseInt(u16, iter.next().?, 10));
    if (!(rect.lbx == rect.rux or rect.lby == rect.ruy)) {
      continue;
    }
    for (rects.items) |old_rect| {
      if (rect.intersect(&old_rect)) |intersection| {
        sum += intersection.area();
        for (intersects.items) |old_intersect| {
          if (intersection.intersect(&old_intersect)) |inter_inter| {
            sum -= inter_inter.area();
          }
        }
        try intersects.append(intersection);
      }
    }
    try rects.append(rect);
  }
  try std.io.getStdOut().writer().print("part1: {}\n", .{sum});
}
