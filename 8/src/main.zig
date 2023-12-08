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

    const test1 =
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    const test2 =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    const answer1: usize = 2;
    const answer2: usize = 6;

    var alloc = std.testing.allocator;
    var res = try part1(test1, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer1);
    res = try part1(test2, alloc);
    try std.testing.expect(res == answer2);
}

test "part2 test input" {
    const test_input =
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    ;
    const answer: usize = 6;

    var alloc = std.testing.allocator;
    var res = try part2(test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Part 1 Solution ------------

const Node = struct {
    left: []const u8,
    right: []const u8,
};

pub fn part1(input: []const u8, alloc: Allocator) !usize {
    var nodes = std.StringHashMap(Node).init(alloc);
    defer nodes.deinit();

    var lines = utils.lines(input);

    // First line contains directions
    const dirs = lines.next().?;

    // 2nd line is blank
    _ = lines.next().?;

    while (lines.next()) |line| {
        if (line.len == 0) break;
        var node_names = utils.tokenize(line, " =(),\n");
        const name = node_names.next().?;
        const left = node_names.next().?;
        const right = node_names.next().?;
        try nodes.put(name, Node{ .left = left, .right = right });
    }

    const N: usize = dirs.len;
    var count: usize = 0;
    var current: []const u8 = "AAA";
    while (!std.mem.eql(u8, current, "ZZZ")) {
        const next_dir = dirs[@mod(count, N)];
        switch (next_dir) {
            'L' => current = nodes.get(current).?.left,
            'R' => current = nodes.get(current).?.right,
            else => @panic("unreachable"),
        }
        count += 1;
    }

    return count;
}

// ------------ Part 2 Solution ------------

fn areAllCurrentZ(current_nodes: [][]const u8) bool {
    for (current_nodes) |node| {
        if (node[2] != 'Z')
            return false;
    }

    return true;
}

pub fn part2(input: []const u8, alloc: Allocator) !usize {
    var nodes = std.StringHashMap(Node).init(alloc);
    defer nodes.deinit();

    var a_nodes = ArrayList([]const u8).init(alloc);
    defer a_nodes.deinit();

    var lines = utils.lines(input);

    // First line contains directions
    const dirs = lines.next().?;

    // 2nd line is blank
    _ = lines.next().?;

    while (lines.next()) |line| {
        if (line.len == 0) break;
        var node_names = utils.tokenize(line, " =(),\n");
        const name = node_names.next().?;
        const left = node_names.next().?;
        const right = node_names.next().?;
        try nodes.put(name, Node{ .left = left, .right = right });
    }

    var keys = nodes.keyIterator();
    while (keys.next()) |name| {
        if (name.*[2] == 'A') {
            print("Start node: {s}\n", .{name.*});
            try a_nodes.append(name.*);
        }
        if (name.*[2] == 'Z') {
            print("End node: {s}\n", .{name.*});
        }
    }

    const N: usize = dirs.len;
    var counts = ArrayList(usize).init(alloc);
    defer counts.deinit();

    for (a_nodes.items) |start| {
        var count: usize = 0;
        var current: []const u8 = start;
        while (current[2] != 'Z') {
            const next_dir = dirs[@mod(count, N)];
            switch (next_dir) {
                'L' => current = nodes.get(current).?.left,
                'R' => current = nodes.get(current).?.right,
                else => @panic("unreachable"),
            }
            count += 1;
        }
        try counts.append(count);
    }

    for (counts.items, 0..) |c, i| {
        print("{d}: {d}\n", .{ i, c });
    }

    return lcm(counts.items);
}

fn lcm(nums: []usize) usize {
    const math = utils.Math(usize);

    var ans: usize = nums[0];
    var i: usize = 1;
    while (i < nums.len) : (i += 1) {
        ans = math.lcm(ans, nums[i]);
    }
    return ans;
}
