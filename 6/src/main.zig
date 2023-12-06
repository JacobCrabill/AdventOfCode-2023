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

    const res2 = try part2(59796575, 597123410321328);
    log.info("Part 2 answer: << {d} >>", .{res2});
    log.info("Part 2 took {d:.6}s", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    // The first line of test output is confusingly prepended with `run test: error:`
    // Adding an extra initial line makes the output easier to parse
    log.warn(" -- Running Tests --", .{});

    const answer: usize = 288;

    var alloc = std.testing.allocator;
    var res = try part1(Data.test_input, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 71503;

    var alloc = std.testing.allocator;
    _ = alloc;
    var res = try part2(71530, 940200);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, alloc: Allocator) !usize {
    var times = ArrayList(usize).init(alloc);
    var records = ArrayList(usize).init(alloc);
    defer times.deinit();
    defer records.deinit();

    var lines = utils.lines(input);
    const line0 = lines.next().?;
    const line1 = lines.next().?;

    var time_iter = utils.tokenize(line0, ": \n");
    _ = time_iter.next();
    while (time_iter.next()) |time_s| {
        try times.append(try std.fmt.parseInt(usize, time_s, 10));
    }

    var dist_iter = utils.tokenize(line1, ": \n");
    _ = dist_iter.next();
    while (dist_iter.next()) |dist_s| {
        try records.append(try std.fmt.parseInt(usize, dist_s, 10));
    }

    var total: usize = 1;
    for (times.items, 0..) |time, i| {
        const record = records.items[i];
        var count: usize = 0;
        var t: usize = 0;
        while (t < time) : (t += 1) {
            var new_dist = t * (time - t);
            if (new_dist > record)
                count += 1;
        }

        total *= count;
    }

    return total;
}

// ------------ Part 2 Solution ------------

pub fn part2(time: usize, distance: usize) !usize {
    const record = distance;
    var count: usize = 0;
    var t: usize = 0;
    while (t < time) : (t += 1) {
        var new_dist = t * (time - t);
        if (new_dist > record)
            count += 1;
    }

    return count;
}

// ------------ Common Functions ------------
