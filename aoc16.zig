const std = @import("std");
const expect = std.testing.expect;

fn writeHexDigitToBinary(buf: []u8, digit: u8) void {
    // Too lazy to figure out printing formatted binary.
    var d = digit;
    buf[0] = '0' + d / 8;
    d %= 8;
    buf[1] = '0' + d / 4;
    d %= 4;
    buf[2] = '0' + d / 2;
    d %= 2;
    buf[3] = '0' + d;
    return;
}

test "writeHex" {
    var buf: [4]u8 = undefined;
    writeHexDigitToBinary(buf[0..], 7);
    try expect(std.mem.eql(u8, buf[0..], "0111"));
    writeHexDigitToBinary(buf[0..], 2);
    try expect(std.mem.eql(u8, buf[0..], "0010"));
    writeHexDigitToBinary(buf[0..], 14);
    try expect(std.mem.eql(u8, buf[0..], "1110"));
}

const PacketErrors = error{
    Overflow,
    InvalidCharacter,
};

// Returns number of bits consumed.
fn processPacket(buf: []u8, accumVersion: *u16) PacketErrors!u16 {
    // std.debug.print("Called with: {s}\n", .{buf});
    accumVersion.* += try std.fmt.parseInt(u8, buf[0..3], 2);
    const type_id = try std.fmt.parseInt(u8, buf[3..6], 2);
    var ind: u16 = 6;
    if (type_id == 4) {
        while (buf[ind] == '1') {
            ind += 5;
        }
        ind += 5;
    } else {
        if (buf[ind] == '1') {
            var num_packets = try std.fmt.parseInt(u16, buf[ind + 1 .. ind + 12], 2);
            ind += 12;
            while (num_packets > 0) {
                ind += try processPacket(buf[ind..], accumVersion);
                num_packets -= 1;
            }
        } else {
            var num_bits = try std.fmt.parseInt(u16, buf[ind + 1 .. ind + 16], 2);
            ind += 16;
            while (num_bits > 0) {
                var consumed = try processPacket(buf[ind..], accumVersion);
                num_bits -= consumed;
                ind += consumed;
            }
        }
    }
    return ind;
}

fn firstArg() ?[]u8 {
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    var args = std.process.args();
    if (args.next(&gpalloc.allocator)) |_| {
        if (args.next(&gpalloc.allocator)) |arg| {
            return arg catch null;
        } else {
            return null;
        }
    } else {
        return null;
    }
}

pub fn main() anyerror!void {
    var filename = firstArg() orelse "aoc16.input";
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [2048]u8 = undefined;

    const opt_line = try in_stream.readUntilDelimiterOrEof(&buf, '\n');
    const line = opt_line.?;
    var binary: [2048 * 4]u8 = undefined;
    var len: usize = 0;

    for (line) |_, ind| {
        var digit = try std.fmt.parseInt(u8, line[ind .. ind + 1], 16);
        writeHexDigitToBinary(binary[len..], digit);
        len += 4;
    }

    var versionSum: u16 = 0;
    _ = try processPacket(binary[0..len], &versionSum);

    try std.io.getStdOut().writer().print("part1: {d}\n", .{versionSum});
}
