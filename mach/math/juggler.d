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



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Juggler sequence", {
        test(jugglerseq(1).equals([1]));
        test(jugglerseq(2).equals([2, 1]));
        test(jugglerseq(3).equals([3, 5, 11, 36, 6, 2, 1]));
        test(jugglerseq(4).equals([4, 2, 1]));
        test(jugglerseq(5).equals([5, 11, 36, 6, 2, 1]));
        testfail({jugglerseq(0);});
        testfail({jugglerseq(-1);});
    });
}
