# mach.text.ascii


This module implements various functions for operating upon ASCII-encoded
strings and characters.

``` D
// Eagerly convert an ASCII character or string to upper case.
assert('x'.toupper == 'X');
assert("Hello".toupper == "HELLO");
// Eagerly convert an ASCII character or string to lower case.
assert('X'.tolower == 'x');
assert("Hello".tolower == "hello");
```

``` D
assert('A'.isascii); // Is a valid ASCII character
assert('a'.isalpha); // Is a–z or A–Z.
assert('X'.isupper); // Is A–Z.
assert('x'.islower); // Is a–z.
assert('e'.isvowel); // Is a, e, i, o, u, or y (case-insensitive)
assert('0'.isdigit); // Is 0–9.
assert('F'.ishexdigit); // Is 0–9, a–f, or A–F.
assert(';'.ispunctuation); // Is punctuation (excluding whitespace)
assert(' '.iswhitespace); // Is whitespace
assert('\0'.iscontrol); // Is a control character
assert('!'.isprintable); // Is a printable (non-control) character
```


# mach.text.numeric


This package provides functions for parsing and serializing numbers.

Of note are the `parsenumber` and `writenumber` functions, which are
generic implementations handling integer and floating point primitives of
any type.

``` D
assert("100".parsenumber!int == 100);
assert("1234.5".parsenumber!double == double(1234.5));
```

``` D
assert(int(200).writenumber == "200");
assert(double(456.789).writenumber == "456.789");
```


# mach.text.text


This module implements the `text` function, which converts all of its arguments
to strings using `str` in `mach.text.str` and concatenates them.

``` D
assert(text("hello", ' ', "world") == "hello world");
assert(text("I would walk ", 1000, " miles") == "I would walk 1000 miles");
```


# mach.text.utf


This package implements encoding and decoding of UTF-8, UTF-16, and UTF-32
strings.

Of particular note are `utfencode`, which acquires a UTF-8 string from an
arbitrary UTF-encoded string input, and `utfdecode`, which acquires a decoded
UTF-32 string from an arbitrary UTF-encoded string input.
Additionally, the `utf16encode` function can be used to encode a UTF-16
string.

When encoding a UTF-8 or UTF-16 string fails, a `UTFEncodeException` is thrown.
When decoding a UTF-8 or UTF-16 string fails, a `UTFDecodeException` is thrown.

``` D
import mach.range.compare : equals;
// UTF-32 => UTF-8
assert("hello! ツ"d.utfencode.equals("hello! ツ"));
// UTF-8 => UTF-32
assert("hello! ツ".utfdecode.equals("hello! ツ"d));
```


