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

pub fn is_vowel(c: u8) bool {
    return c == 'a' or c == 'e' or c == 'i' or c == 'o' or c == 'u';
}

pub fn mutate_word(random: std.Random, words: *std.ArrayList(u8), start: usize, end: usize) !void {
    const index = random.intRangeLessThan(usize, start, end);
    if (is_vowel(words.items[index])) {
        words.items[index] = random_vowel(random);
    } else {
        words.items[index] = random_consonant(random);
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
    mutations: usize,
};

pub fn parse_options(allocator: std.mem.Allocator) !GeneratorOptions {
    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer argsIterator.deinit();

    var options = GeneratorOptions{
        .word_count = 10,
        .min_syllable_count = 1,
        .max_syllable_count = 5,
        .mutations = 1,
    };

    _ = argsIterator.next(); // Skip the program name.

    const Case = enum { @"-w", @"--word-count", @"-m", @"--min-syllable-count", @"-M", @"--max-syllable-count", @"-p", @"--mutations", @"-h", @"--help" };

    while (argsIterator.next()) |arg| {
        const case = std.meta.stringToEnum(Case, arg) orelse {
            return error.UnknownArgument;
        };
        switch (case) {
            .@"-w", .@"--word-count" => {
                if (argsIterator.next()) |wc| {
                    options.word_count = try std.fmt.parseUnsigned(usize, wc, 10);
                } else {
                    return error.InvalidWordCount;
                }
            },
            .@"-m", .@"--min-syllable-count" => {
                if (argsIterator.next()) |msc| {
                    options.min_syllable_count = try std.fmt.parseUnsigned(usize, msc, 10);
                } else {
                    return error.InvalidMinSyllableCount;
                }
            },
            .@"-M", .@"--max-syllable-count" => {
                if (argsIterator.next()) |msc| {
                    options.max_syllable_count = try std.fmt.parseUnsigned(usize, msc, 10);
                } else {
                    return error.InvalidMaxSyllableCount;
                }
            },
            .@"-p", .@"--mutations" => {
                if (argsIterator.next()) |m| {
                    options.mutations = try std.fmt.parseUnsigned(usize, m, 10);
                } else {
                    return error.InvalidMutations;
                }
            },
            .@"-h", .@"--help" => {
                const writer = std.io.getStdOut().writer();
                try writer.print("Usage: word_generator [options]\n", .{});
                try writer.print("Options:\n", .{});
                try writer.print("  -w, --word-count <count>          Number of words to generate (default: 10)\n", .{});
                try writer.print("  -m, --min-syllable-count <count>  Minimum number of syllables per word (default: 1)\n", .{});
                try writer.print("  -M, --max-syllable-count <count>  Maximum number of syllables per word (default: 5)\n", .{});
                try writer.print("  -p, --mutations <count>           Number of mutations to apply to each word (default: 0)\n", .{});
                return error.UnknownArgument;
            },
        }
    }

    return options;
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
        const start = words.items.len;
        try random_word(random, &words, random.intRangeAtMost(usize, options.min_syllable_count, options.max_syllable_count));
        const end = words.items.len;
        for (0..options.mutations) |_| {
            try mutate_word(random, &words, start, end);
        }
        try words.append('\n');
    }
    try std.io.getStdOut().writeAll(words.items);
}
