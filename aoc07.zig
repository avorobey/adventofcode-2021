const std = @import("std");
const expect = std.testing.expect;

fn tri_dist(x:u16, y:u16) u64 {
  var len = @as(u64, @maximum(x,y) - @minimum(x,y));
  return len*(len+1)/2;
}

fn list_dist(x:u16, list:[] const u16) u64 {
  var sum:u64 = 0;
  for (list) |item| {
    sum += tri_dist(x, item);
  }
  return sum;
}

pub fn main() anyerror!void {
  var file = try std.fs.cwd().openFile("aoc07.input", .{});
  defer file.close();
  var buf_reader = std.io.bufferedReader(file.reader());
  var in_stream = buf_reader.reader();
  var buf: [10240]u8 = undefined;

  var arr: [1000]u16 = undefined;
  var len:usize = 0;
  const opt_first_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
  var iter = std.mem.tokenize(u8, opt_first_line.?, ",");
  while (iter.next()) |token| {
    arr[len] = try std.fmt.parseInt(u16, token, 10);
    len += 1;
  }
  std.sort.sort(u16, arr[0..len], {}, comptime std.sort.asc(u16));
  var med_index:usize = len/2;
  var med = arr[med_index];
  var cnt:usize = 0;
  var sum:u64 = 0;
  while (cnt < len) {
    if (cnt < med_index) {
      sum += med - arr[cnt];
    } else {
      sum += arr[cnt] - med;
    }
    cnt += 1;
  }
  std.debug.print("part1: {}\n", .{sum});

  var first:u16 = arr[0];
  var last:u16 = arr[len-1];
  var i = first;
  var champ:u64 = list_dist(i, arr[0..len]);
  while (i < last) {
    var new = list_dist(i, arr[0..len]);
    if (new < champ) {
      champ = new;
    }
    i += 1;
  }
  std.debug.print("part2: {}\n", .{champ});
}
