const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;

const test_input = Data.test_input;
const input = Data.input;

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var T = try std.time.Timer.start();

    var res1 = try part1(input, alloc);
    std.debug.print("Part1: {d}\n", .{res1});
    std.debug.print("Part 1 took {d:.6}s\n", .{ns2sec(T.lap())});

    var res2 = try part2(input, alloc);
    std.debug.print("Part2: {d}\n", .{res2});
    std.debug.print("Part 2 took {d:.6}s\n", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    std.debug.print("[Test] Part 1: {d}\n", .{res});
    try std.testing.expect(res == 0);
}

test "part2 test input" {
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    std.debug.print("[Test] Part 2: {d}\n", .{res});
    try std.testing.expect(res == 0);
}

// ------------ Part 1 Solution ------------

pub fn part1(_: []const u8, _: Allocator) !usize {
    return 0;
}

// ------------ Part 2 Solution ------------

pub fn part2(_: []const u8, _: Allocator) !usize {
    return 0;
}

// ------------ Common Functions ------------

