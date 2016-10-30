module mach.math.floats.extract;

private:

import mach.traits : isFloatingPoint, IEEEFormat, IEEEFormatOf;
import mach.math.bits.extract : extractbit, extractbits;
import mach.math.bits.pow2 : pow2;
import mach.math.floats.properties : fissubnormal, fiszero;

public:



/// Extract the sign bit of a floating point value.
auto fextractsgn(T)(T value) if(isFloatingPoint!T){
    enum uint offset = IEEEFormatOf!T.sgnoffset;
    return value.extractbit!(offset);
}



/// Extract the exponent bits of a floating point value.
auto fextractexp(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum uint offset = Format.expoffset;
    enum uint size = Format.expsize;
    return value.extractbits!(uint, offset, size);
}

/// Get the exponent of a floating point value as a signed integer.
/// Respects subnormal and unnormal inputs.
auto fextractsexp(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    if(value.fissubnormal){
        return -(cast(int) Format.expsubnormal);
    }else{
        return cast(int) value.fextractexp - Format.expbias;
    }
}



/// Get the significand bits of a floating point value.
/// The specific meaning of these bits may vary depending on
/// the floating point type.
auto fextractsig(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum uint size = Format.sigsize;
    return value.extractbits!(0, size);
}

/// Get the significand bits of a floating point value
/// such the decimal place is always after the first digit,
/// regardless of the format of the input.
auto fextractnsig(T)(T value) if(isFloatingPoint!T){
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
auto fextractdiv(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum divshift = Format.sigsize - Format.intpart;
    return pow2!divshift;
}

/// Get the fractional value of a floating point value, itself
/// as a floating point value.
auto fextractfrac(F = double, T)(T value) if(isFloatingPoint!T){
    return cast(F) value.fextractnsig / value.fextractdiv;
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
}
unittest{
    tests("Float extract", {
        foreach(T; Aliases!(float, double, real)){
            tests(T.stringof, {
                // Test recomposition of normal, non-zero values
                foreach(x; [
                    T(1), T(-1),
                    T(256), T(-256),
                    T(1234), T(-1234),
                    T(100000), T(-100000),
                    T(1234.5), T(-1234.5),
                ]){
                    auto sgn = x.fextractsgn;
                    auto sexp = x.fextractsexp;
                    auto frac = x.fextractfrac;
                    auto y = T(2) ^^ sexp * frac;
                    testeq(x, sgn ? -y : y);
                }
            });
        }
    });
}
