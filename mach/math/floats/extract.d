module mach.math.floats.extract;

private:

import mach.traits : isFloatingPoint, IEEEFormat, IEEEFormatOf;
import mach.math.bits.extract : extractbit, extractbits;
import mach.math.bits.pow2 : pow2;
import mach.math.floats.properties : fissubnormal, fiszero;

// previously used to implement fextractsgn but changed because it isn't pure
//import core.stdc.math : signbit;

pure public:



/// Extract the sign bit of a floating point value.
/// Guaranteed to behave correctly with NaN inputs at runtime.
/// Always returns false for NaN inputs in CTFE. (TODO: How to fix?)
bool fextractsgn(T)(in T value) if(isFloatingPoint!T){
    if(__ctfe) {
        static assert(T(1.0) / T(-0.0) == -T.infinity); // Sanity check
        return value < 0 || 1 / value < 0;
    }else {
        enum Format = IEEEFormatOf!T;
        enum uint offset = Format.sgnoffset;
        return extractbit!offset(value);
    }
}



/// Extract the exponent bits of a floating point value.
auto fextractexp(T)(in T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum uint offset = Format.expoffset;
    enum uint size = Format.expsize;
    return value.extractbits!(uint, offset, size);
}

/// Get the exponent of a floating point value as a signed integer.
/// Respects subnormal and unnormal inputs.
auto fextractsexp(T)(in T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    if(value.fissubnormal){
        return -(cast(int) Format.expsubnormal);
    }else{
        auto unbiased = cast(int) value.fextractexp;
        if(unbiased == 0) return int(1) - Format.expbias;
        else return unbiased - Format.expbias;
    }
}



/// Get the significand bits of a floating point value.
/// The specific meaning of these bits may vary depending on
/// the floating point type.
auto fextractsig(T)(in T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum uint size = Format.sigsize;
    return value.extractbits!(0, size);
}

/// Get the significand bits of a floating point value
/// such the decimal place is always after the first digit,
/// regardless of the format of the input.
auto fextractnsig(T)(in T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format.intpart){
        return value.fextractsig;
    }else{
        if(value.fissubnormal || value.fiszero){
            return value.fextractsig;
        }else{
            immutable size = Format.sigsize;
            // Funky edge case that should never happen
            // But if it does, give an error instead of incorrect behavior.
            static assert(size < typeof(value.fextractsig()).sizeof * 8);
            return pow2!size | value.fextractsig;
        }
    }
}



/// Get the significand divisor for a floating point type.
/// A float's fractional value is equal to the result of `fextractsig`
/// divided by this value.
auto fextractdiv(T)(in T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum divshift = Format.sigsize - Format.intpart;
    return pow2!divshift;
}

/// Get the fractional value of a floating point value, itself
/// as a floating point value.
auto fextractfrac(F = double, T)(in T value) if(isFloatingPoint!T){
    return cast(F) value.fextractnsig / value.fextractdiv;
}



private version(unittest) {
    import mach.meta : Aliases;
}

unittest { /// Test fextractsgn at runtime
    assert(fextractsgn(+0.0) == 0);
    assert(fextractsgn(-0.0) == 1);
    assert(fextractsgn(+1.0) == 0);
    assert(fextractsgn(-1.0) == 1);
    assert(fextractsgn(+double.infinity) == 0);
    assert(fextractsgn(-double.infinity) == 1);
    assert(fextractsgn(+double.nan) == 0);
    assert(fextractsgn(-double.nan) == 1);
}

unittest { /// Test fextractsgnz in CTFE
    static assert(fextractsgn(+0.0) == 0);
    static assert(fextractsgn(-0.0) == 1);
    static assert(fextractsgn(+1.0) == 0);
    static assert(fextractsgn(-1.0) == 1);
    static assert(fextractsgn(+double.infinity) == 0);
    static assert(fextractsgn(-double.infinity) == 1);
    static assert(fextractsgn(+double.nan) == 0);
    static assert(fextractsgn(-double.nan) == 0); // TODO: How to fix?
}

unittest { /// Test by recomposition of normal, non-zero values
    foreach(T; Aliases!(float, double, real)){
        foreach(x; [
            T(1), T(-1),
            T(256), T(-256),
            T(1234), T(-1234),
            T(100000), T(-100000),
            T(1234.5), T(-1234.5),
        ]){
            const sgn = x.fextractsgn;
            const sexp = x.fextractsexp;
            const frac = x.fextractfrac;
            const T y = T(2) ^^ sexp * frac;
            assert(x == sgn ? -y : y);
        }
    }
}
