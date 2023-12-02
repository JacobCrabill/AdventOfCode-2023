const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;

const log = std.log.scoped(.AoC);

pub fn main() !void {
    var gpa = GPA(.{}){};
    defer _ = gpa.deinit(); // Performs leak checking
    var alloc = gpa.allocator();

    var T = try std.time.Timer.start();

    const res1 = try part1(Data.input, alloc);
    log.info("Part 1 answer: {d}", .{res1});
    log.info("Part 1 took {d:.6}s", .{ns2sec(T.lap())});

    const res2 = try part2(Data.input, alloc);
    log.info("Part 2 answer: {d}", .{res2});
    log.info("Part 2 took {d:.6}s", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    // The first line of test output is confusingly prepended with `run test: error:`
    // Adding an extra initial line makes the output easier to parse
    log.warn(" -- Running Tests --", .{});

    const answer: usize = 8;

    var alloc = std.testing.allocator;
    var res = try part1(Data.test_input, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 2286;

    var alloc = std.testing.allocator;
    var res = try part2(Data.test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, alloc: Allocator) !usize {
    var limits = std.StringHashMap(usize).init(alloc);
    defer limits.deinit();
    try limits.put("red", 12);
    try limits.put("green", 13);
    try limits.put("blue", 14);

    var sum: usize = 0;
    var lines = std.mem.split(u8, input, "\n");
    var id: usize = 1;
    while (lines.next()) |line| {
        if (line.len < 10) continue;

        // Skip the game label
        var game_it = std.mem.split(u8, line, ":");
        _ = game_it.next().?;

        // Get the games lists
        var game_s = game_it.next().?;
        var games = std.mem.split(u8, game_s, ";");
        var possible: bool = true;
        while (games.next()) |game| {
            // Parse a single "game" round: '<number> <color>, '
            var cubes = std.mem.tokenize(u8, game, ", ");
            while (cubes.next()) |cube_val| {
                var count: usize = try std.fmt.parseInt(u8, cube_val, 10);
                var color = cubes.next().?;
                if (count > limits.get(color).?) {
                    possible = false;
                }
            }
        }

        if (possible) {
            sum += id;
        }

        id += 1;
    }

    return sum;
}

// ------------ Part 2 Solution ------------

pub fn part2(input: []const u8, _: Allocator) !usize {
    var sum: usize = 0;
    var lines = std.mem.split(u8, input, "\n");
    while (lines.next()) |line| {
        if (line.len < 10) continue;

        var red_min: usize = 0;
        var green_min: usize = 0;
        var blue_min: usize = 0;

        // Skip the game label
        var game_it = std.mem.split(u8, line, ":");
        _ = game_it.next().?;

        // Get the games lists
        var game_s = game_it.next().?;
        var games = std.mem.split(u8, game_s, ";");

        while (games.next()) |game| {
            // Parse a single "game" round: 'number color, '
            var cubes = std.mem.tokenize(u8, game, ", ");
            while (cubes.next()) |cube_val| {
                var count: usize = try std.fmt.parseInt(u8, cube_val, 10);
                var color = cubes.next().?;

                if (std.mem.eql(u8, color, "red")) {
                    red_min = @max(red_min, count);
                } else if (std.mem.eql(u8, color, "blue")) {
                    blue_min = @max(blue_min, count);
                } else if (std.mem.eql(u8, color, "green")) {
                    green_min = @max(green_min, count);
                }
            }
        }

        sum += (red_min * blue_min * green_min);
    }

    return sum;
}
