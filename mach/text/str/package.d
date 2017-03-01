module mach.text.str;

private:

/++ Docs

This package implements the `str` function, which may be used to generate a
useful string representation of just about anything.

+/

unittest{ /// Example
    assert(str("Hello!") == "Hello!");
    assert(str(1234) == "1234");
}

public:

import mach.text.str.settings;
import mach.text.str.str;
