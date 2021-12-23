const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

fn isLarge(c: u8) bool {
    return c >= 'A' and c <= 'D';
}
fn isSmall(c: u8) bool {
    return c >= 'a' and c <= 'd';
}
fn isLetter(c: u8) bool {
    return isLarge(c) or isSmall(c);
}

pub const State = struct {
    //#############
    //#...........#
    //###B#C#B#D###
    //  #D#C#B#A#
    //  #D#B#A#C#
    //  #A#D#C#A#
    //  #########
    //
    // A state is a string:
    // "|...........|BDDA|CCBD|BBAC|DACA|"
    // plus "moving" is an optional index in the state
    // of the currently moving amphipod.
    // Connections:
    // state[1..12] is the hallway, [13..17] the A-room,
    // [18..22], [23..27], [28..32] the B-, C-, D-rooms.
    // 13 <-->3, 18<-->5, 23<-->7, 27<-->9.
    // When an amphipod goes e.g. from 13 to 3, it becomes
    // "moving" and the moving index is initialized. Then
    // only it can move until it stops. When it stops, 'A'
    // turns into 'a' etc. When 'a' starts moving again,
    // the moving index is initialized again and is reset when
    // it steps into A's room. It stays 'a' until the end and
    // can't go out to the hallway again.
    code: [33]u8 = undefined,
    moving: ?u8 = null,
    fn inHallway(ind: u8) bool {
        return 1 <= ind and ind <= 11;
    }
    fn atGateway(ind: u8) bool {
        return ind == 3 or ind == 5 or ind == 7 or ind == 9;
    }
    fn indRoom(letter: u8) u8 {
        return switch (letter) {
            'A', 'a' => 13,
            'B', 'b' => 18,
            'C', 'c' => 23,
            'D', 'd' => 28,
            else => 0,
        };
    }
    // Next step towards own room.
    fn towardsRoom(self: *const State, ind: u8) u8 {
        const letter = self.code[ind];
        const gateway = switch (letter) {
            'A', 'a' => 3,
            'B', 'b' => 5,
            'C', 'c' => 7,
            'D', 'd' => 9,
            else => @intCast(u8, 0),
        };
        if (ind > gateway) {
            return ind - 1;
        } else if (ind < gateway) {
            return ind + 1;
        } else return indRoom(letter);
    }

    fn endState(self: *const State) bool {
        for (self.code) |val, i| {
            if (0 <= i and i <= 10 and val != '.') {
                return false;
            }
            if (isLetter(val) and !(i >= indRoom(val) and i <= indRoom(val) + 4)) {
                return false;
            }
        }
        return true;
    }
    // Caller deinits.
    fn nextStates(self: *const State) !std.ArrayList(State) {
        var arr = std.ArrayList(State).init(&gpalloc.allocator);
        if (self.moving) |ind| {
            // Moving is always in the hallway.
            if (!(inHallway(ind))) {
                @panic("Inappropriate movement.");
            }
            // Moving is always for letters.
            if (!isLetter(self.code[ind])) {
                print("code: {s} ind: {d} selfcodeind: {c}\n", .{ self.code, ind, self.code[ind] });
                @panic("Moving a non-letter.");
            }
            if (isLarge(self.code[ind])) {
                // Moving as a large letter. First thing we can do is stop.
                // Stopping can't happen outside rooms.
                if (!atGateway(ind)) {
                    try arr.append(State{ .code = self.code, .moving = null });
                }
                // Moving left or right is fine.
                if (self.code[ind - 1] == '.') {
                    var next = State{ .code = self.code, .moving = ind - 1 };
                    next.code[ind - 1] = self.code[ind];
                    next.code[ind] = '.';
                    try arr.append(next);
                }
                if (self.code[ind + 1] == '.') {
                    var next = State{ .code = self.code, .moving = ind + 1 };
                    next.code[ind + 1] = self.code[ind];
                    next.code[ind] = '.';
                    try arr.append(next);
                }
            } else {
                // Moving as a small letter. Always towards one's own room,
                // and when crossing into it, stop moving.
                var next_ind = self.towardsRoom(ind);
                if (self.code[next_ind] == '.') {
                    var next = State{ .code = self.code, .moving = if (!inHallway(next_ind)) null else next_ind };
                    next.code[next_ind] = self.code[ind];
                    next.code[ind] = '.';
                    try arr.append(next);
                }
            }
        } else {
            // Not moving.
            // Consider movement in the hallway or within rooms.
            for (self.code) |val, to| {
                if (val == '.') {
                    const froms = [2]u8{ @intCast(u8, to) - 1, @intCast(u8, to) + 1 };
                    for (froms) |from| {
                        if (isLetter(self.code[from])) {
                            // We have a possible movement from "from" to "to".
                            if (!inHallway(from)) {
                                // In rooms, large letters up, small letters down.
                                if ((isLarge(self.code[from]) and to == from - 1) or
                                    (isSmall(self.code[from]) and to == from + 1))
                                {
                                    var next = State{ .code = self.code, .moving = null };
                                    next.code[to] = self.code[from];
                                    next.code[from] = '.';
                                    try arr.append(next);
                                }
                            } else {
                                if (atGateway(from)) {
                                    @panic("Moving can't start at gateway");
                                }
                                if (isSmall(self.code[from])) {
                                    @panic("Small letter in hallway, not moving");
                                }
                                // In the hallway, movement starts "moving".
                                if (to == self.towardsRoom(from)) {
                                    // Only try to start moving if dest room only has
                                    // friendlies and they occupy the lowest positions.
                                    var room_good = true;
                                    var seen_letter = false;
                                    var room_ind = indRoom(self.code[from]);
                                    for (self.code[room_ind .. room_ind + 5]) |v| {
                                        if (v == '.' and seen_letter) {
                                            room_good = false;
                                            break;
                                        }
                                        if (isLetter(v)) {
                                            seen_letter = true;
                                            if (indRoom(v) != room_ind) {
                                                room_good = false;
                                                break;
                                            }
                                        }
                                    }
                                    if (room_good) {
                                        var next = State{ .code = self.code, .moving = @intCast(u8, to) };
                                        next.code[to] = self.code[from] + 'a' - 'A';
                                        next.code[from] = '.';
                                        try arr.append(next);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Finally, provide movement from rooms into gateways.
            const froms = [4]u8{ 13, 18, 23, 28 };
            const tos = [4]u8{ 3, 5, 7, 9 };
            for (froms) |from, i| {
                if (isLarge(self.code[from]) and self.code[tos[i]] == '.') {
                    // Move to the hallway and start "moving".
                    var next = State{ .code = self.code, .moving = tos[i] };
                    next.code[tos[i]] = self.code[from];
                    next.code[from] = '.';
                    try arr.append(next);
                }
            }
        }
        return arr;
    }
};

fn moveCost(from: *const State, to: *const State) u32 {
    if (std.mem.eql(u8, from.code[0..], to.code[0..])) {
        return 0;
    }
    for (from.code) |val, i| {
        if (val != to.code[i] and isLetter(val)) {
            return switch (val) {
                'A', 'a' => 1,
                'B', 'b' => 10,
                'C', 'c' => 100,
                'D', 'd' => 1000,
                else => 0,
            };
        }
    }
    return 0;
}

pub const StateDistance = struct {
    state: State,
    distance: u32,
};

fn sd_compare(a: StateDistance, b: StateDistance) std.math.Order {
    return std.math.order(a.distance, b.distance);
}

var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
var distances = std.AutoHashMap(State, u32).init(&gpalloc.allocator);
var visited = std.AutoHashMap(State, bool).init(&gpalloc.allocator);
var queue = std.PriorityQueue(StateDistance, sd_compare).init(&gpalloc.allocator);

fn retrieveStateDistance(state: State) ?StateDistance {
    if (distances.get(state)) |distance| {
        return StateDistance{ .state = state, .distance = distance };
    } else {
        return null;
    }
}

fn dijkstra() !void {
    var cnt: u64 = 0;
    outer: while (true) {
        if (queue.removeOrNull()) |least_sd| {
            cnt += 1;
            if (cnt % 1000 == 0) {
                print("cnt: {d} least distance: {d}\n", .{ cnt, least_sd.distance });
            }
            try visited.put(least_sd.state, true);
            const state = least_sd.state;
            print("Visiting: {s} moving:{}\n", .{ state.code, state.moving });
            const next_states = try state.nextStates();
            defer next_states.deinit();
            for (next_states.items) |next| {
                if (visited.get(next)) |_| {
                    continue;
                }
                const cost = moveCost(&state, &next);
                const new_distance = least_sd.distance + cost;
                const new_sd = StateDistance{
                    .state = next,
                    .distance = new_distance,
                };

                //print("  Generated: {s} moving:{}\n", .{ next.code, next.moving });
                if (retrieveStateDistance(next)) |next_sd| {
                    if (new_distance >= next_sd.distance) {
                        continue;
                    }
                    // An improvement.
                    try distances.put(next, new_distance);
                    //try queue.update(next_sd, new_sd); - structs don't ==.
                    var iter = queue.iterator();
                    while (iter.next()) |i| {
                        if (std.meta.eql(i.state, next)) {
                            _ = queue.removeIndex(iter.count - 1);
                            try queue.add(new_sd);
                            break;
                        }
                    }
                } else {
                    // A new state.
                    try distances.put(next, new_distance);
                    try queue.add(new_sd);
                }
                if (next.endState()) {
                    print("Path found! Distance: {d}\n", .{new_distance});
                    break :outer;
                }
            }
        } else {
            @panic("Path not found!");
        }
    }
}

pub fn main() anyerror!void {
    try std.io.getStdOut().writer().print("part2: {}\n", .{0});

    var state: State = State{
        //.code = "|...........|BDDA|CCBD|BBAC|DACA|".*,
        .code = "|...........|BA##|CD##|BC##|DA##|".*,
        .moving = null,
    };
    try distances.put(state, 0);
    var sd = StateDistance{
        .state = state,
        .distance = 0,
    };
    try queue.add(sd);

    try dijkstra();
}
