const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;

const log = std.log.scoped(.AoC);
const print = std.debug.print;

pub fn main() !void {
    var gpa = GPA(.{}){};
    defer _ = gpa.deinit(); // Performs leak checking
    var alloc = gpa.allocator();

    var T = try std.time.Timer.start();

    const res1 = try part1(Data.input, alloc);
    log.info("Part 1 answer: << {d} >>", .{res1});
    log.info("Part 1 took {d:.6}s", .{ns2sec(T.lap())});

    const res2 = try part2(Data.input, alloc);
    log.info("Part 2 answer: << {d} >>", .{res2});
    log.info("Part 2 took {d:.6}s", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    // The first line of test output is confusingly prepended with `run test: error:`
    // Adding an extra initial line makes the output easier to parse
    log.warn(" -- Running Tests --", .{});

    const answer: usize = 4361;

    var alloc = std.testing.allocator;
    var res = try part1(Data.test_input, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 467835;

    var alloc = std.testing.allocator;
    var res = try part2(Data.test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, _: Allocator) !usize {
    var line_len = utils.splitFirst(input, "\n").?.len + 1;
    const n_lines = @divFloor(input.len, line_len);

    var idx: usize = 0;
    var sum: usize = 0;
    while (idx < input.len) {
        while (idx < input.len and !std.ascii.isDigit(input[idx])) : (idx += 1) {}

        var end: usize = idx;
        while (end < input.len and std.ascii.isDigit(input[end])) : (end += 1) {}

        if (idx >= input.len) break;
        end = @min(end, input.len - 1);

        if (std.ascii.isDigit(input[idx])) {
            // We have a number
            var num: usize = try std.fmt.parseInt(usize, input[idx..end], 10);

            // Explore the region around the number for non-digit, non-'.' symbols
            var num_row: usize = @divFloor(idx, line_len);
            var num_start_col: usize = @mod(idx, line_len);
            var num_end_col: usize = @mod(end - 1, line_len);

            var start_row = @max(1, num_row) - 1;
            var end_row = @min(n_lines - 1, num_row + 1);
            var start_col = @max(1, num_start_col) - 1;
            var end_col = @min(line_len - 1, num_end_col + 1);

            var i: usize = start_row;
            while (i <= end_row) : (i += 1) blk: {
                var j: usize = start_col;
                while (j <= end_col) : (j += 1) {
                    switch (input[j + line_len * i]) {
                        '0'...'9', '.', '\n' => {},
                        else => {
                            sum += num;
                            break :blk;
                        },
                    }
                }
            }
        }
        idx = end;
    }

    return sum;
}

// ------------ Part 2 Solution ------------

const Gear = struct {
    gear1: usize = undefined,
    gear2: usize = undefined,
    count: usize = 0,
};

pub fn part2(input: []const u8, alloc: Allocator) !usize {
    var gears = std.AutoHashMap(usize, Gear).init(alloc);
    defer gears.deinit();

    var line_len = utils.splitFirst(input, "\n").?.len + 1;
    const n_lines = @divFloor(input.len, line_len);

    var idx: usize = 0;
    var sum: usize = 0;
    while (idx < input.len) {
        while (idx < input.len and !std.ascii.isDigit(input[idx])) : (idx += 1) {}

        var end: usize = idx;
        while (end < input.len and std.ascii.isDigit(input[end])) : (end += 1) {}

        if (idx >= input.len) break;
        end = @min(end, input.len - 1);

        if (std.ascii.isDigit(input[idx])) {
            // We have a number
            var num: usize = try std.fmt.parseInt(usize, input[idx..end], 10);

            // Explore the region around the number for non-digit, non-'.' symbols
            var num_row: usize = @divFloor(idx, line_len);
            var num_start_col: usize = @mod(idx, line_len);
            var num_end_col: usize = @mod(end - 1, line_len);

            var start_row = @max(1, num_row) - 1;
            var end_row = @min(n_lines - 1, num_row + 1);
            var start_col = @max(1, num_start_col) - 1;
            var end_col = @min(line_len - 1, num_end_col + 1);

            var i: usize = start_row;
            while (i <= end_row) : (i += 1) {
                var j: usize = start_col;
                while (j <= end_col) : (j += 1) {
                    const index = j + line_len * i;
                    switch (input[index]) {
                        '0'...'9', '.', '\n' => {},
                        '*' => {
                            if (gears.getPtr(index)) |gear| {
                                gear.count += 1;
                                gear.gear2 = num;
                            } else {
                                try gears.put(index, Gear{ .gear1 = num, .count = 1 });
                            }
                        },
                        else => {},
                    }
                }
            }
        }
        idx = end;
    }

    // Look for all gears with a count of 2
    var iter = gears.valueIterator();
    while (iter.next()) |gear| {
        if (gear.count == 2) {
            sum += gear.gear1 * gear.gear2;
        }
    }

    return sum;
}
