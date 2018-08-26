module mach.math.abs.floats;

private:

import core.stdc.math : fabs, fabsf;
import mach.traits : isFloatingPoint, isImaginary;
import mach.math.floats : finjectsgn, fisnan;

public:



/// Get the absolute value of a given floating point number.
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
/// Get the absolute value of a given imaginary number.
T abs(T)(in T value) if(isImaginary!T){
    return T(abs(value.im) * 1i);
}



private version(unittest){
    import mach.meta.aliases : Aliases;
    import mach.math.floats : fextractsgn;
}
unittest{
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
