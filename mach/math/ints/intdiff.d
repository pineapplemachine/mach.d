module mach.math.ints.intdiff;

private:

import mach.traits : isIntegral, isUnsigned, Unsigned;

/++ Docs

The `intdiff` function returns the positive difference of two integers as an
unsigned integer.
For unsigned inputs this is a trivial operation but for signed inputs some
extra logic is required to get the difference between values without causing
integer overflow. (Hence the existence of this function.)

+/

unittest{ /// Example
    assert(intdiff(int.min, int.max) == uint.max);
    assert(intdiff(ulong.min, ulong.max) == ulong.max);
}

public:



/// Get the positive difference of two signed or unsigned integers as an
/// unsigned integer.
T intdiff(T)(in T a, in T b) if(isIntegral!T){
    static if(isUnsigned!T){
        return a > b ? a - b : b - a;
    }else{
        if(b < 0 && a >= 0) return cast(Unsigned!T) a + cast(Unsigned!T) -b;
        else if(a < 0 && b >= 0) return cast(Unsigned!T) b + cast(Unsigned!T) -a;
        else return cast(Unsigned!T)(a > b ? a - b : b - a);
    }
}



unittest{
    assert(intdiff(int(0), int(0)) == 0);
    assert(intdiff(uint(0), uint(0)) == 0);
    assert(intdiff(int(0), int(100)) == 100);
    assert(intdiff(uint(0), uint(100)) == 100);
    assert(intdiff(int.min, int.max) == uint.max);
    assert(intdiff(uint.min, uint.max) == uint.max);
    assert(intdiff(long.min, long.max) == ulong.max);
    assert(intdiff(ulong.min, ulong.max) == ulong.max);
}
