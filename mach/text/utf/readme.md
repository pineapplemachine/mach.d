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

``` D
import mach.range.compare : equals;
assert("hello! ツ".utf8encode.equals("hello! ツ")); // UTF-8 => UTF-8
assert("hello! ツ".utf16encode.equals("hello! ツ"w)); // UTF-8 => UTF-16
assert("hello! ツ".utf32encode.equals("hello! ツ"d)); // UTF-8 => UTF-32
```


The `utfdecode` function can be used to acquire a UTF-32 string from some
UTF-encoded input.

The `utfencode` function can be called without template arguments to encode
a UTF-8 string, it can be called with a character type as a template argument
to specify the encoding type (UTF-8 for `char`, UTF-16 for `wchar`, and
UTF-32 for `dchar`), or it can be called with a member of the `UTFEncoding`
enum as a template argument to specify the output encoding type.


Note that if the input was not already encoded with the desired encoding type
then these functions return ranges which lazily enumerate code units, rather
than arrays or string primitives.
To get an in-memory array from the output, a function such as `asarray` from
`mach.range.asarray` can be used.

``` D
import mach.range.asarray : asarray;
dstring utf32 = "hello! ツ".utf8decode.asarray!(immutable dchar);
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


