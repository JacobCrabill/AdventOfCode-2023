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

    const answer: i64 = 114;

    var alloc = std.testing.allocator;
    var res = try part1(Data.test_input, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: i64 = 2;

    var alloc = std.testing.allocator;
    var res = try part2(Data.test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, alloc: Allocator) !i64 {
    var sum: i64 = 0;
    var lines = utils.lines(input);
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var nums = ArrayList(i64).init(alloc);
        defer nums.deinit();

        var nums_s = utils.tokenize(line, " \n");
        while (nums_s.next()) |num| {
            try nums.append(try std.fmt.parseInt(i64, num, 10));
        }

        // Pretty sure there's a Taylor Series-style equation for this,
        // but I was too tired to figure it out, so let's use some
        // recursion instead!
        sum += try recurse(alloc, nums.items);
    }
    return sum;
}

// ------------ Part 2 Solution ------------

pub fn part2(input: []const u8, alloc: Allocator) !i64 {
    var sum: i64 = 0;
    var lines = utils.lines(input);
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var nums = ArrayList(i64).init(alloc);
        defer nums.deinit();

        var nums_s = utils.tokenize(line, " \n");
        while (nums_s.next()) |num| {
            try nums.append(try std.fmt.parseInt(i64, num, 10));
        }

        sum += try recurse2(alloc, nums.items);
    }

    // Compute the pseudo-Taylor Series expansion of the series
    return sum;
}

// ------------ Common Functions ------------

fn calcDiff(nums: []const i64, diff: []i64) void {
    var i: usize = 0;
    while (i < diff.len) : (i += 1) {
        diff[i] = nums[i + 1] - nums[i];
    }
}

fn recurse(alloc: Allocator, nums: []const i64) !i64 {
    // Base case
    if (nums.len == 1) return nums[0];
    if (utils.countScalar(i64, nums, 0) == nums.len) return 0;

    // Compute next difference
    var diff = try alloc.alloc(i64, nums.len - 1);
    defer alloc.free(diff);
    calcDiff(nums, diff);

    // Final answer
    return nums[nums.len - 1] + try recurse(alloc, diff);
}

fn recurse2(alloc: Allocator, nums: []const i64) !i64 {
    // Base case
    if (nums.len == 1) return nums[0];
    if (utils.countScalar(i64, nums, 0) == nums.len) return 0;

    // Compute next difference
    var diff = try alloc.alloc(i64, nums.len - 1);
    defer alloc.free(diff);
    calcDiff(nums, diff);

    // Final answer
    return nums[0] - try recurse2(alloc, diff);
}
