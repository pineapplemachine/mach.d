module mach.math.juggler;

private:

import std.traits : isIntegral, isFloatingPoint;
import std.math : pow;
import mach.range : recur;

public:



/// Determine whether the types are valid for juggler sequence calculation.
enum canJuggler(N, F = real) = isIntegral!N && isFloatingPoint!F;



/// Get a range which enumerates the juggler sequence of a given number.
/// Reference: https://en.wikipedia.org/wiki/Juggler_sequence
auto jugglerseq(N, F = real)(N value) if(canJuggler!(N, F)) in{
    assert(value >= 1, "Operation is only meaningful for positive integers.");
}body{
    return value.recur!(
        (in N n) => (cast(N)(cast(F) n.pow(n % 2 == 0 ? 0.5 : 1.5))),
        (in N n) => (n <= 1), true
    );
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Juggler sequence", {
        test(jugglerseq(1).equals([1]));
        test(jugglerseq(2).equals([2, 1]));
        test(jugglerseq(3).equals([3, 5, 11, 36, 6, 2, 1]));
        test(jugglerseq(4).equals([4, 2, 1]));
        test(jugglerseq(5).equals([5, 11, 36, 6, 2, 1]));
        fail({jugglerseq(0);});
        fail({jugglerseq(-1);});
    });
}
