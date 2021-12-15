const std = @import("std");
const expect = std.testing.expect;

fn present(letter: u8, str: []const u8) bool {
    return std.mem.indexOfScalar(u8, str, letter) != null;
}

test "present" {
    try expect(present('a', "abc"));
    try expect(present('a', "cba"));
    try expect(!present('a', ""));
    try expect(!present('a', "   "));
    try expect(!present('d', "abc cba"));
}

fn categorizeDigits(raw_digits: [10][]u8) [10][]u8 {
    var new_digits: [10][]u8 = undefined;

    // Categorize 1,4,7,8 using their known lengths.
    // The others go into 'sixes' and 'fives' according
    // to their lengths.
    var sixes: [3][]u8 = undefined;
    var fives: [3][]u8 = undefined;
    var ind_sixes: u8 = 0;
    var ind_fives: u8 = 0;
    for (raw_digits) |digit| {
        if (digit.len == 2) {
            new_digits[1] = digit;
        }
        if (digit.len == 3) {
            new_digits[7] = digit;
        }
        if (digit.len == 4) {
            new_digits[4] = digit;
        }
        if (digit.len == 7) {
            new_digits[8] = digit;
        }
        if (digit.len == 5) {
            fives[ind_fives] = digit;
            ind_fives += 1;
        }
        if (digit.len == 6) {
            sixes[ind_sixes] = digit;
            ind_sixes += 1;
        }
    }
    // It remains to sorts out fives[] among 2,3,5,
    // and sixes[] among 0, 6, 9.
    // 'd' and 'b' are the letters that are present in 4 but not in 1,7.
    // But 'd' is also present in all of 2,3,5 while 'b' is only in
    // one of them.
    var b_letter: u8 = undefined;
    var d_letter: u8 = undefined;
    for (new_digits[4]) |letter| {
        if (present(letter, new_digits[1]) or present(letter, new_digits[7])) {
            continue;
        }
        if (!present(letter, fives[0]) or !present(letter, fives[1]) or
            !present(letter, fives[2]))
        {
            b_letter = letter;
        } else {
            d_letter = letter;
        }
    }
    // We can now determine 5, it's the one with 'b'. Also the letter that's in 1 but
    // absent from 5 is 'c', and the other letter in 1 is 'f'.
    var c_letter: u8 = undefined;
    var f_letter: u8 = undefined;
    for (fives) |digit| {
        if (present(b_letter, digit)) {
            new_digits[5] = digit;
            for (new_digits[1]) |letter| {
                if (!present(letter, digit)) {
                    c_letter = letter;
                } else {
                    f_letter = letter;
                }
            }
        }
    }
    // Sort out the rest of 'fives'. 2 has both 'b' and 'f' absent,
    // 3 has both 'c' and 'f' present.
    for (fives) |digit| {
        if (!present(b_letter, digit) and !present(f_letter, digit)) {
            new_digits[2] = digit;
        }
        if (present(c_letter, digit) and present(f_letter, digit)) {
            new_digits[3] = digit;
        }
    }
    // Sort out 'sixes'. 0 is the one without 'd', 6 is the one without 'c',
    // 9 is the remaining one.
    for (sixes) |digit| {
        if (!present(d_letter, digit)) {
            new_digits[0] = digit;
        } else if (!present(c_letter, digit)) {
            new_digits[6] = digit;
        } else {
            new_digits[9] = digit;
        }
    }
    return new_digits;
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("aoc08.input", .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};

    var cnt: u16 = 0;
    var sum: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var first_half = line[0..std.mem.indexOfScalar(u8, line, '|').?];
        var raw_digits: [10][]u8 = undefined;
        var iter = std.mem.tokenize(u8, first_half, " ");
        var ind: u8 = 0;
        while (iter.next()) |token| {
            raw_digits[ind] = try gpalloc.allocator.dupe(u8, token);
            std.sort.sort(u8, raw_digits[ind], {}, comptime std.sort.asc(u8));
            ind += 1;
        }
        var digits = categorizeDigits(raw_digits);

        var second_half = line[std.mem.indexOfScalar(u8, line, '|').? + 1 ..];
        iter = std.mem.tokenize(u8, second_half, " ");
        var num: u32 = 0;
        while (iter.next()) |token| {
            if (token.len == 2 or token.len == 4 or token.len == 3 or token.len == 7) {
                cnt += 1;
            }
            var stoken = try gpalloc.allocator.dupe(u8, token);
            defer gpalloc.allocator.free(stoken);
            std.sort.sort(u8, stoken, {}, comptime std.sort.asc(u8));
            var digit: u8 = 0;
            while (digit < 10) {
                if (std.mem.eql(u8, stoken, digits[digit])) {
                    num = num * 10 + digit;
                    break;
                }
                digit += 1;
            }
        }
        sum += num;
        for (raw_digits) |raw| {
            gpalloc.allocator.free(raw);
        }
    }
    try std.io.getStdOut().writer().print("part1: {d}\n", .{cnt});
    try std.io.getStdOut().writer().print("part1: {d}\n", .{sum});
}
