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

pub const ParseError = error{
    OutOfMemory,
    UnknownArgument,
    InvalidWordCount,
    InvalidMinSyllableCount,
    InvalidMaxSyllableCount,
};

pub const GeneratorOptions = struct {
    word_count: usize,
    min_syllable_count: usize,
    max_syllable_count: usize,
};

pub fn parse_options(allocator: std.mem.Allocator) !GeneratorOptions {
    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();

    var word_count: usize = 10;
    var min_syllable_count: usize = 1;
    var max_syllable_count: usize = 5;

    _ = argsIterator.next(); // Skip the program name.

    const Case = enum {
        @"-w",
        @"--word-count",
        @"-m",
        @"--min-syllable-count",
        @"-M",
        @"--max-syllable-count",
    };

    while (argsIterator.next()) |arg| {
        const case = std.meta.stringToEnum(Case, arg) orelse {
            return error.UnknownArgument;
        };
        switch (case) {
            .@"-w", .@"--word-count" => {
                if (argsIterator.next()) |wc| {
                    word_count = try std.fmt.parseUnsigned(usize, wc, 10);
                } else {
                    return error.InvalidWordCount;
                }
            },
            .@"-m", .@"--min-syllable-count" => {
                if (argsIterator.next()) |msc| {
                    min_syllable_count = try std.fmt.parseUnsigned(usize, msc, 10);
                } else {
                    return error.InvalidMinSyllableCount;
                }
            },
            .@"-M", .@"--max-syllable-count" => {
                if (argsIterator.next()) |msc| {
                    max_syllable_count = try std.fmt.parseUnsigned(usize, msc, 10);
                } else {
                    return error.InvalidMaxSyllableCount;
                }
            },
        }
    }

    return GeneratorOptions{
        .word_count = word_count,
        .min_syllable_count = min_syllable_count,
        .max_syllable_count = max_syllable_count,
    };
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};

    const allocator = gpa.allocator();

    const options = try parse_options(allocator);

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    var words = std.ArrayList(u8).init(allocator);
    defer words.deinit();
    for (0..options.word_count) |_| {
        try random_word(random, &words, random.intRangeAtMost(usize, options.min_syllable_count, options.max_syllable_count));
        try words.append('\n');
    }
    try std.io.getStdOut().writeAll(words.items);
}
