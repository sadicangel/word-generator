# word-generator

A random word generator written in Zig.

## Installation

1. Clone the repository:
```sh
git clone https://github.com/sadicangel/word-generator.git
cd word-generator
```

2. Build the project:
```sh
zig build
```

## Usage

```sh
zig build run
```

By default, the program generates 10 random words, with 1 to 5 syllables. This is configurable:

| Argument                      | Type    | Description                               |
|-------------------------------|---------|-------------------------------------------|
| `-w` / `--word-count`         | `usize` | Number of words to generate               |
| `-m` / `--min-syllable-count` | `usize` | Minimum number of syllables per word      |
| `-M` / `--max-syllable-count` | `usize` | Maximum number of syllables per word      |
| `-p` / `--mutations`          | `usize` | Number of mutations to apply to each word |

### Example Output
Here’s an example of the program’s output, using `zig build run`:
```
atucag
um
a
gezlu
aiti
aoqa
kow
as
iulnob
uf
```

## How It Works
The program composes words by generating random syllables and then apply a set of mutations on each word.
A word is defined as follows:
```
     word : syllable*
 syllable : consonant vowel consonant
          | consonant vowel
          | vowel consonant
          | vowel
    vowel : [aeiou]
consonant : [bcdfghjklmnpqrstvwxyz]
```

## License
This project is licensed under the MIT License. See the LICENSE file for details.