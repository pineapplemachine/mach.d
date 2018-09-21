module mach.math.collatz;

private:

import mach.traits.primitives : isIntegral;
import mach.range.recur : recur;

/++ Docs

The `collatzseq` function returns a range which enumerates the values in the
[Collatz sequence](https://en.wikipedia.org/wiki/Collatz_conjecture) of an input.

+/

unittest { /// Example
    import mach.range.compare : equals;
    assert(collatzseq(3).equals([3, 10, 5, 16, 8, 4, 2, 1]));
}

public:



/// Get a range which enumerates the Collatz sequence of a given number.
auto collatzseq(N)(N value) if(isIntegral!N) in{
    assert(value >= 1, "Operation is only meaningful for positive integers.");
}body{
    return value.recur!(
        (in N n) => (n % 2 == 0 ? n / 2 : n * 3 + 1),
        (in N n) => (n <= 1), true
    );
}



private version(unittest) {
    import mach.range.compare : equals;
    import mach.test.assertthrows : assertthrows;
}

/// Valid inputs
unittest {
    assert(collatzseq(1).equals([1]));
    assert(collatzseq(2).equals([2, 1]));
    assert(collatzseq(3).equals([3, 10, 5, 16, 8, 4, 2, 1]));
}

/// Invalid inputs
unittest {
    assertthrows({auto x = collatzseq(0);});
    assertthrows({auto x = collatzseq(-1);});
}
