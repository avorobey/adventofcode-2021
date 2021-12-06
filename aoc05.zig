const std = @import("std");
const expect = std.testing.expect;

pub const Rect = struct {
  const Self = @This();
  // left bottom x,y, right upper x,y
  lbx: i16,
  lby: i16,
  rux: i16, 
  ruy: i16,
  inum: i16, // intersection number, starts with 1
  fn init(x1:i16, y1:i16, x2:i16, y2:i16) Self {
    return Self{
      .lbx = @minimum(x1, x2),
      .lby = @minimum(y1, y2),
      .rux = @maximum(x1, x2),
      .ruy = @maximum(y1, y2),
      .inum = 1,
    };
  }
  fn maybeInit(lbx:i16, lby:i16, rux:i16, ruy:i16, inum:i16) ?Self {
    if (lbx > rux or lby > ruy) {
      return null;
    } else {
      return Self {.lbx=lbx, .lby=lby, .rux=rux, .ruy=ruy, .inum=inum};
    }
  }
  fn intersect(self: *const Rect, other: *const Rect) ?Rect {
    var lbx = @maximum(self.lbx, other.lbx);
    var lby = @maximum(self.lby, other.lby);
    var rux = @minimum(self.rux, other.rux);
    var ruy = @minimum(self.ruy, other.ruy);
    if (lbx <= rux and lby <= ruy) {
      return Rect{.lbx=lbx, .lby=lby, .rux=rux, .ruy=ruy, .inum = self.inum + other.inum};
    } else {
      return null;
    }
  }
  // Subtract other from self - intersection must be nonempty - and adds pieces to list.
  fn subtractAndAppend(self: *const Rect, other: *const Rect, list: *std.ArrayList(Rect)) !void {
    var inter = self.intersect(other).?;
    if (maybeInit(self.lbx, self.lby, inter.lbx-1, inter.lby-1, self.inum)) |rect| {
      try list.append(rect);
    }
    if (maybeInit(self.lbx, inter.lby, inter.lbx-1, inter.ruy, self.inum)) |rect| {
      try list.append(rect);
    }
    if (maybeInit(self.lbx, inter.ruy+1, inter.lbx-1, self.ruy, self.inum)) |rect| {
      try list.append(rect);
    }
    if (maybeInit(inter.lbx, self.lby, inter.rux, inter.lby-1, self.inum)) |rect| {
      try list.append(rect);
    }
    if (maybeInit(inter.lbx, inter.ruy+1, inter.rux, self.ruy, self.inum)) |rect| {
      try list.append(rect);
    }
    if (maybeInit(inter.rux+1, self.lby, self.rux, inter.lby-1, self.inum)) |rect| {
      try list.append(rect);
    }
    if (maybeInit(inter.rux+1, inter.lby, self.rux, inter.ruy, self.inum)) |rect| {
      try list.append(rect);
    }
    if (maybeInit(inter.rux+1, inter.ruy+1, self.rux, self.ruy, self.inum)) |rect| {
      try list.append(rect);
    }
  }
  fn area(self: *const Rect) i64 {
    return @as(i64, self.rux-self.lbx+1)*@as(i64, self.ruy-self.lby+1);
  }
}; 

fn addToDisjointList(list: *std.ArrayList(Rect), new: *std.ArrayList(Rect)) !void {
  var i:usize = 0;
  while (i < new.items.len) {
    var j:usize = 0;
    while (j < list.items.len) {
      if (i >= new.items.len) {
        break;
      }
      if (list.items[j].intersect(&new.items[i])) |inter| {
        var olditem = list.items[j];
        var newitem = new.items[i];
        try olditem.subtractAndAppend(&inter, list);
        try list.append(inter);
        _ = list.swapRemove(j);
        try newitem.subtractAndAppend(&inter, new);
        _ = new.swapRemove(i);
      } else {
        j += 1;
      }
    }
    i += 1;
  }
  try list.appendSlice(new.items);
}

fn multiple(list: *std.ArrayList(Rect)) i64 {
  var sum:i64 = 0;
  for (list.items) |rect| {
    if (rect.inum > 1) {
      sum += rect.area();
    }
  }
  return sum;
}

fn dumpRects(list: *std.ArrayList(Rect)) void {
  std.debug.print("---\n", .{});
  for (list.items) |rect| {
    std.debug.print("rect [{}]: {}:{} -> {}:{}\n", .{rect.inum, rect.lbx, rect.lby, rect.rux, rect.ruy});
  }
  std.debug.print("---\n", .{});
}

test "basic Rect" {
  var b1 = Rect.init(1,1,3,3);
  try expect(b1.area() == 9);
  var b2 = Rect.init(1,1,13,1);
  try expect(b2.area() == 13);
  var b3 = Rect.init(5,1,5,10);
  try expect(b3.area() == 10);
  try expect(b2.intersect(&b3).?.area() == 1);
}

test "addToDisjoint" {
  var rects = std.ArrayList(Rect).init(std.testing.allocator);
  defer rects.deinit();
  var new_rects = std.ArrayList(Rect).init(std.testing.allocator);
  defer new_rects.deinit();
  var b1 = Rect.init(1,1,3,3);
  try rects.append(b1);
  var b2 = Rect.init(2,2,2,2);
  try new_rects.append(b2);
  try addToDisjointList(&rects, &new_rects); 
  try expect(multiple(&rects) == 1);

  dumpRects(&rects);

  new_rects.clearAndFree();
  try new_rects.append(Rect.init(2,1,2,3));
  try addToDisjointList(&rects, &new_rects); 
  dumpRects(&rects);

  new_rects.clearAndFree();
  try new_rects.append(Rect.init(1,2,3,2));
  try addToDisjointList(&rects, &new_rects); 
  dumpRects(&rects);

  std.debug.print("{}\n", .{multiple(&rects)});
  try expect(multiple(&rects) == 5);
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
  var new_rects = std.ArrayList(Rect).init(&gpalloc.allocator);
  defer new_rects.deinit();
  while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    var iter = std.mem.tokenize(u8, line, " ,->");
    var rect = Rect.init(
      try std.fmt.parseInt(i16, iter.next().?, 10),
      try std.fmt.parseInt(i16, iter.next().?, 10),
      try std.fmt.parseInt(i16, iter.next().?, 10),
      try std.fmt.parseInt(i16, iter.next().?, 10));
    if (!(rect.lbx == rect.rux or rect.lby == rect.ruy)) {
      continue;
    }
    std.debug.print("line:{s}\n", .{line});
    std.debug.print("rects size:{}\n", .{rects.items.len});
    std.debug.print("new size:{}\n", .{new_rects.items.len});
    new_rects.clearAndFree();
    try new_rects.append(rect);
    try addToDisjointList(&rects, &new_rects);
  }
  try std.io.getStdOut().writer().print("part1: {}\n", .{multiple(&rects)});
}
