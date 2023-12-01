const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;

const test_input = Data.test_input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var T = try std.time.Timer.start();

    var res1 = try part1(Data.input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});
    std.debug.print("Part 1 took {d:.6}s\n", .{ns2sec(T.lap())});

    var res2 = try part2(Data.input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
    std.debug.print("Part 2 took {d:.6}s\n", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    std.debug.print("[Test] Part 1: {d}\n", .{res});
    try std.testing.expect(res == 142);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(Data.test2, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 281);
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, alloc: Allocator) !usize {
    _ = alloc;
    var lines = std.mem.split(u8, input, "\n");

    var sum: usize = 0;
    while (lines.next()) |line| {
        if (line.len < 2) break;
        var first: ?u8 = null;
        var last: ?u8 = null;
        for (line) |c| {
            switch (c) {
                '0'...'9' => {
                    if (first == null) {
                        first = c - '0';
                    } else {
                        last = c - '0';
                    }
                },
                else => {},
            }
        }

        if (last == null) {
            last = first.?;
        }

        const val = first.? * 10 + last.?;
        sum += val;
    }
    return sum;
}

// ------------ Part 2 Solution ------------

pub fn part2(input: []const u8, alloc: Allocator) !usize {
    _ = alloc;
    var lines = std.mem.split(u8, input, "\n");

    const nums = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

    var sum: usize = 0;
    while (lines.next()) |line| {
        if (line.len < 2) break;

        var first: ?u8 = null;
        var last: ?u8 = null;
        for (line, 0..) |c, i| {
            // Check for text num
            for (nums, 1..) |num, j| {
                if (std.mem.startsWith(u8, line[i..], num)) {
                    if (first == null) {
                        first = @intCast(j);
                    } else {
                        last = @intCast(j);
                    }
                }
            }
            // Check for digit
            switch (c) {
                '0'...'9' => {
                    if (first == null) {
                        first = c - '0';
                    } else {
                        last = c - '0';
                    }
                },
                else => {},
            }
        }

        if (last == null) {
            last = first.?;
        }

        const val = first.? * 10 + last.?;
        sum += val;
    }
    return sum;
}

// ------------ Common Functions ------------
