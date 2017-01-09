module mach.range.asrange;

private:

/++ Docs

Many iterables, though they are not themselves ranges, should logically be
valid as ranges. For example, though an array is not itself a range, a range
can be created which enumerates its elements.

The `asrange` method may be implemented for any type; for example, the
collections in `mach.collect` typically have an `asrange` method.
The purpose of this package is to provide default `asrange` implementations
for primitive types: Specifically, arrays and associative arrays.
`asrange` is additionally implemented for ranges, in this case the function
simply returns its input.

Functions in mach which require a range to operate upon accept any iterable
valid as a range and internally call `asrange` with that iterable in order
to acquire a range. It is strongly recommended that code utilizing or extending
this library duplicate this pattern in its own functions operating upon ranges.

+/

unittest{ /// Example
    // Acquire a range from an array.
    auto range = [0, 1, 2, 3].asrange;
    assert(range.front == 0);
    assert(range.back == 3);
}

unittest{ /// Example
    // Acquire a range from an associative array.
    auto range = ["hello": "world"].asrange;
    assert(range.length == 1);
    assert(range.front.key == "hello");
    assert(range.front.value == "world");
    foreach(key, value; range){
        // The ranges produced for associative arrays
        // can be enumerated like associative arrays.
    }
}

unittest{ /// Example
    /// Acquire a range from a range.
    import mach.range.rangeof : rangeof;
    auto range = rangeof(0, 1, 2, 3);
    assert(range.asrange is range);
}

public:

import mach.range.asrange.as;

import mach.range.asrange.aarange;
import mach.range.asrange.arrayrange;
import mach.range.asrange.indexrange;
