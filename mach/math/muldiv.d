module mach.math.muldiv;

private:

import mach.traits : isIntegral, isFloatingPoint, LargerType;
import mach.math.abs : uabs;
import mach.math.bits.split : splitbits, mergebits;
import mach.math.ints.intproduct : intproduct;

/++ Docs

This module provides functions for performing the computation `x * y / w` for
inputs meeting various constraints.
When the inputs are integers, these computations are performed using only
integer math and will never overflow when the result of the computation is
representable of the input type.
Therefore, none of the provided functions will overflow if `abs(x) <= abs(y)`.

The module additionally provides a function for computing `x * y / (T.max + 1)`.
In this case, the input must satisfy the condition `abs(x) < abs(y)`.

The output of `muldiv` called with integers is not guaranteed to be accurately
rounded. However, these things are guaranteed:
If the result can fit in the given integer type, then it will not be incorrect
as a result of overflowing intermediate operations.
Additionally, when that condition holds, `muldiv(x*y, y, w) == x` and
`muldiv(x, y, w) <= muldiv(x + 1, y, w)`.

+/

unittest{ /// Example
    assert(muldiv(0, 16, 32) == 0); // 0 / 16 * 32 == 0
    assert(muldiv(4, 16, 32) == 8); // 4 / 16 * 32 == 8
    assert(muldiv(8, 16, 32) == 16); // 8 / 16 * 32 == 16
    assert(muldiv(12, 16, 32) == 24); // 12 / 16 * 32 == 24
    assert(muldiv(16, 16, 32) == 32); // 16 / 16 * 32 == 32
}

public:


/// Get `x / y * w`.
auto muldiv(T)(in T x, in T y, in T w) if(isFloatingPoint!T){
    return x * (w / y);
}

/// Ditto
auto muldiv(T)(in T x, in T y, in T w) if(isIntegral!T){
    static if(is(Larger: LargerType!T)){
        return cast(T)(cast(Larger) x * w / y);
    }else{
        return y > w ? muldiv_ygtw(x, y, w) : muldiv_yltew(x, y, w);
    }
}

/// Get `x / y * w` where `abs(y) > abs(w)`.
/// May overflow for large values of x or w when `x > y`.
auto muldiv_ygtw(T)(in T x, in T y, in T w) if(isIntegral!T){
    assert(y != 0 && uabs(y) > uabs(w));
    return muldiv_ygtw_xltey(x % y, y, w) + x / y * w;
}

/// Get `x / y * w` where `abs(y) > abs(w)` and `abs(x) <= abs(y)`.
/// TODO: The result of this function is not correctly rounded.
auto muldiv_ygtw_xltey(T)(in T x, in T y, in T w) if(isIntegral!T){
    assert(y != 0 && uabs(y) > uabs(w) && uabs(x) <= uabs(y));
    immutable q = y / w;
    immutable hx = x / q / 2;
    immutable hy = y / q / 2;
    return muldiv_yltew_xltey(hx, hy, w); // TODO: How to compensate for error?
}

/// Get `x / y * w` where `x/y = z/w` for z where `abs(y) <= abs(w)`.
/// May overflow for large values of x or w when `x > y`.
auto muldiv_yltew(T)(in T x, in T y, in T w) if(isIntegral!T){
    assert(y != 0 && uabs(y) <= uabs(w));
    return muldiv_yltew_xltey(x % y, y, w) + x / y * w;
}

/// Get `x / y * w` where `abs(y) <= abs(w)` and `abs(x) <= abs(y)`.
auto muldiv_yltew_xltey(T)(in T x, in T y, in T w) if(isIntegral!T){
    assert(y != 0 && uabs(y) <= uabs(w) && uabs(x) <= uabs(y));
    // immutable quotient = w / y;
    // immutable remainder = w % y;
    // immutable error = remainder / (y/x); // should be remainder / (y/x)
    // return x * quotient + error;
    return x == 0 ? 0 : x * (w / y) + ((w % y) / (y / x));
}

/// Get `x / y * w` where `w = T.max + 1` and `abs(x) < abs(y)`.
auto muldiv_xlty_wmax(T)(in T x, in T y) if(isIntegral!T){
    assert(y != 0 && uabs(x) < uabs(y));
    static if(is(Larger: LargerType!T)){
        enum w = (cast(Larger) T.max + 1);
        return x * w / y;
    }else{
        return x == 0 ? 0 : (
            x * ((T.max / 2 + 1) / y * 2 + y % 2) +
            ((((T.max % y) + 1) % y) / (y / x))
        );
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.round : floor;
}

unittest{
    foreach(T; Aliases!(int, uint, long, ulong)){
        assert(muldiv(T(0), T(8), T(4)) == 0);
        assert(muldiv(T(4), T(8), T(4)) == 2);
        assert(muldiv(T(8), T(8), T(4)) == 4);
        assert(muldiv(T(0), T(6), T(12)) == 0);
        assert(muldiv(T(3), T(6), T(12)) == 6);
        assert(muldiv(T(6), T(6), T(12)) == 12);
    }
}

unittest{
    assert(muldiv(1.0, 2.0, 3.0) == 1.5);
    assert(muldiv(2.0, 1.0, 3.0) == 6.0);
}

unittest{
    foreach(i; 1 .. 10){
        assert(muldiv_yltew(0, i, 10) == 0);
        assert(muldiv_yltew(i, i, 10) == 10);
        assert(muldiv_yltew(i + i, i, 10) == 20);
        if(i % 2 == 0) assert(muldiv_yltew(i / 2, i, 10) == 5);
        foreach(j; 1 .. i + i){
            assert(muldiv_yltew(j, i, 10) > muldiv_yltew(j - 1, i, 10));
        }
    }
}

unittest{
    foreach(i; 5 .. 20){
        assert(muldiv_ygtw(0, i, 4) == 0);
        assert(muldiv_ygtw(i, i, 4) == 4);
        assert(muldiv_ygtw(i + i, i, 4) == 8);
        // TODO: Make output accurate enough for this to be reliable
        //if(i % 2 == 0) assert(muldiv_ygtw(i / 2, i, 4) == 2);
        foreach(j; 1 .. i + i){
            assert(muldiv_ygtw(j, i, 4) >= muldiv_ygtw(j - 1, i, 4));
        }
    }
}

unittest{
    assert(muldiv_xlty_wmax(uint(0), uint(4)) == 0);
    assert(muldiv_xlty_wmax(uint(1), uint(4)) == uint.max / 4 + 1);
    assert(muldiv_xlty_wmax(uint(2), uint(4)) == uint.max / 2 + 1);
    assert(muldiv_xlty_wmax(uint(3), uint(4)) == uint.max / 4 + uint.max / 2 + 2);
}
