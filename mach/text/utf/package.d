module mach.text.utf;

private:

/++ Docs

This package implements encoding and decoding of UTF-8, UTF-16, and UTF-32
strings.

Of particular note are `utfencode`, which acquires a UTF-8 string from an
arbitrary UTF-encoded string input, and `utfdecode`, which acquires a decoded
UTF-32 string from an arbitrary UTF-encoded string input.
Additionally, the `utf16encode` function can be used to encode a UTF-16
string.

When encoding a UTF-8 or UTF-16 string fails, a `UTFEncodeException` is thrown.
When decoding a UTF-8 or UTF-16 string fails, a `UTFDecodeException` is thrown.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    // UTF-32 => UTF-8
    assert("hello! ツ"d.utfencode.equals("hello! ツ"));
    // UTF-8 => UTF-32
    assert("hello! ツ".utfdecode.equals("hello! ツ"d));
}

public:

import mach.text.utf.combined;
import mach.text.utf.exceptions;
import mach.text.utf.encode;
import mach.text.utf.encodings;
