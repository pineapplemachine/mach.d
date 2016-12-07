module mach.math.abs;

private:

import core.stdc.math : fabs, fabsf;
import mach.traits : isFloatingPoint, isImaginary;
import mach.traits : isSignedIntegral, isUnsignedIntegral;
import mach.math.floats : finjectsgn;

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



version(unittest){
    private:
    import mach.meta : Aliases;
    import mach.math.floats : fextractsgn, fisnan;
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
        assert(abs(T.nan).fisnan && !abs(T.nan).fextractsgn);
        assert(abs(-T.nan).fisnan && !abs(-T.nan).fextractsgn);
    }
    foreach(T; Aliases!(ifloat, idouble, ireal)){
        assert(abs(T(0i)) == 0i);
        assert(abs(T(1i)) == 1i);
        assert(abs(T(-1i)) == 1i);
        assert(abs(T(1.125i)) == 1.125i);
        assert(abs(T(-1.125i)) == 1.125i);
        assert(abs(T.infinity) == T.infinity);
        assert(abs(-T.infinity) == T.infinity);
        assert(abs(T.nan).im.fisnan && !abs(T.nan).im.fextractsgn);
        assert(abs(-T.nan).im.fisnan && !abs(-T.nan).im.fextractsgn);
    }
}
