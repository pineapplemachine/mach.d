module mach.text.cstring;

private:

/++ Docs

This package contains functions for working with cstrings, or null-terminated
strings.
The `tocstring` and `fromcstring` functions can be used to covert character
arrays to and from null-terminated strings, and the `cstringlength` function
can be used to determine the length in code units of a null-terminated string.

+/

unittest{ /// Example
    assert("hello".tocstring.cstringlength == 5);
    assert("world\0".ptr.fromcstring == "world");
}

public:

import mach.text.cstring.convert;
import mach.text.cstring.length;
