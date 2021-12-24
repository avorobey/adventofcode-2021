const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

var vars = [_]i64{0} ** 4;

pub const Inst = struct {
    // 1 inp, 2 add, 3 mul, 4 div, 5 mod, 6 eql
    op: u8,
    v: u8, // index into vars
    opvar: ?u8, // index into vars
    opimm: ?i64,
};

var program: [300]Inst = undefined;
var p_len: usize = 0;

fn prz() void {
    var buf: [10]u8 = undefined;
    var blen: usize = 0;
    var z = vars[3];
    while (true) {
        buf[blen] = @intCast(u8, @mod(z, 26)) + 'A';
        blen += 1;
        z = @divTrunc(z, 26);
        if (z == 0) {
            break;
        }
    }
    var len = blen;
    print("z: ", .{});
    while (len > 0) {
        print("{c}", .{buf[len - 1]});
        len -= 1;
    }
    print("\n", .{});
}

fn run(inp: []const u8, failing_index: *u8, failing_comparison: *i64) bool {
    _ = failing_index;
    _ = failing_comparison;
    vars[0] = 0;
    vars[1] = 0;
    vars[2] = 0;
    vars[3] = 0;
    var inp_ind: u8 = 0;
    var always_equal = true;
    for (program[0..p_len]) |in, i| {
        var val: i64 = 0;
        if (in.op != 1) {
            if (in.opvar) |v| {
                val = vars[v];
            } else {
                val = in.opimm.?;
            }
        }
        switch (in.op) {
            1 => {
                vars[in.v] = inp[inp_ind] - '0';
                inp_ind += 1;
                //print("index: {d} z mod 26: {d} incoming value: {d} next adjustment: {d} prev comparison: {}\n", .{ inp_ind, @mod(vars[3], 26), vars[0], next_inc, inc });
                //prz();
            },
            2 => {
                vars[in.v] += val;
            },
            3 => {
                vars[in.v] *= val;
            },
            4 => {
                vars[in.v] = @divTrunc(vars[in.v], val);
            },
            5 => {
                vars[in.v] = @mod(vars[in.v], val);
            },
            6 => {
                if (in.opvar) |_| {
                    // the next condition zeroes in 'eql x w' that always comes after
                    // 'add x NUM'. We want to catch a case when this check fails, catch
                    // only the first time it happens, and only when the NUM that was added
                    // in the previous instruction was negative.
                    if (vars[in.v] != val and always_equal and program[i - 1].opimm.? < 0) {
                        always_equal = false;
                        failing_index.* = inp_ind - 1;
                        failing_comparison.* = vars[in.v];
                    }
                    //print("compared: {d} ?= {d}\n", .{ vars[in.v], val });
                }
                vars[in.v] = if (vars[in.v] == val) 1 else 0;
            },
            else => {
                @panic("else\n");
            },
        }
    }
    return always_equal;
}

fn update(num: *[7]u8, increase: bool) bool {
    var ind: u8 = 6;
    while (true) {
        if (increase) {
            num[ind] += 1;
        } else {
            num[ind] -= 1;
        }
        if (num[ind] < '1' or num[ind] > '9') {
            if (ind == 0) {
                return false;
            }
            num[ind] = if (increase) '1' else '9';
            ind -= 1;
        } else {
            return true;
        }
    }
}

fn copy7to14(num1: *[7]u8, num2: *[14]u8) void {
    num2[0] = num1[0];
    num2[1] = num1[1];
    num2[2] = num1[2];
    num2[3] = num1[3];
    num2[4] = num1[4];
    num2[5] = '1';
    num2[6] = num1[5];
    num2[7] = '1';
    num2[8] = '1';
    num2[9] = num1[6];
    num2[10] = '1';
    num2[11] = '1';
    num2[12] = '1';
    num2[13] = '1';
}

var seven = [_]u8{0} ** 7;
var fourteen = [_]u8{0} ** 14;

fn find(increase: bool) bool {
    // The general number has 14 digits, indices 0 through 13.
    // We vary those with 'positive' increments in the program, those are 0,1,2,3,4,6,9.
    // For each value from 9999999 to 1111111 for those, we try to find digits for the
    // other indices 5,7,8,10,11,12,13. Each index is fixed by the necessity to make the
    // 'eql' check in the program zero. We repeatedly call run() and it tells us the first
    // failing comparison and the necessary number to put there. If it's not from 1 to 9,
    // we fail this value of the initial 7 indices. If we fix all 7 successfully and the
    // value of z is still not 0 (not sure it's possible), we still fail and try the next
    // one. When we find the values that bring to z=0, we're done.

    for (seven[0..]) |_, i| {
        if (increase) {
            seven[i] = '1';
        } else {
            seven[i] = '9';
        }
    }

    while (true) {
        copy7to14(&seven, &fourteen);
        //print("trying: {s}\n", .{fourteen[0..]});
        var failing_comparison: i64 = 0;
        var failing_index: u8 = 0;
        while (!run(fourteen[0..], &failing_index, &failing_comparison)) {
            //print("failed on index: {d}, wants: {d}\n", .{ failing_index, failing_comparison });
            if (failing_comparison >= 1 and failing_comparison <= 9) {
                fourteen[failing_index] = @intCast(u8, failing_comparison) + '0';
                continue;
            }
            break;
        }
        if (vars[3] == 0) {
            break;
        }
        if (!update(&seven, increase)) {
            break;
        }
    }
    return vars[3] == 0;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc24.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var op: u8 = 0;
        var opvar: ?u8 = null;
        var opimm: ?i64 = null;

        if (std.mem.eql(u8, line[0..3], "inp")) {
            op = 1;
        } else if (std.mem.eql(u8, line[0..3], "add")) {
            op = 2;
        } else if (std.mem.eql(u8, line[0..3], "mul")) {
            op = 3;
        } else if (std.mem.eql(u8, line[0..3], "div")) {
            op = 4;
        } else if (std.mem.eql(u8, line[0..3], "mod")) {
            op = 5;
        } else if (std.mem.eql(u8, line[0..3], "eql")) {
            op = 6;
        } else {
            @panic("Bad op");
        }
        const v: u8 = line[4] - 'w';
        if (op != 1) {
            if (line[6] >= 'w' and line[6] <= 'z') {
                opvar = line[6] - 'w';
            } else {
                opimm = try std.fmt.parseInt(i64, line[6..], 10);
            }
        }
        program[p_len] = Inst{ .op = op, .v = v, .opvar = opvar, .opimm = opimm };
        p_len += 1;
    }

    if (find(false)) {
        print("part1: {s}\n", .{fourteen[0..]});
    } else {
        print("part1: unable to find!\n", .{});
    }
    if (find(true)) {
        print("part2: {s}\n", .{fourteen[0..]});
    } else {
        print("part2: unable to find!\n", .{});
    }
}
