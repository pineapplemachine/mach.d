module mach.math.abs.floats;

private:

import core.stdc.math : cfabs = fabs, fabsf;
import mach.traits.primitives : isFloatingPoint, isImaginary;
import mach.math.floats.inject : finjectsgn;
import mach.math.floats.properties : fisnan;

public @trusted:



/// Get the absolute value of a given floating point number.
T fabs(T)(in T value) if(isFloatingPoint!T){
    version(CRuntime_Microsoft){
        // MSVC libc `fabs` doesn't convert -nan to +nan
        if(value.fisnan) return value.finjectsgn(0);
    }
    static if(is(T == float)){
        return fabsf(value);
    }else static if(is(T == double)){
        return cfabs(value);
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
T imabs(T)(in T value) if(isImaginary!T){
    return T(fabs(value.im) * 1i);
}



private version(unittest){
    import mach.meta.aliases : Aliases;
    import mach.math.floats : fextractsgn;
}
unittest{
    foreach(T; Aliases!(float, double, real)){
        assert(fabs(T(0)) == 0);
        assert(fabs(T(1)) == 1);
        assert(fabs(T(-1)) == 1);
        assert(fabs(T(1.125)) == 1.125);
        assert(fabs(T(-1.125)) == 1.125);
        assert(fabs(T.infinity) == T.infinity);
        assert(fabs(-T.infinity) == T.infinity);
        assert(fabs(T.nan).fisnan);
        assert(!fabs(T.nan).fextractsgn);
        assert(fabs(-T.nan).fisnan);
        assert(!fabs(-T.nan).fextractsgn);
    }
    foreach(T; Aliases!(ifloat, idouble, ireal)){
        assert(imabs(T(0i)) == 0i);
        assert(imabs(T(1i)) == 1i);
        assert(imabs(T(-1i)) == 1i);
        assert(imabs(T(1.125i)) == 1.125i);
        assert(imabs(T(-1.125i)) == 1.125i);
        assert(imabs(T.infinity) == T.infinity);
        assert(imabs(-T.infinity) == T.infinity);
        assert(imabs(T.nan).im.fisnan);
        assert(!imabs(T.nan).im.fextractsgn);
        assert(imabs(-T.nan).im.fisnan);
        assert(!imabs(-T.nan).im.fextractsgn);
    }
}
