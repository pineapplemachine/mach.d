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


## mach.text.utf.combined


This module exposes generalized implementations for acquiring UTF-8, UTF-16,
or UTF-32 strings from arbitrary UTF-encoded inputs.
`utf8encode` can be used to acquire a UTF-8 string, `utf16encode` a UTF-16
string, and `utf32encode` a UTF-32 string.

The `utfencode` alias can be used to acquire UTF-8 strings and the `utfdecode`
alias can be used to acquire UTF-32 strings.

``` D
import mach.range.compare : equals;
// UTF-8 => UTF-8
assert("hello! ツ".utf8encode.equals("hello! ツ"));
// UTF-8 => UTF-16
assert("hello! ツ".utf16encode.equals("hello! ツ"w));
// UTF-8 => UTF-32
assert("hello! ツ".utfdecode.equals("hello! ツ"d));
// UTF-16 => UTF-32
assert("hello! ツ"w.utfdecode.equals("hello! ツ"d));
```


Note that if the input was not already encoded with the desired encoding type
then these functions return ranges which lazily enumerate code units, rather
than arrays or string primitives.
To get an in-memory array from the output, a function such as `asarray` from
`mach.range.asarray` can be used.

``` D
import mach.range.asarray : asarray;
dstring utf32 = "hello! ツ".utfdecode.asarray!(immutable dchar); // Decode UTF-8
assert(utf32 == "hello! ツ"d);
```


## mach.text.utf.encode


This module implements templates and types shared by UTF-8 and UTF-16
encoding implementations.


## mach.text.utf.encodings


This module implements the `UTFEncoding` enum, which enumerates all
recognized UTF encodings.


## mach.text.utf.exceptions


This module implements the various exception types that may be thrown by
functions in the `mach.text.utf` package.
All such exceptions inherit from the base `UTFException` class.
Encoding errors result in a `UTFEncodeException` and decoding errors result
in a `UTFDecodeException`.


## mach.text.utf.utf16


This package implements encoding and decoding of UTF-16 strings.


## mach.text.utf.utf8


This package implements encoding and decoding of UTF-8 strings.


