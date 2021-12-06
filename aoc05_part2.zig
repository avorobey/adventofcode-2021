const std = @import("std");
const expect = std.testing.expect;

pub const Line = struct {
  lbx: i16,
  lby: i16,
  rux: i16, 
  ruy: i16,
}; 

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc05.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [1024]u8 = undefined;
  var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};

  var lines = std.ArrayList(Line).init(&gpalloc.allocator);
  defer lines.deinit();
  while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    var iter = std.mem.tokenize(u8, line, " ,->");
    var l = Line{
      .lbx=try std.fmt.parseInt(i16, iter.next().?, 10),
      .lby=try std.fmt.parseInt(i16, iter.next().?, 10),
      .rux=try std.fmt.parseInt(i16, iter.next().?, 10),
      .ruy=try std.fmt.parseInt(i16, iter.next().?, 10),
    };
    try lines.append(l);
  }
  var x:isize = 0;
  var y:isize = 0;
  var pts_counter:u32 = 0;

  while (x < 1000) {
    y = 0;
    while (y < 1000) {
      var debug = false;
      var cnt:u32 = 0;
      for (lines.items) |l| {
        if (x == l.lbx and x == l.rux and ((l.lby <= y and y <= l.ruy) or (l.ruy <= y and y <= l.lby))) {
          if (debug) {
            std.debug.print("{}:{} on {}:{}->{}:{}\n", .{x,y,l.lbx,l.lby,l.rux,l.ruy});
          }
          cnt += 1; 
        } else if (y == l.lby and y == l.ruy and ((l.lbx <= x and x <= l.rux) or (l.rux <= x and x <= l.lbx))) {
          if (debug) {
            std.debug.print("{}:{} on {}:{}->{}:{}\n", .{x,y,l.lbx,l.lby,l.rux,l.ruy});
          }
          cnt += 1; 
        } else if (x - y == l.lbx - l.lby and
            ( (l.lbx <= x and x <= l.rux and l.lby <= y and y <= l.ruy) or
              (l.rux <= x and x <= l.lbx and l.ruy <= y and y <= l.lby))) {
          if (debug) {
            std.debug.print("{}:{} on {}:{}->{}:{}\n", .{x,y,l.lbx,l.lby,l.rux,l.ruy});
          }
          cnt += 1;
        } else if (x + y == l.lbx + l.lby and
            ( (l.lbx <= x and x <= l.rux and l.ruy <= y and y <= l.lby) or
              (l.rux <= x and x <= l.lbx and l.lby <= y and y <= l.ruy))) {
          if (debug) {
            std.debug.print("{}:{} on {}:{}->{}:{}\n", .{x,y,l.lbx,l.lby,l.rux,l.ruy});
          }
          cnt += 1;
        }
        if (cnt > 1) { break; }
      }
      if (debug) { std.debug.print("cnt: {}\n", .{cnt}); }
      if (cnt > 1) { 
        // std.debug.print("x={}, y={}, cnt={}\n", .{x,y,cnt});
        pts_counter += 1;
      }
      y += 1;
    }
    x += 1;
  }
  try std.io.getStdOut().writer().print("part2: {}\n", .{pts_counter});
}
