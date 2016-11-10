module mach.math.bits.pow2;

private:

import mach.traits : isIntegral, isSigned;
import mach.math.bits.hamming : hamming;

public:



/// Get as an alias the smallest primitive unsigned integer type
/// out of uint, ulong, and ucent, which is at least the given
/// number of bits long.
template MinInt(size_t size){
    static if(size <= 32) alias MinInt = uint;
    else static if(size <= 64) alias MinInt = ulong;
    else static if(size <= 128 && is(ucent)) alias MinInt = ucent;
    else static assert(false, "Value too large for any numeric primitive.");
}



/// Utility function for getting a power of two at compile time.
/// Returns the smallest primitive able to store the given type out of
/// uint, ulong, and ucent.
template pow2(size_t pow){
    static if(pow < 32) enum pow2 = uint(1) << pow;
    else static if(pow < 64) enum pow2 = ulong(1) << pow;
    else static if(pow < 128 && is(ucent)) enum pow2 = ucent(1) << pow;
    else static assert(false, "Value too large to fit in any numeric primitive.");
}

/// Get a power of two stored in the given primitive integral type.
/// Throws an assertion error if the integral isn't big enough to fit the number.
auto pow2(T)(in size_t pow) if(isIntegral!T) in{
    assert(pow < T.sizeof * 8, "Value too large to fit in the given type.");
}body{
    return T(1) << pow;
}




/// Utility function for getting a power of two minus one at compile time.
/// Returns the smallest primitive able to store the given type out of
/// uint, ulong, and ucent.
template pow2d(size_t pow) if(pow > 0){
    static if(pow < 32) enum pow2d = (uint(1) << pow) - 1;
    else static if(pow == 32) enum pow2d = ~uint(0);
    else static if(pow < 64) enum pow2d = (ulong(1) << pow) - 1;
    else static if(pow == 64) enum pow2d = ~ulong(0);
    else static if(pow < 128 && is(ucent)) enum pow2d = (ucent(1) << pow) - 1;
    else static if(pow == 128 && is(ucent)) enum pow2d = ~ucent(0);
    else static assert(false, "Value too large to fit in any numeric primitive.");
}

/// Get a power of two minus one stored in the given primitive integral type.
/// Throws an assertion error if the integral isn't big enough to fit the number.
auto pow2d(T)(in size_t pow) if(isIntegral!T) in{
    assert(pow >= 0 && pow <= T.sizeof * 8,
        "Value too large to fit in the given type."
    );
}body{
    if(pow == T.sizeof * 8) return ~T(0);
    else return (T(1) << pow) - 1;
}



/// Get whether a number is a power of two.
/// TODO: Overrides for signed and float types
bool ispow2(T)(T n) if(isIntegral!T && !isSigned!T){
    return n == 0 || n.hamming == 1;
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
}

unittest{
    static assert(is(MinInt!5 == uint));
    static assert(is(MinInt!8 == uint));
    static assert(is(MinInt!32 == uint));
    static assert(is(MinInt!33 == ulong));
    static assert(is(MinInt!64 == ulong));
    static if(is(ucent)){
        static assert(is(MinInt!65 == ucent));
        static assert(is(MinInt!128 == ucent));
    }
}

unittest{
    tests("pow2", {
        static assert(pow2!0 == 1);
        static assert(pow2!1 == 2);
        static assert(pow2!2 == 4);
        testeq(pow2!uint(0), 1);
        testeq(pow2!uint(1), 2);
        testeq(pow2!uint(2), 4);
        foreach(i; Aliases!(0, 1, 2, 3, 7, 8, 16, 30, 31, 32, 63)){
            alias T = MinInt!(i + 1);
            static assert(pow2!i == ulong(1) << i);
            static assert(is(typeof(pow2!i) == T));
            static assert(is(typeof(pow2!T(i)) == T));
            testeq(pow2!T(i), pow2!i);
        }
    });
}

unittest{
    tests("pow2d", {
        static assert(pow2d!1 == 1);
        static assert(pow2d!2 == 3);
        static assert(pow2d!3 == 7);
        testeq(pow2d!uint(1), 1);
        testeq(pow2d!uint(2), 3);
        testeq(pow2d!uint(3), 7);
        foreach(i; Aliases!(1, 2, 3, 7, 8, 16, 30, 31, 32, 33, 63, 64)){
            alias T = MinInt!i;
            static if(i != 64){
                static assert(pow2d!i == (ulong(1) << i) - 1);
            }else{
                static assert(pow2d!i == ~ulong(0));
            }
            static assert(is(typeof(pow2d!i) == T));
            static assert(is(typeof(pow2d!T(i)) == T));
            testeq(pow2d!T(i), pow2d!i);
        }
    });
}

unittest{
    tests("ispow2", {
        test(0u.ispow2);
        test(1u.ispow2);
        test(2u.ispow2);
        test(4u.ispow2);
        test(8u.ispow2);
        test(16u.ispow2);
        test(256u.ispow2);
        test(65536u.ispow2);
        test(uint(1 << 30).ispow2);
        testf(3u.ispow2);
        testf(5u.ispow2);
        testf(11u.ispow2);
        testf(100000u.ispow2);
    });
}
