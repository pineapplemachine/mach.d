module mach.math.lcm;

private:

import mach.types : Rebindable;
import mach.math.abs : abs;

/++ Docs

This module makes available the `gcd` and `lcm` functions for determining the
greatest common divisor and least common multiple of two numbers, respectively.
When both inputs to `gcd` are 0, 0 is returned. When any input to `lcm` is 0,
0 is returned. In all other cases (except, potentially, for overflow in the case
of least common multiple) the outputs of `gcd` and `lcm` are positive integers.

+/

unittest{ /// Example
    // The greatest common divisor of 100 and 24 is 4.
    assert(gcd(100, 24) == 4);
    // The least common multiple of 100 and 24 is 600.
    assert(lcm(100, 24) == 600);
}

public:



/// Get the greatest common divisor of two integers.
/// Always returns a positive number less than or equal to the smaller input.
/// Except in the case where both inputs are 0, in which case 0 is returned.
/// https://en.wikipedia.org/wiki/Euclidean_algorithm
auto gcd(N)(in N a, in N b){
    Rebindable!N workinga = a.abs;
    Rebindable!N workingb = b.abs;
    while(workingb != 0){
        auto t = workingb;
        workingb = workinga % workingb;
        workinga = t;
    }
    return cast(N) workinga;
}

/// Get the least common multiple of two integers.
/// Always returns a positive integer, except for when any input is 0, in which
/// case the function returns 0.
/// https://en.wikipedia.org/wiki/Least_common_multiple#Reduction_by_the_greatest_common_divisor
auto lcm(N)(in N a, in N b){
    if(a == 0 || b == 0) return N(0);
    return (a / gcd(a, b) * b).abs;
}



unittest{ /// Greatest common divisor
    assert(gcd(0, 0) == 0);
    assert(gcd(1, 0) == 1);
    assert(gcd(0, 1) == 1);
    assert(gcd(1, 1) == 1);
    assert(gcd(1, 2) == 1);
    assert(gcd(2, 1) == 1);
    assert(gcd(2, 2) == 2);
    assert(gcd(2, 4) == 2);
    assert(gcd(4, 2) == 2);
    assert(gcd(32, 2) == 2);
    assert(gcd(120, 2) == 2);
    assert(gcd(15, 35) == 5);
    assert(gcd(+15, -35) == 5);
    assert(gcd(-15, +35) == 5);
    assert(gcd(-15, -35) == 5);
}

unittest{ /// Least common multiple
    assert(lcm(0, 0) == 0);
    assert(lcm(1, 0) == 0);
    assert(lcm(0, 1) == 0);
    assert(lcm(1, 1) == 1);
    assert(lcm(1, 2) == 2);
    assert(lcm(2, 1) == 2);
    assert(lcm(2, 2) == 2);
    assert(lcm(2, 4) == 4);
    assert(lcm(4, 2) == 4);
    assert(lcm(2, 5) == 10);
    assert(lcm(5, 2) == 10);
    assert(lcm(4, 6) == 12);
    assert(lcm(6, 4) == 12);
    assert(lcm(+4, -6) == 12);
    assert(lcm(-4, +6) == 12);
    assert(lcm(-4, -6) == 12);
}
