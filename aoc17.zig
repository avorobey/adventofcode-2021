const std = @import("std");
const expect = std.testing.expect;

fn fitRange(a1: i32, a2: i32, steps: u8, res_1: *i32, res_2: *i32) bool {
    // If we start from A and do 'steps' steps downwards, we have overall
    // steps+1 numbers A,A-1,...,A-steps. The sum is (2A-steps)(steps+1)/2,
    // we need it to fit between a1 and a2.
    var a: i32 = @maximum(steps, a2);
    var sum: i32 = @divTrunc((2 * a - steps) * (steps + 1), 2);
    var found_end = false;
    var a_end: i32 = 0;
    while (sum >= a1) {
        if (sum <= a2 and !found_end) {
            a_end = a;
            found_end = true;
        }
        a -= 1;
        sum -= (steps + 1);
    }
    var a_start = a + 1;
    if (!found_end) {
        return false;
    } else {
        res_1.* = a_start;
        res_2.* = a_end;
        return true;
    }
}

fn prTuples(x: i32, y1: i32, y2: i32) void {
    var y = y1;
    while (y <= y2) {
        std.debug.print("{d},{d}\n", .{ x, y });
        y += 1;
    }
}

fn solveSteps(x1: i32, x2: i32, y1: i32, y2: i32, steps: u8) void {
    var y_start: i32 = undefined;
    var y_end: i32 = undefined;
    if (!fitRange(y1, y2, steps, &y_start, &y_end)) {
        return;
    }
    // std.debug.print("steps {d}: {d} -> {d}\n", .{ steps, y_start, y_end });

    var x_start: i32 = undefined;
    var x_end: i32 = undefined;
    var found_x_range = fitRange(x1, x2, steps, &x_start, &x_end);
    if (found_x_range) {
        //std.debug.print("xrange {d}: {d} -> {d}\n", .{ steps, x_start, x_end });
        var x = x_start;
        while (x <= x_end) {
            if (x >= steps) {
                prTuples(x, y_start, y_end);
            }
            x += 1;
        }
    }

    // Now also try to fit X's where X < steps and stops at 0.
    var sum: i32 = 0;
    var x_cand: i32 = 1;
    while (x_cand <= steps) {
        sum += x_cand;
        if (sum >= x1 and sum <= x2) {
            prTuples(x_cand, y_start, y_end);
        }
        x_cand += 1;
    }
}

fn solve(x1: i32, x2: i32, y1: i32, y2: i32) void {
    var steps: u8 = 0;
    // We assume that x1,x2 are positive for simplicity.
    while (steps < 255) {
        solveSteps(x1, x2, y1, y2, steps);
        steps += 1;
    }
}

pub fn main() anyerror!void {
    // I solved part1 without any code. If the y range is large negative and
    // the x range is smaller positive, as in my puzzle input, the best answer
    // in part1 will start with a positive Y, go through Y,Y-1,...,0,-1,...-Y,
    // and then just hit the lower edge of the target area at -Y-1; the X
    // value will long stabilize by then. For my range -122..-74, Y=121 is the
    // highest that'll work, so the answer is 121*122/2=7381.

    // Now for part2. Run the below, capture the output and pipe through
    // sort|uniq.
    //solve(20, 30, -10, -5);
    solve(185, 221, -122, -74);
}
