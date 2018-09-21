module mach.math.juggler;

private:

import mach.traits : isIntegral, isFloatingPoint;
import mach.range : recur;

public:



/// Get a range which enumerates the juggler sequence of a given number.
/// Reference: https://en.wikipedia.org/wiki/Juggler_sequence
auto jugglerseq(N, F = double)(N value) if(
    isIntegral!N && isFloatingPoint!F
) in{
    assert(value >= 1, "Operation is only meaningful for positive integers.");
}body{
    return value.recur!(
        (in N n) => (cast(N)(cast(F) n ^^ (n % 2 == 0 ? 0.5 : 1.5))),
        (in N n) => (n <= 1), true
    );
}



private version(unittest) {
    import mach.range.compare : equals;
    import mach.test.assertthrows : assertthrows;
}

/// Valid inputs
unittest {
    assert(jugglerseq(1).equals([1]));
    assert(jugglerseq(2).equals([2, 1]));
    assert(jugglerseq(3).equals([3, 5, 11, 36, 6, 2, 1]));
    assert(jugglerseq(4).equals([4, 2, 1]));
    assert(jugglerseq(5).equals([5, 11, 36, 6, 2, 1]));
}

/// Invalid inputs
unittest {
    assertthrows({auto x = jugglerseq(0);});
    assertthrows({auto x = jugglerseq(-1);});
}
