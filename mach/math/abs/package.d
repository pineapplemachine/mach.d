module mach.math.abs;

private:

/++ Docs

This module implements the `abs` function, as well as a `uabs` function.

`abs` can be applied to any numeric or imaginary primitive. When its input
is positive, it returns its input. When its input is negative, it returns the
negation of its input.
The output will always be the same numeric type as the input.

+/

unittest{ /// Example
    assert(abs(10) == 10);
    assert(abs(-20) == 20);
}

unittest{ /// Example
    // `abs` accepts imaginary inputs.
    assert(abs(10i) == 10i);
    assert(abs(-20i) == 20i);
}

unittest{ /// Example
    // This module guarantees that `abs(-float.nan)` is always `+float.nan`.
    import mach.math.floats : fextractsgn, fisnan;
    assert(abs(-float.nan).fisnan); // Is nan?
    assert(abs(-float.nan).fextractsgn == false); // Is positive nan?
}

/++ Docs

The functionally similar `uabs` applies only to integral types,
and always returns an unsigned integer.
The `uabs` function exists because signed numeric primitives are not able
to correctly store the absolute value of their smallest representable value.
Their unsigned counterparts, however, are subject to no such limitation.

+/

unittest{ /// Example
    assert(abs(int.min) < 0); // This is a limitation of the `int` type!
    assert(uabs(int.min) > 0); // Which `uabs` is not affected by.
}

public:

import mach.math.abs.floats;
import mach.math.abs.ints;
