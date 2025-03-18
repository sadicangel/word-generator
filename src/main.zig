const std = @import("std");
const VOWELS: []const u8 = "aeiou";
const CONSONANTS: []const u8 = "bcdfghjklmnpqrstvwxyz";

// word: syllable*
// syllable: consonant vowel consonant
//         | consonant vowel
//         | vowel consonant
//         | vowel
// vowel: 'aeiou'
// consonant: 'bcdfghjklmnpqrstvwxyz'

pub fn random_vowel(random: std.Random) u8 {
    return VOWELS[random.uintLessThan(usize, VOWELS.len)];
}

pub fn random_consonant(random: std.Random) u8 {
    return CONSONANTS[random.uintLessThan(usize, CONSONANTS.len)];
}

pub fn random_syllable(random: std.Random, result: *std.ArrayList(u8)) !void {
    const expr = random.intRangeLessThan(usize, 0, 4);

    switch (expr) {
        0 => {
            try result.append(random_consonant(random));
            try result.append(random_vowel(random));
            try result.append(random_consonant(random));
            return;
        },
        1 => {
            try result.append(random_consonant(random));
            try result.append(random_vowel(random));
            return;
        },
        2 => {
            try result.append(random_vowel(random));
            try result.append(random_consonant(random));
            return;
        },
        3 => {
            try result.append(random_vowel(random));
            return;
        },
        else => unreachable,
    }
}

pub fn random_word(random: std.Random, words: *std.ArrayList(u8), syllable_count: usize) !void {
    for (0..syllable_count) |_| {
        try random_syllable(random, words);
    }
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};

    const allocator = gpa.allocator();

    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();

    _ = argsIterator.next(); // Skip the program name.
    const word_count = if (argsIterator.next()) |wc| try std.fmt.parseInt(usize, wc, 10) else 10;

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var words = std.ArrayList(u8).init(allocator);
    defer words.deinit();
    for (0..word_count) |_| {
        try random_word(random, &words, random.intRangeAtMost(usize, 1, 5));
        try words.append('\n');
    }
    try std.io.getStdOut().writeAll(words.items);
}
