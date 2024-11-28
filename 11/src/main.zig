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

    const res1 = try solution(Data.input, alloc, 2);
    log.info("Part 1 answer: << {d} >>", .{res1});
    log.info("Part 1 took {d:.6}s", .{ns2sec(T.lap())});

    const res2 = try solution(Data.input, alloc, 1_000_000);
    log.info("Part 2 answer: << {d} >>", .{res2});
    log.info("Part 2 took {d:.6}s", .{ns2sec(T.lap())});
}

// ------------ Tests ------------

test "part1 test input" {
    log.warn(" -- Running Tests --", .{});

    const answer: usize = 374;

    const alloc = std.testing.allocator;
    const res = try solution(Data.test_input, alloc, 2);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 8410;

    const alloc = std.testing.allocator;
    const res = try solution(Data.test_input, alloc, 100);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

pub fn solution(input: []const u8, alloc: Allocator, expansion: usize) !usize {
    var galaxies = std.ArrayList(Point).init(alloc);
    var empty_rows = std.ArrayList(usize).init(alloc);
    var empty_cols = std.ArrayList(usize).init(alloc);
    defer galaxies.deinit();
    defer empty_rows.deinit();
    defer empty_cols.deinit();

    var col_empty = ArrayList(bool).init(alloc);
    defer col_empty.deinit();

    var lines = utils.lines(input);
    var i: usize = 0;
    while (lines.next()) |line| {
        if (col_empty.items.len == 0) try col_empty.appendNTimes(true, line.len);

        var row_empty: bool = true;
        for (line, 0..) |c, j| {
            if (c == '#') {
                row_empty = false;
                col_empty.items[j] = false;
                try galaxies.append(.{ .row = i, .col = j });
            }
        }
        if (row_empty) {
            try empty_rows.append(i);
        }
        i += 1;
    }

    for (col_empty.items, 0..) |is_empty, col| {
        if (is_empty) {
            try empty_cols.append(col);
        }
    }

    for (galaxies.items) |*galaxy| {
        // bump row value
        var count: usize = 0;
        for (empty_rows.items) |row| {
            if (row > galaxy.row) break;
            count += expansion - 1;
        }
        galaxy.row += count;

        // Bump column value
        count = 0;
        for (empty_cols.items) |col| {
            if (col > galaxy.col) break;
            count += expansion - 1;
        }
        galaxy.col += count;
    }

    var sum: usize = 0;
    for (galaxies.items, 0..) |ga, ii| {
        for (galaxies.items[ii + 1 ..]) |gb| {
            sum += @abs(gb.row - ga.row);
            if (ga.col > gb.col) {
                sum += @abs(ga.col - gb.col);
            } else {
                sum += @abs(gb.col - ga.col);
            }
        }
    }

    return sum;
}

// ------------ Common Functions ------------

const Point = struct {
    row: usize = 0,
    col: usize = 0,
};
