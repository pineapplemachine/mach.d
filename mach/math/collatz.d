module mach.math.collatz;

private:

import mach.traits : isIntegral;
import mach.range : recur;

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



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Collatz sequence", {
        test(collatzseq(1).equals([1]));
        test(collatzseq(2).equals([2, 1]));
        test(collatzseq(3).equals([3, 10, 5, 16, 8, 4, 2, 1]));
        testfail({collatzseq(0);});
        testfail({collatzseq(-1);});
    });
}
