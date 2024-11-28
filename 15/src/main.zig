const std = @import("std");
const Data = @import("data");
const utils = @import("utils");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const GPA = std.heap.GeneralPurposeAllocator;
const ns2sec = utils.ns2sec;

pub const std_options = .{ .log_level = .info };
const log = std.log.scoped(.AoC);
const print = std.debug.print;

pub fn main() !void {
    var gpa = GPA(.{}){};
    defer _ = gpa.deinit(); // Performs leak checking
    const alloc = gpa.allocator();

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
    log.warn(" -- Running Tests --", .{});

    const answer: usize = 1320;

    const alloc = std.testing.allocator;
    const res = try part1(Data.test_input, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 145;

    const alloc = std.testing.allocator;
    const res = try part2(Data.test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, alloc: Allocator) !usize {
    _ = alloc;
    var result: usize = 0;
    var iter = std.mem.tokenize(u8, input, "\n,");
    while (iter.next()) |word| {
        result += hash(word);
    }
    return result;
}

// ------------ Part 2 Solution ------------

pub fn part2(input: []const u8, alloc: Allocator) !usize {
    var boxes = try ArrayList(std.StringArrayHashMap(u8)).initCapacity(alloc, 256);
    defer {
        for (boxes.items) |*item| {
            item.deinit();
        }
        boxes.deinit();
    }

    for (0..256) |_| {
        try boxes.append(std.StringArrayHashMap(u8).init(alloc));
    }

    var op_iter = std.mem.tokenize(u8, input, ",");
    while (op_iter.next()) |operation| {
        if (std.mem.indexOfScalar(u8, operation, '-')) |i| {
            const label = operation[0..i];
            const idx = hash(label);
            var box = &boxes.items[idx];
            _ = box.orderedRemove(label);
        } else if (std.mem.indexOfScalar(u8, operation, '=')) |i| {
            const label = operation[0..i];
            const idx = hash(label);
            const focal: u8 = try std.fmt.parseInt(u8, &[1]u8{operation[i + 1]}, 10);
            var box = &boxes.items[idx];
            try box.put(label, focal);
        }
    }

    var result: usize = 0;
    for (boxes.items, 1..) |box, i| {
        var iter = box.iterator();
        var j: usize = 1;
        while (iter.next()) |lens| {
            result += i * j * lens.value_ptr.*;
            j += 1;
        }
    }
    return result;
}

// ------------ Common Functions ------------

fn hash(input: []const u8) usize {
    var value: usize = 0;
    for (input) |c| {
        value = @mod((value + c) * 17, 256);
    }
    return value;
}

test "HASH" {
    try std.testing.expectEqual(52, hash("HASH"));
    try std.testing.expectEqual(30, hash("rn=1"));
    try std.testing.expectEqual(253, hash("cm-"));
}
