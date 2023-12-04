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

    const answer: usize = 13;

    var alloc = std.testing.allocator;
    var res = try part1(Data.test_input, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 30;

    var alloc = std.testing.allocator;
    var res = try part2(Data.test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, alloc: Allocator) !usize {
    var lines = utils.lines(input);
    var sum: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var nums = ArrayList(usize).init(alloc);
        defer nums.deinit();

        var data = utils.splitLast(line, ": ").?;
        var data1 = utils.splitFirst(data, "|").?;
        var data2 = utils.splitLast(data, "|").?;
        // std.debug.print("{s} || {s}\n", .{ data1, data2 });

        var num_iter = utils.tokenize(data1, " ");
        while (num_iter.next()) |num| {
            if (num.len == 0) break;
            // std.debug.print("** '{s}'\n", .{num});
            try nums.append(try std.fmt.parseInt(usize, num, 10));
        }

        var num_iter2 = utils.tokenize(data2, " \n");
        var score: usize = 0;
        while (num_iter2.next()) |num_s| {
            if (num_s.len == 0) break;
            // std.debug.print(">> '{s}'\n", .{num_s});
            var num: usize = try std.fmt.parseInt(usize, num_s, 10);
            if (std.mem.count(usize, nums.items, &[1]usize{num}) > 0) {
                // std.debug.print("==== {d} ====\n", .{num});
                if (score == 0) {
                    score = 1;
                } else {
                    score *= 2;
                }
            }
        }
        sum += score;
    }

    return sum;
}

// ------------ Part 2 Solution ------------

pub fn part2(input: []const u8, alloc: Allocator) !usize {
    var lines = utils.lines(input);

    var cardCount = ArrayList(usize).init(alloc);
    try cardCount.appendNTimes(1, utils.lineCount(input));
    defer cardCount.deinit();

    var card: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) break;

        var nums = ArrayList(usize).init(alloc);
        defer nums.deinit();

        var data = utils.splitLast(line, ": ").?;
        var data1 = utils.splitFirst(data, "|").?;
        var data2 = utils.splitLast(data, "|").?;

        var num_iter = utils.tokenize(data1, " ");
        while (num_iter.next()) |num| {
            if (num.len == 0) break;
            try nums.append(try std.fmt.parseInt(usize, num, 10));
        }

        var num_iter2 = utils.tokenize(data2, " \n");
        var count: usize = 0;
        while (num_iter2.next()) |num_s| {
            if (num_s.len == 0) break;
            var num: usize = try std.fmt.parseInt(usize, num_s, 10);
            if (std.mem.count(usize, nums.items, &[1]usize{num}) > 0) {
                count += 1;
            }
        }

        const copies: usize = cardCount.items[card];

        var idx: usize = 0;
        while (idx < count) : (idx += 1) {
            cardCount.items[card + 1 + idx] += copies;
        }

        card += 1;
    }

    var sum: usize = 0;
    for (cardCount.items) |count| {
        sum += count;
    }
    return sum;
}
