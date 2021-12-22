const std = @import("std");
const expect = std.testing.expect;

const scores = [21]u8{ 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 };
const ten = [10]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
const three = [3]u8{ 1, 2, 3 };
const binary = [2]u8{ 0, 1 };

pub fn main() anyerror!void {
    var uni: [21][21][10][10][2][2]u64 = undefined;

    for (scores) |s1| {
        for (scores) |s2| {
            for (ten) |p1| {
                for (ten) |p2| {
                    for (binary) |turn| {
                        uni[s1][s2][p1][p2][turn][0] = 0;
                        uni[s1][s2][p1][p2][turn][1] = 0;
                        for (three) |die1| {
                            for (three) |die2| {
                                for (three) |die3| {
                                    if (turn == 0) {
                                        const new_p1 = (p1 + die1 + die2 + die3) % 10;
                                        const new_s1 = s1 + new_p1 + 1;
                                        if (new_s1 >= 21) {
                                            uni[s1][s2][p1][p2][turn][0] += 1;
                                        } else {
                                            uni[s1][s2][p1][p2][turn][0] += uni[new_s1][s2][new_p1][p2][1 - turn][0];
                                            uni[s1][s2][p1][p2][turn][1] += uni[new_s1][s2][new_p1][p2][1 - turn][1];
                                        }
                                    } else {
                                        const new_p2 = (p2 + die1 + die2 + die3) % 10;
                                        const new_s2 = s2 + new_p2 + 1;
                                        if (new_s2 >= 21) {
                                            uni[s1][s2][p1][p2][turn][1] += 1;
                                        } else {
                                            uni[s1][s2][p1][p2][turn][0] += uni[s1][new_s2][p1][new_p2][1 - turn][0];
                                            uni[s1][s2][p1][p2][turn][1] += uni[s1][new_s2][p1][new_p2][1 - turn][1];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    try std.io.getStdOut().writer().print("part2 sample: {d}:{d}\n", .{ uni[0][0][3][7][0][0], uni[0][0][3][7][0][1] });
    try std.io.getStdOut().writer().print("part2 real: {d}:{d}\n", .{ uni[0][0][6][1][0][0], uni[0][0][6][1][0][1] });
}
