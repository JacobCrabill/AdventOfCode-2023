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

    const answer: usize = 6440;

    var alloc = std.testing.allocator;
    var res = try part1(Data.test_input, alloc);
    //var res = try part1(Data.test_input2, alloc);
    log.warn("[Test] Part 1: {d}", .{res});
    try std.testing.expect(res == answer);
}

test "part2 test input" {
    const answer: usize = 0;

    var alloc = std.testing.allocator;
    var res = try part2(Data.test_input, alloc);
    log.warn("[Test] Part 2: {d}", .{res});
    try std.testing.expect(res == answer);
}

// ------------ Part 1 Solution ------------

const cards = [_]u8{ '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A' };

const HandType = enum(u8) {
    HighCard = 0,
    OnePair = 1,
    TwoPair = 2,
    ThreeOfAKind = 3,
    FullHouse = 4,
    FourOfAKind = 5,
    FiveOfAKind = 6,
};

const Hand = struct {
    cards: []const u8 = undefined,
    bid: usize = undefined,
    kind: HandType = undefined,
};

pub fn part1(input: []const u8, alloc: Allocator) !usize {
    var hands = ArrayList(Hand).init(alloc);
    defer hands.deinit();

    var lines = utils.lines(input);
    while (lines.next()) |line| {
        if (line.len == 0) break;
        var fields = utils.tokenize(line, " \n");

        const hand = fields.next().?;
        const bid = try std.fmt.parseInt(usize, fields.next().?, 10);
        const hand_type = getHandType(hand);

        try hands.append(Hand{ .cards = hand, .bid = bid, .kind = hand_type });
    }

    std.sort.heap(Hand, hands.items, {}, compareHands);

    var sum: usize = 0;
    for (hands.items, 1..) |hand, i| {
        //std.debug.print("{any}\n", .{hand});
        std.debug.print("{d}: ", .{i});
        printHand(hand);
        sum += i * hand.bid;
    }

    if (!std.sort.isSorted(Hand, hands.items, {}, compareHands)) {
        @panic("Improper sort!!");
    }

    return sum;
}

// ------------ Part 2 Solution ------------

pub fn part2(input: []const u8, alloc: Allocator) !usize {
    _ = alloc;
    _ = input;
    return 0;
}

// ------------ Common Functions ------------

fn printHand(hand: Hand) void {
    std.debug.print("{s}: {s}, {d}\n", .{ hand.cards, @tagName(hand.kind), hand.bid });
}

fn cardRank(c: u8) u8 {
    return switch (c) {
        '2' => 0,
        '3' => 1,
        '4' => 2,
        '5' => 3,
        '6' => 4,
        '7' => 5,
        '8' => 6,
        '9' => 7,
        'T' => 8,
        'J' => 9,
        'Q' => 10,
        'K' => 11,
        'A' => 12,
        else => 255,
    };
}

fn getHandType(hand: []const u8) HandType {
    var counts = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    var max_count: u8 = 0;
    for (cards, 0..) |card, i| {
        counts[i] = @intCast(std.mem.count(u8, hand, &[1]u8{card}));
        if (counts[i] > max_count)
            max_count = counts[i];
    }

    switch (max_count) {
        5 => return .FiveOfAKind,
        4 => return .FourOfAKind,
        3 => {
            for (counts) |count| {
                if (count == 2) return .FullHouse;
            }
            return .ThreeOfAKind;
        },
        2 => {
            var pair_count: u8 = 0;
            for (counts) |count| {
                if (count == 2) pair_count += 1;
            }
            if (pair_count >= 2) return .TwoPair;
            return .OnePair;
        },
        else => return .HighCard,
    }

    return .HighCard;
}

fn getHighCard(hand: []const u8) u8 {
    var counts = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    var max_count: u8 = 0;
    var high_card: u8 = '2';
    for (cards, 0..) |card, i| {
        counts[i] = @intCast(utils.countScalar(u8, hand, card));
        if (counts[i] > max_count) {
            max_count = counts[i];
            high_card = card;
        }
    }

    return high_card;
}

/// Comparator fn for Hand types - returns whether hand1 < hand2
fn compareHands(_: void, hand1: Hand, hand2: Hand) bool {
    if (@intFromEnum(hand1.kind) < @intFromEnum(hand2.kind)) return true;
    if (@intFromEnum(hand1.kind) > @intFromEnum(hand2.kind)) return false;

    // Simple AoC version - compare cards in order
    for (hand1.cards, 0..) |card1, i| {
        const card2 = hand2.cards[i];
        // std.debug.print("{c}, {c}, {any}\n", .{ card1, card2, cardRank(card1) < cardRank(card2) });
        if (cardRank(card1) < cardRank(card2)) return true;
        if (cardRank(card1) > cardRank(card2)) return false;
    }

    // If we were playing real poker:
    // switch (hand1.kind) {
    //     .FiveOfAKind => return hand1.cards[0] < hand2.cards[0],
    //     .FourOfAKind, .ThreeOfAKind, .OnePair, .HighCard => {
    //         const h1 = getHighCard(hand1.cards);
    //         const h2 = getHighCard(hand1.cards);
    //         return h1 < h2;
    //     },
    //     .TwoPair => {
    //     },
    //     else => return false,
    // }

    return true;
}
