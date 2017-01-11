module mach.math.abs;

private:

import core.stdc.math : fabs, fabsf;
import mach.traits : Unsigned, isFloatingPoint, isImaginary;
import mach.traits : isSignedIntegral, isUnsignedIntegral;
import mach.math.floats : finjectsgn, fisnan;

/++ Docs

This module implements the `abs` function, as well as a `uabs` function.

`abs` can be applied to any numeric or imaginary primitive. When its input
is positive, it returns its input. When its input is negative, it returns the
negation of its input.
The output will always be the same numeric type as the input.

+/

unittest{ /// Example
    assert(abs(10) == 10);
    assert(abs(-20) == 20);
}

unittest{ /// Example
    // `abs` accepts imaginary inputs.
    assert(abs(10i) == 10i);
    assert(abs(-20i) == 20i);
}

unittest{ /// Example
    // This module guarantees that `abs(-float.nan)` is always `+float.nan`.
    import mach.math.floats : fextractsgn, fisnan;
    assert(abs(-float.nan).fisnan); // Is nan?
    assert(abs(-float.nan).fextractsgn == false); // Is positive nan?
}

/++ Docs

The functionally similar `uabs` applies only to integral types,
and always returns an unsigned integer.
The `uabs` function exists because signed numeric primitives are not able
to correctly store the absolute value of their smallest representable value.
Their unsigned counterparts, however, are subject to no such limitation.

+/

unittest{ /// Example
    assert(abs(int.min) < 0); // This is a limitation of the `int` type!
    assert(uabs(int.min) > 0); // Which `uabs` is not affected by.
}

public:



/// Get the absolute value of a given number.
T abs(T)(in T value) if(isUnsignedIntegral!T){
    return value;
}
/// ditto
T abs(T)(in T value) if(isSignedIntegral!T){
    return value >= 0 ? value : -value;
}
/// ditto
T abs(T)(in T value) if(isFloatingPoint!T){
    version(CRuntime_Microsoft){
        // MSVC libc `fabs` doesn't convert -nan to +nan
        if(value.fisnan) return value.finjectsgn(0);
    }
    static if(is(T == float)){
        return fabsf(value);
    }else static if(is(T == double)){
        return fabs(value);
    }else static if(is(T == real)){
        // core.std.math.fabsl not used because it casts the input to double
        // before determining absolute value.
        return value.finjectsgn(0);
    }else{
        // Shouldn't happen
        static assert(false, "Unknown floating point type.");
    }
}
/// ditto
T abs(T)(in T value) if(isImaginary!T){
    return T(abs(value.im) * 1i);
}



/// Get the absolute value of a signed or unsigned integer,
/// and get an unsigned integer back.
/// This functionality is significant because the absolute value of,
/// for example, `int.min` is not actually storeable in an int.
T uabs(T)(in T value) if(isUnsignedIntegral!T){
    return value;
}
/// ditto
Unsigned!T uabs(T)(in T value) if(isSignedIntegral!T){
    if(value >= 0) return cast(Unsigned!T) value;
    else if(value == T.min) return (cast(Unsigned!T) T.max) + 1;
    else return cast(Unsigned!T) -value;
}



version(unittest){
    private:
    import mach.meta : Aliases;
    import mach.math.floats : fextractsgn;
}
unittest{
    foreach(T; Aliases!(ubyte, ushort, uint, ulong)){
        assert(abs(T(0)) == 0);
        assert(abs(T(1)) == 1);
    }
    foreach(T; Aliases!(byte, short, int, long)){
        assert(abs(T(0)) == 0);
        assert(abs(T(1)) == 1);
        assert(abs(T(-1)) == 1);
    }
    foreach(T; Aliases!(float, double, real)){
        assert(abs(T(0)) == 0);
        assert(abs(T(1)) == 1);
        assert(abs(T(-1)) == 1);
        assert(abs(T(1.125)) == 1.125);
        assert(abs(T(-1.125)) == 1.125);
        assert(abs(T.infinity) == T.infinity);
        assert(abs(-T.infinity) == T.infinity);
        assert(abs(T.nan).fisnan);
        assert(!abs(T.nan).fextractsgn);
        assert(abs(-T.nan).fisnan);
        assert(!abs(-T.nan).fextractsgn);
    }
    foreach(T; Aliases!(ifloat, idouble, ireal)){
        assert(abs(T(0i)) == 0i);
        assert(abs(T(1i)) == 1i);
        assert(abs(T(-1i)) == 1i);
        assert(abs(T(1.125i)) == 1.125i);
        assert(abs(T(-1.125i)) == 1.125i);
        assert(abs(T.infinity) == T.infinity);
        assert(abs(-T.infinity) == T.infinity);
        assert(abs(T.nan).im.fisnan);
        assert(!abs(T.nan).im.fextractsgn);
        assert(abs(-T.nan).im.fisnan);
        assert(!abs(-T.nan).im.fextractsgn);
    }
}
unittest{
    foreach(T; Aliases!(ubyte, ushort, uint, ulong)){
        assert(uabs(T(0)) == 0);
        assert(uabs(T(1)) == 1);
    }
    foreach(T; Aliases!(byte, short, int, long)){
        assert(uabs(T(0)) == 0);
        assert(uabs(T(1)) == 1);
        assert(uabs(T(-1)) == 1);
        assert(uabs(T.min) == (cast(Unsigned!T) T.max) + 1);
    }
}
