const std = @import("std");
const expect = std.testing.expect;

var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};

var names: [15][]u8 = undefined;
var name_len: u8 = 0;
var large = [_]bool{false} ** 15;
var start_ind: u8 = 0;
var end_ind: u8 = 0;
fn stateNum(state_name: []const u8) u8 {
    for (names[0..name_len]) |val, ind| {
        if (std.mem.eql(u8, state_name, val)) {
            return @intCast(u8, ind);
        }
    }
    names[name_len] = gpalloc.allocator.dupe(u8, state_name) catch "";
    if (std.mem.eql(u8, state_name, "start")) {
        start_ind = name_len;
    }
    if (std.mem.eql(u8, state_name, "end")) {
        end_ind = name_len;
    }
    if (state_name[0] >= 'A' and state_name[0] <= 'Z') {
        large[name_len] = true;
    }
    name_len += 1;
    return name_len - 1;
}

test "stateNum" {
    try expect(stateNum("start") == 0);
    try expect(stateNum("s1") == 1);
    try expect(stateNum("start") == 0);
    try expect(stateNum("S1") == 2);
    try expect(stateNum("s1") == 1);
}

var board = [_][15]bool{[_]bool{false} ** 15} ** 15;
fn processEdge(edge: []const u8) void {
    var iter = std.mem.tokenize(u8, edge, "-");
    var src_ind: u8 = undefined;
    var dst_ind: u8 = undefined;
    if (iter.next()) |src| {
        src_ind = stateNum(src);
    } else {
        @panic("no src");
    }
    if (iter.next()) |dst| {
        dst_ind = stateNum(dst);
    } else {
        @panic("no dst");
    }
    board[src_ind][dst_ind] = true;
    board[dst_ind][src_ind] = true;
}

var visited = [_]bool{false} ** 15;
fn countPathsRec(curr_ind: u8, cnt: *u16) void {
    // std.debug.print("At: {s}\n", .{names[curr_ind]});
    if (curr_ind == end_ind) {
        cnt.* += 1;
        return;
    }
    for (board[curr_ind]) |val, next_ind| {
        if (val) {
            // std.debug.print("considering: {s}->{s}, visited:{}\n", .{ names[curr_ind], names[next_ind], visited[next_ind] });
        }
        if (val and !visited[next_ind]) {
            if (!large[next_ind]) {
                visited[next_ind] = true;
            }
            // std.debug.print("recursing to: {s}\n", .{names[next_ind]});
            countPathsRec(@intCast(u8, next_ind), cnt);
            visited[next_ind] = false;
        }
    }
    return;
}

fn countPaths() u16 {
    visited[start_ind] = true;
    var cnt: u16 = 0;
    countPathsRec(start_ind, &cnt);
    return cnt;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc12.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        processEdge(line);
    }
    try std.io.getStdOut().writer().print("part1: {d}\n", .{countPaths()});
}
