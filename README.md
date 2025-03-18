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

By default, the program generates 10 random words. You can specify the number of words to generate by passing an argument:
    ```sh
    zig build run -- 5
    ```
This will generate 5 random words.

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
The program composes words by generating 1 to 5 random syllables. A word is defined as follows:
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