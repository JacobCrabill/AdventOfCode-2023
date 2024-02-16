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
    // The first line of test output is confusingly prepended with `run test: error:`
    // Adding an extra initial line makes the output easier to parse
    log.warn(" -- Running Tests --", .{});

    const sample_1: []const u8 =
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ;

    const sample_2: []const u8 =
        \\-L|F7
        \\7S-7|
        \\L|7||
        \\-L-J|
        \\L|-JF
    ;

    const sample_3: []const u8 =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;

    const sample_4: []const u8 =
        \\7-F7-
        \\.FJ|7
        \\SJLL7
        \\|F--J
        \\LJ.LJ
    ;

    const alloc = std.testing.allocator;
    try std.testing.expectEqual(@as(i32, 4), try part1(sample_1, alloc));
    try std.testing.expectEqual(@as(i32, 4), try part1(sample_2, alloc));
    try std.testing.expectEqual(@as(i32, 8), try part1(sample_3, alloc));
    try std.testing.expectEqual(@as(i32, 8), try part1(sample_4, alloc));
}

test "part2 test input" {
    const answer: i32 = 0;
    _ = answer;

    const sample_1 =
        \\...........
        \\.S-------7.
        \\.|F-----7|.
        \\.||.....||.
        \\.||.....||.
        \\.|L-7.F-J|.
        \\.|..|.|..|.
        \\.L--J.L--J.
        \\...........
    ;
    const sample_2: []const u8 =
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ;

    const alloc = std.testing.allocator;
    try std.testing.expectEqual(@as(usize, 4), try part2(sample_1, alloc));
    try std.testing.expectEqual(@as(usize, 1), try part2(sample_2, alloc));
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, _: Allocator) !i32 {
    const width: i32 = @intCast(std.mem.indexOfScalar(u8, input, '\n').? + 1);
    const height: i32 = @intCast(utils.lineCount(input));

    const S: Point = findStartLocation(input, width);

    const dirs_to_try = [4]Direction{ .North, .South, .East, .West };
    for (dirs_to_try) |dir| {
        const next = stepInDir(S, dir);
        if (doStep(input, width, height, 1, next, dir)) |dist| {
            return std.math.divCeil(i32, dist, 2);
        }
    }

    return 0;
}

// ------------ Part 2 Solution ------------

pub fn part2(input: []const u8, alloc: Allocator) !usize {
    const width: i32 = @intCast(std.mem.indexOfScalar(u8, input, '\n').? + 1);
    const height: i32 = @intCast(utils.lineCount(input));

    const S: Point = findStartLocation(input, width);

    var marks = try alloc.dupe(u8, input);
    defer alloc.free(marks);
    for (marks) |*c| {
        if (c.* == '\n') continue;
        c.* = '.';
    }

    const start_idx: usize = @intCast(S.row * width + S.col);
    marks[start_idx] = 'x';

    var path = ArrayList(Point).init(alloc);
    defer path.deinit();

    // Find the loop
    const dirs_to_try = [4]Direction{ .North, .South, .East, .West };
    var loop_dir: ?Direction = null;
    for (dirs_to_try) |dir| blk: {
        if (loop_dir != null)
            continue; // idk why 'break :blk' doesn't exit the block

        const next = stepInDir(S, dir);
        if (doStepPaint(input, marks, width, height, next, dir, &path)) {
            loop_dir = dir;
            try path.append(next); // add in the correct starting point
            break :blk; // why does this not exit the loop?!?!
        } else {
            path.clearRetainingCapacity();
        }
    }

    var count: usize = 0;
    var row: i32 = 0;
    while (row < height) : (row += 1) {
        var col: i32 = 0;
        while (col < width - 1) : (col += 1) {
            const idx: usize = @intCast(row * width + col);
            if (marks[idx] == 'x') continue;
            const p = Point{ .row = row, .col = col };
            if (isInside(p, path)) {
                count += 1;
                marks[idx] = 'I';
            }
        }
    }

    return count;
}

// ------------ Common Functions ------------

const Point = struct {
    row: i32 = undefined,
    col: i32 = undefined,
};

const Direction = enum {
    None,
    North,
    South,
    East,
    West,
};

fn directions(pipe: u8) [2]Direction {
    return switch (pipe) {
        '|' => .{ .North, .South },
        '-' => .{ .West, .East },
        'L' => .{ .North, .East },
        'J' => .{ .West, .North },
        '7' => .{ .West, .South },
        'F' => .{ .South, .East },
        'S' => unreachable,
        else => .{ .None, .None },
    };
}

fn isCorner(pipe: u8) bool {
    return switch (pipe) {
        '|' => false,
        '-' => false,
        'L' => true,
        'J' => true,
        '7' => true,
        'F' => true,
        'S' => unreachable,
        else => false,
    };
}

/// Reverse a Direction
fn reverse(dir: Direction) Direction {
    return switch (dir) {
        .North => .South,
        .South => .North,
        .East => .West,
        .West => .East,
        .None => .None,
    };
}

fn dirFromDelta(delta: Point) Direction {
    if (delta.row < 0) return .North;
    if (delta.row > 0) return .South;
    if (delta.col < 0) return .West;
    if (delta.col > 0) return .East;
    return .None;
}

fn deltaFromDir(dir: Direction) Point {
    return switch (dir) {
        .North => Point{ .row = -1, .col = 0 },
        .South => Point{ .row = 1, .col = 0 },
        .East => Point{ .row = 0, .col = 1 },
        .West => Point{ .row = 0, .col = -1 },
        else => unreachable,
    };
}

fn stepInDir(cur: Point, dir: Direction) Point {
    const delta = deltaFromDir(dir);
    return Point{ .row = cur.row + delta.row, .col = cur.col + delta.col };
}

/// Check if pipe 'from' is connected to pipe 'to' along direction 'dir'
fn isConnected(from: u8, to: u8, dir: Direction) bool {
    // Special case for empty ground
    if (from == '.' or to == '.')
        return false;

    // Special case for starting location
    if (from == 'S') {
        const to_dirs = directions(to);
        for (to_dirs) |to_dir| {
            if (reverse(dir) == to_dir) {
                return true;
            }
        }

        return false;
    }

    // Normal non-start-location case
    const valid_dirs = directions(from);
    for (valid_dirs) |from_dir| {
        if (from_dir == dir) {
            if (to == 'S') return true;

            const to_dirs = directions(to);
            for (to_dirs) |to_dir| {
                if (from_dir == reverse(to_dir))
                    return true;
            }
        }
    }

    return false;
}

fn doStep(input: []const u8, width: i32, height: i32, dist: i32, from: Point, step_dir: Direction) ?i32 {
    const cur = stepInDir(from, step_dir);

    // Check for out-of-bounds -> invalid step
    if (cur.row < 0 or cur.col < 0 or cur.row >= height or cur.col >= width - 1)
        return null;

    // Get the previous and current pipe types
    const cur_pipe = input[@intCast(cur.row * width + cur.col)];
    const prev_pipe = input[@intCast(from.row * width + from.col)];
    if (!isConnected(prev_pipe, cur_pipe, step_dir)) {
        return null;
    }

    // --- Handle special cases ---
    // We've completed the loop!
    if (cur_pipe == 'S') {
        return dist;
    }

    // Invalid (stepped onto empty ground)
    if (cur_pipe == '.') {
        return null;
    }

    const dirs = directions(cur_pipe);
    for (dirs) |next_dir| {
        if (reverse(next_dir) == step_dir) {
            // don't go back the way we came
            continue;
        }

        //return doStep(input, width, height, dist + 1, cur, next_dir);
        if (doStep(input, width, height, dist + 1, cur, next_dir)) |new_dist| {
            return new_dist;
        }
    }

    return null;
}

fn doStepPaint(input: []const u8, marks: []u8, width: i32, height: i32, from: Point, step_dir: Direction, path: *ArrayList(Point)) bool {
    const cur = stepInDir(from, step_dir);

    // Check for out-of-bounds -> invalid step
    if (cur.row < 0 or cur.col < 0 or cur.row >= height or cur.col >= width - 1)
        return false;

    // Get the previous and current pipe types
    const cur_idx: usize = @intCast(cur.row * width + cur.col);
    const cur_pipe = input[cur_idx];
    const prev_pipe = input[@intCast(from.row * width + from.col)];
    if (!isConnected(prev_pipe, cur_pipe, step_dir)) {
        return false;
    }

    // --- Handle special cases ---
    // We've completed the loop!
    if (cur_pipe == 'S') {
        path.append(cur) catch unreachable;
        return true;
    }

    // Invalid (stepped onto empty ground)
    if (cur_pipe == '.') {
        return false;
    }

    const dirs = directions(cur_pipe);
    for (dirs) |next_dir| {
        if (reverse(next_dir) == step_dir) {
            // don't go back the way we came
            continue;
        }

        if (doStepPaint(input, marks, width, height, cur, next_dir, path)) {
            path.append(cur) catch unreachable;
            return true;
        }
    }

    return false;
}

const Pointf = struct {
    x: f64 = undefined,
    y: f64 = undefined,

    fn fromPoint(p: Point) Pointf {
        return Pointf{ .x = @floatFromInt(p.row), .y = @floatFromInt(p.col) };
    }

    fn add(a: Pointf, b: Pointf) Pointf {
        return Pointf{ .x = a.x + b.x, .y = a.y + b.y };
    }

    fn sub(a: Pointf, b: Pointf) Pointf {
        return Pointf{ .x = a.x - b.x, .y = a.y - b.y };
    }

    fn dot(a: Pointf, b: Pointf) f64 {
        return a.x * b.x + a.y * b.y;
    }

    fn cross(a: Pointf, b: Pointf) f64 {
        return a.x * b.y - b.x * a.y;
    }

    fn norm(p: Pointf) f64 {
        return @sqrt(p.dot(p));
    }

    fn normalize(p: *Pointf) void {
        const n: f64 = p.norm();
        p.x /= n;
        p.y /= n;
    }

    fn normalized(p: Pointf) Pointf {
        const n: f64 = p.norm();
        return Pointf{ .x = p.x / n, .y = p.y / n };
    }
};

fn computeAngle(base: Pointf, p1: Pointf, p2: Pointf) f64 {
    // a x b = |a| |b| sin(theta)
    const dx1: Pointf = p1.sub(base);
    const dx2: Pointf = p2.sub(base);
    const norm = dx1.norm() * dx2.norm();
    const cross = std.math.clamp(dx1.cross(dx2) / norm, -1, 1); // rotation direction via cross product
    return std.math.asin(cross);
}

/// Use the winding-number method to determine if a point is inside a path
fn isInside(p: Point, path: ArrayList(Point)) bool {
    const base = Pointf.fromPoint(p);
    var wind: f64 = 0;
    var i: usize = 0;
    while (i < path.items.len) : (i += 1) {
        const j: usize = @mod(i + 1, path.items.len);
        const pt1 = Pointf.fromPoint(path.items[i]);
        const pt2 = Pointf.fromPoint(path.items[j]);
        wind += computeAngle(base, pt1, pt2);
    }

    const eps: f64 = 1e-4;
    return @abs(wind) + eps >= 2 * std.math.pi;
}

test "winding method" {
    const alloc = std.testing.allocator;
    var path = ArrayList(Point).init(alloc);
    defer path.deinit();

    const base1 = Point{ .row = 0, .col = 0 };
    const base2 = Point{ .row = 2, .col = 0 };

    const pt0 = Point{ .row = 1, .col = 1 };
    const pt1 = Point{ .row = 1, .col = -1 };
    const pt2 = Point{ .row = -1, .col = -1 };
    const pt3 = Point{ .row = -1, .col = 1 };

    try path.append(pt0);
    try path.append(pt1);
    try path.append(pt2);
    try path.append(pt3);

    try std.testing.expect(isInside(base1, path));
    try std.testing.expect(!isInside(base2, path));
}

fn findStartLocation(input: []const u8, width: i32) Point {
    const idx: i32 = @intCast(std.mem.indexOfScalar(u8, input, 'S').?);
    const row = @divFloor(idx, width);
    const col = @mod(idx, width);

    return Point{ .row = row, .col = col };
}
