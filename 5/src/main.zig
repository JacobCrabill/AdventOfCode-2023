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

    const answer: usize = 35;

    var alloc = std.testing.allocator;
    var res = try part1(Data.test_input, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 46;

    var alloc = std.testing.allocator;
    var res = try part2(Data.test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Common Functions ------------

const Mapping = struct {
    dst_start: usize = undefined,
    src_start: usize = undefined,
    length: usize = undefined,
};

const SeedMap = struct {
    input: usize = undefined,
    output: usize = undefined,
    default: bool = true,
};

fn mapValue(in: usize, map: Mapping) SeedMap {
    var mapping = SeedMap{
        .input = in,
        .output = in,
        .default = true,
    };

    if (in >= map.src_start and in < map.src_start + map.length) {
        mapping.output = map.dst_start + (in - map.src_start);
        mapping.default = false;
    }

    return mapping;
}

test "map value" {
    const map = Mapping{
        .dst_start = 52,
        .src_start = 50,
        .length = 2,
    };
    try std.testing.expectEqual(@as(usize, 53), mapValue(51, map).output);
}

/// Perform a single round of mapping for one tag
fn parseMapping(alloc: Allocator, input: []const u8, seeds: []usize, tag: []const u8) !ArrayList(usize) {
    var seed_maps = try ArrayList(SeedMap).initCapacity(alloc, seeds.len);
    defer seed_maps.deinit();

    for (seeds) |seed| {
        try seed_maps.append(SeedMap{ .input = seed, .output = seed, .default = true });
    }

    var lines = utils.lines(input);
    _ = lines.next(); // skip the seeds row

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, tag)) break;
    }

    // parse the map
    while (lines.next()) |line| {
        if (line.len == 0) break;
        var nums = utils.tokenize(line, " \n");
        var dst = try std.fmt.parseInt(usize, nums.next().?, 10);
        var src = try std.fmt.parseInt(usize, nums.next().?, 10);
        var len = try std.fmt.parseInt(usize, nums.next().?, 10);
        const map = Mapping{ .dst_start = dst, .src_start = src, .length = len };
        for (seed_maps.items, 0..) |mapping, i| {
            if (mapping.default) {
                const new_map = mapValue(mapping.input, map);
                if (!new_map.default) {
                    seed_maps.items[i] = new_map;
                }
            }
        }
    }

    var outputs = ArrayList(usize).init(alloc);
    for (seed_maps.items) |mapping| {
        try outputs.append(mapping.output);
    }

    return outputs;
}

fn parseMappings(alloc: Allocator, input: []const u8, tag: []const u8) !ArrayList(Mapping) {
    var lines = utils.lines(input);
    _ = lines.next(); // skip the seeds row

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, tag)) break;
    }

    var mappings = ArrayList(Mapping).init(alloc);

    // parse the map
    while (lines.next()) |line| {
        if (line.len == 0) break;
        var nums = utils.tokenize(line, " \n");
        var dst = try std.fmt.parseInt(usize, nums.next().?, 10);
        var src = try std.fmt.parseInt(usize, nums.next().?, 10);
        var len = try std.fmt.parseInt(usize, nums.next().?, 10);
        try mappings.append(Mapping{ .dst_start = dst, .src_start = src, .length = len });
    }

    return mappings;
}

var section_names = [_][]const u8{
    "soil",
    "fertilizer",
    "water",
    "light",
    "temperature",
    "humidity",
    "location",
};

fn mapSeed(seed: usize, mappings: ArrayList(ArrayList(Mapping))) usize {
    var output: usize = seed;
    for (mappings.items) |map_list| {
        var mapped: bool = false;
        for (map_list.items) |map| inner: {
            if (mapped) break;
            const out = mapValue(output, map);
            if (!out.default) {
                output = out.output;
                mapped = true;
                break :inner;
            }
        }
    }

    return output;
}

// ------------ Part 1 Solution ------------

pub fn part1(input: []const u8, alloc: Allocator) !usize {
    var seeds = ArrayList(usize).init(alloc);
    defer seeds.deinit();

    // Parse the first line: the list of seeds
    var lines = utils.lines(input);
    const seed_row = lines.next().?;
    var data = utils.tokenize(seed_row, ": \n");
    _ = data.next(); // Skip the "seeds"
    while (data.next()) |seed| {
        try seeds.append(try std.fmt.parseInt(usize, seed, 10));
    }

    var sections = [_][]const u8{
        "seed-to-soil",
        "soil-to-fertilizer",
        "fertilizer-to-water",
        "water-to-light",
        "light-to-temperature",
        "temperature-to-humidity",
        "humidity-to-location",
    };

    var values: []usize = try seeds.toOwnedSlice();
    defer alloc.free(values);

    // Perform each mapping
    for (sections) |section| {
        var tmp = try parseMapping(alloc, input, values, section);
        alloc.free(values);
        values = try tmp.toOwnedSlice();
    }

    var final_loc: usize = std.math.maxInt(usize);
    for (values) |loc| {
        if (loc < final_loc)
            final_loc = loc;
    }

    return final_loc;
}

// ------------ Part 2 Solution ------------

// While this is technically correct, the brute-force solution can't be solved
// in a reasonable amount of time.
// JK! Brute force can work :)
pub fn part2(input: []const u8, alloc: Allocator) !usize {
    var sections = [_][]const u8{
        "seed-to-soil",
        "soil-to-fertilizer",
        "fertilizer-to-water",
        "water-to-light",
        "light-to-temperature",
        "temperature-to-humidity",
        "humidity-to-location",
    };

    var ranges = ArrayList(usize).init(alloc);
    defer ranges.deinit();

    // Parse the first line: the list of seeds
    var lines = utils.lines(input);
    const seed_row = lines.next().?;
    var data = utils.tokenize(seed_row, ": \n");
    _ = data.next(); // Skip the "seeds"
    while (data.next()) |seed| {
        try ranges.append(try std.fmt.parseInt(usize, seed, 10));
    }

    // Pare the lists of mappings
    var section_maps = ArrayList(ArrayList(Mapping)).init(alloc);
    defer {
        for (section_maps.items) |*map| map.deinit();
        section_maps.deinit();
    }

    for (sections) |section| {
        try section_maps.append(try parseMappings(alloc, input, section));
    }

    var final_loc: usize = std.math.maxInt(usize);
    var idx: usize = 0;
    while (idx < ranges.items.len / 2) : (idx += 1) {
        const start: usize = ranges.items[2 * idx];
        const length: usize = ranges.items[2 * idx + 1];
        std.debug.print("Range [{d}-{d}]\n", .{ start, start + length });
        var seed_idx: usize = 0;
        while (seed_idx < length) : (seed_idx += 1) {
            const seed = mapSeed(start + seed_idx, section_maps);

            if (seed < final_loc)
                final_loc = seed;
        }
    }

    return final_loc;
}
