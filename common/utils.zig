const std = @import("std");

const TokenIterator = std.mem.TokenIterator(u8, .any);
const SplitIterator = std.mem.SplitIterator(u8, .sequence);

/// Split the input by newline chars "\n"
/// Note: This keeps empty lines
pub fn lines(input: []const u8) SplitIterator {
    return std.mem.split(u8, input, "\n");
}

pub fn split(input: []const u8, delim: []const u8) SplitIterator {
    return std.mem.splitSequence(u8, input, delim);
}

/// Return the first item of the split
pub fn splitFirst(input: []const u8, delim: []const u8) ?[]const u8 {
    var iter = split(input, delim);
    return iter.next();
}

/// Return the last item of the split
pub fn splitLast(input: []const u8, delim: []const u8) ?[]const u8 {
    var last: ?[]const u8 = null;
    var iter = split(input, delim);
    while (iter.next()) |item| {
        last = item;
    }
    return last;
}

/// Return the Nth item of the split
pub fn splitN(input: []const u8, delim: []const u8, idx: usize) ?[]const u8 {
    var last: ?[]const u8 = null;
    var iter = split(input, delim);
    var i: usize = 0;
    while (iter.next()) |item| {
        if (i > idx) break;
        last = item;
        i += 1;
    }
    return last;
}

pub fn tokenize(input: []const u8, delim: []const u8) TokenIterator {
    return std.mem.tokenizeAny(u8, input, delim);
}

/// Return the first item of the tokenization
pub fn tokenizeFirst(input: []const u8, delim: []const u8) ?[]const u8 {
    var iter = tokenize(input, delim);
    return iter.next();
}

/// Return the last item of the tokenization
pub fn tokenizeLast(input: []const u8, delim: []const u8) ?[]const u8 {
    var last: ?[]const u8 = null;
    var iter = tokenize(input, delim);
    while (iter.next()) |item| {
        last = item;
    }
    return last;
}

/// Return the Nth item of the tokenization
pub fn tokenizeN(input: []const u8, delim: []const u8, idx: usize) ?[]const u8 {
    var last: ?[]const u8 = null;
    var iter = tokenize(input, delim);
    var i: usize = 0;
    while (iter.next()) |item| {
        if (i > idx) break;
        last = item;
        i += 1;
    }
    return last;
}

// Convert timer value to seconds (float)
pub fn ns2sec(nanos: u64) f64 {
    return @as(f64, @floatFromInt(nanos)) / 1.0e9;
}

pub fn Timer() !std.time.Timer {
    return try std.time.Timer.start();
}

// Simple wrapper around std.io.getStdOut
pub fn stdout(comptime fmt: []const u8, args: anytype) void {
    const out = std.io.getStdOut().writer();
    out.print(fmt, args) catch @panic("stdout failed!");
}

// Classic Set container type, like C++'s std::undordered_set
pub fn Set(comptime keytype: type) type {
    return struct {
        const Self = @This();
        const Key = keytype;
        const MapType = std.AutoHashMap(keytype, void);
        const Size = MapType.Size;
        map: MapType,
        alloc: std.mem.Allocator,

        pub fn init(alloc: std.mem.Allocator) Self {
            return Self{
                .alloc = alloc,
                .map = MapType.init(alloc),
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn count(self: *Self) Size {
            return self.map.count();
        }

        pub fn capacity(self: *Self) Size {
            return self.map.capacity();
        }

        pub fn getOrPut(self: *Self, key: Key) !void {
            try self.map.getOrPut(key, {});
        }

        pub fn put(self: *Self, key: Key) !void {
            try self.map.put(key, {});
        }

        pub fn putNoClobber(self: *Self, key: Key) !void {
            try self.map.putNoClobber(key, {});
        }

        pub fn contains(self: *Self, key: Key) bool {
            return self.map.contains(key);
        }

        pub fn remove(self: *Self, key: Key) bool {
            return self.map.remove(key);
        }

        pub fn iterator(self: *Self) MapType.Iterator {
            return self.map.iterator();
        }

        // Alias for remove
        pub fn pop(self: *Self, key: Key) bool {
            return self.remove(key);
        }
    };
}

test "AutoHashMap set test" {
    var set = Set(u8).init(std.testing.allocator);
    defer set.deinit();

    try set.put(10);
    try set.put(50);
    try set.put(8);

    try std.testing.expect(set.count() == 3);
    try std.testing.expect(set.capacity() == 8);
    try std.testing.expect(set.contains(8));
    try std.testing.expect(set.contains(10));
    try std.testing.expect(set.contains(1) == false);

    try std.testing.expect(set.pop(10) == true);
    try std.testing.expect(set.pop(10) == false);
    try std.testing.expect(set.count() == 2);
}

test "split First/Last/N" {
    const input = "abc, 123, def";

    try std.testing.expectEqualSlices(u8, "def", splitLast(input, ", ").?);
    try std.testing.expectEqualSlices(u8, "abc", splitFirst(input, ", ").?);
    try std.testing.expectEqualSlices(u8, "123", splitN(input, ", ", 1).?);
}

test "split uses full delim and keeps empties" {
    const input = "abc,123, , def";
    const delim = ", ";

    try std.testing.expectEqualSlices(u8, "def", splitLast(input, delim).?);
    try std.testing.expectEqualSlices(u8, "abc,123", splitFirst(input, delim).?);
    try std.testing.expectEqualSlices(u8, "", splitN(input, delim, 1).?);
}

test "tokenize First/Last/N" {
    const input = "abc, 123, def";

    try std.testing.expectEqualSlices(u8, "def", tokenizeLast(input, ", ").?);
    try std.testing.expectEqualSlices(u8, "abc", tokenizeFirst(input, ", ").?);
    try std.testing.expectEqualSlices(u8, "123", tokenizeN(input, ", ", 1).?);
}

test "tokenize uses any delim and skips empties" {
    const input = "abc,123, , def";
    const delim = ", ";

    try std.testing.expectEqualSlices(u8, "def", tokenizeLast(input, delim).?);
    try std.testing.expectEqualSlices(u8, "abc", tokenizeFirst(input, delim).?);
    try std.testing.expectEqualSlices(u8, "123", tokenizeN(input, delim, 1).?);
    try std.testing.expectEqualSlices(u8, "def", tokenizeN(input, delim, 2).?);
}
