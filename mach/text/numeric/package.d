module mach.text.numeric;

private:

/++ Docs

This package provides functions for parsing and serializing numbers.

Of note are the `parsenumber` and `writenumber` functions, which are
generic implementations handling integer and floating point primitives of
any type.

+/

unittest{ /// Example
    assert("100".parsenumber!int == 100);
    assert("1234.5".parsenumber!double == double(1234.5));
}

unittest{ /// Example
    assert(int(200).writenumber == "200");
    assert(double(456.789).writenumber == "456.789");
}

public:

import mach.text.numeric.combined;
import mach.text.numeric.exceptions;
import mach.text.numeric.floats;
import mach.text.numeric.integrals;
