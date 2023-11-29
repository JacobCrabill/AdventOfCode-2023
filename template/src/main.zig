const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;

const test_input = Data.test_input;
const input = Data.input;

const log = std.log.scoped(.aoc);

pub fn main() !void {
    var gpa = GPA(.{}){};
    var alloc = gpa.allocator();

    var T = try std.time.Timer.start();

    var res1 = try part1(input, alloc);
    log.info("Part1: {d}", .{res1});
    log.info("Part 1 took {d:.6}s", .{ns2sec(T.lap())});

    var res2 = try part2(input, alloc);
    log.info("Part2: {d}", .{res2});
    log.info("Part 2 took {d:.6}s", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    log.warn(" -- Running Tests --", .{}); // First line of test output is confusingly prepended with `run test: error:`

    const answer: usize = 0;
    var alloc = std.testing.allocator;
    var res = try part1(test_input, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 0;
    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
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
