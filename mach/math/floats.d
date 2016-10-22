module mach.math.floats;

private:

import mach.traits : isIntegral, isFloatingPoint, IEEEFormat, IEEEFormatOf;
import mach.math.bits : extractbit, extractbits;

public:



/// Utility function for getting a power of two at compile time.
/// Returns the smallest primitive able to store the given type out of
/// uint, ulong, and ucent.
private auto pow2(size_t pow)(){
    static if(pow < 32) return uint(1) << pow;
    else static if(pow < 64) return ulong(1) << pow;
    else static if(pow < 128 && is(ucent)) return ucent(1) << pow;
    else static assert(false, "Power too large to fit in any numeric primitive.");
}



/// Extract the sign bit of a floating point value.
auto extractfsgn(T)(T value) if(isFloatingPoint!T){
    enum uint offset = IEEEFormatOf!T.sgnoffset;
    return value.extractbit!(offset);
}

/// Extract the exponent bits of a floating point value.
auto extractfexp(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum uint offset = Format.expoffset;
    enum uint size = Format.expsize;
    return value.extractbits!(uint, offset, size);
}

/// Get the exponent of a floating point value as a signed integer.
/// Respects subnormal and unnormal inputs.
auto extractfsexp(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        if(value.issubnormal){
            return -(cast(int) Format.expsubnormal);
        }else if(value.isunnormal){
            return -(cast(int) Format.expbias);
        }else{
            return cast(int) value.extractfexp - Format.expbias;
        }
    }else{
        if(value.issubnormal){
            return -(cast(int) Format.expsubnormal);
        }else{
            return cast(int) value.extractfexp - Format.expbias;
        }
    }
}

/// Get the significand bits of a floating point value.
/// The specific meaning of these bits may vary depending on
/// the floating point type.
auto extractfsig(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum uint offset = Format.sigoffset;
    enum uint size = Format.sigsize;
    return value.extractbits!(offset, size);
}

/// Get the significand bits of a floating point value
/// such the decimal place is always after the first digit,
/// regardless of the format of the input.
auto extractfnsig(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format.intpart){
        return value.extractfsig;
    }else{
        if(value.issubnormal){
            return value.extractfsig;
        }else{
            // Funky edge case that should never happen
            // But if it does, give an error instead of incorrect behavior.
            immutable size = Format.sigsize;
            static assert(size < typeof(value.extractfsig()).sizeof * 8);
            return pow2!size | value.extractfsig;
        }
    }
}

/// Get the significand divisor for a floating point type.
/// A float's fractional value is equal to the result of `extractfsig`
/// divided by this value.
auto extractfdiv(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    enum divshift = Format.sigsize - Format.intpart;
    return pow2!divshift;
}

/// Get the fractional value of a floating point value, itself
/// as a floating point value.
auto extractffrac(F = double, T)(T value) if(isFloatingPoint!T){
    return cast(F) value.extractfnsig / value.extractfdiv;
}



/// Get whether a floating point value represents an infinite value.
auto isinf(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        return(
            value.extractfexp == Format.expmax &&
            value.extractbits!(0, 63) == 0
        );
    }else{
        return(
            value.extractfexp == Format.expmax &&
            value.extractfsig == 0
        );
    }
}

/// Get whether a floating point value represents NaN.
/// Also evaluates true for pseudo-infinity.
auto isnan(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        return(
            value.extractfexp == Format.expmax &&
            value.extractbits!(0, 63) != 0
        );
    }else{
        return(
            value.extractfexp == Format.expmax &&
            value.extractfsig != 0
        );
    }
}

/// Get whether a floating point value represents a subnormal number.
/// Also evaluates true for pseudo-subnormals.
auto issubnormal(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        return(
            value.extractfexp == 0 && (
                value.extractbit!63 ||
                value.extractbits!(0, 63) != 0
            )
        );
    }else{
        return(
            value.extractfexp == 0 &&
            value.extractfsig != 0
        );
    }
}

/// Get whether a floating point value represents a unnormal number.
/// Only meaningful for x86 extended precision prior to the 80387 processor.
auto isunnormal(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        immutable exp = value.extractfexp;
        return(
            exp != 0 && exp != Format.expmax &&
            value.extractbit!63 == 0
        );
    }else{
        return false;
    }
}

/// Get whether a floating point value represents a normal number.
/// A normal number is any that is not NaN, not infinite, not subnormal,
/// and not unnormal.
auto isnormal(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    immutable exp = value.extractfexp;
    static if(Format is IEEEFormat.Extended){
        return(
            (exp == 0 && value.extractfsig == 0) ||
            (exp != 0 && exp != Format.expmax && value.extractbit!63 != 0)
        );
    }else{
        return(
            (exp == 0 && value.extractfsig == 0) ||
            (exp != 0 && exp != Format.expmax)
        );
    }
}

/// Get whether a floating point value represents zero.
auto iszero(T)(T value) if(isFloatingPoint!T){
    return value.extractfexp == 0 && value.extractfsig == 0;
}



/// For sake of uniformity, define `isnan`, `isinf`, etc. for integrals, too.
auto isinf(T)(T value) if(isIntegral!T){
    return false;
}
/// ditto
auto isnan(T)(T value) if(isIntegral!T){
    return false;
}
/// ditto
auto issubnormal(T)(T value) if(isIntegral!T){
    return false;
}
/// ditto
auto isunnormal(T)(T value) if(isIntegral!T){
    return false;
}
/// ditto
auto isnormal(T)(T value) if(isIntegral!T){
    return true;
}
/// ditto
auto iszero(T)(T value) if(isIntegral!T){
    return value == 0;
}



version(unittest){
    private:
    import mach.test;
    
    import mach.meta : Aliases;
    import mach.io.log;
    import mach.text.parse.numeric.integrals;
}
unittest{
    tests("Float decomposition", {
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
                    auto sgn = x.extractfsgn;
                    auto sexp = x.extractfsexp;
                    auto frac = x.extractffrac;
                    auto y = T(2) ^^ sexp * frac;
                    testeq(x, sgn ? -y : y);
                }
                // Test detection of zero
                test(T(0).iszero);
                test((-T(0)).iszero);
                testf(T(1).iszero);
                testf(T(-1).iszero);
                testf(T.infinity.iszero);
                testf((-T.infinity).iszero);
                testf(T.nan.iszero);
                // Test detection of normal
                test(T(0).isnormal);
                test((-T(0)).isnormal);
                test(T(1).isnormal);
                test(T(-1).isnormal);
                testf(T.infinity.isnormal);
                testf((-T.infinity).isnormal);
                testf(T.nan.isnormal);
                // Test detection of infinity
                test(T.infinity.isinf);
                test((-T.infinity).isinf);
                testf(T(0).isinf);
                testf(T(1).isinf);
                testf(T(-1).isinf);
                testf(T.nan.isinf);
                // Test detection of NaN
                test(T.nan.isnan);
                testf(T(0).isnan);
                testf(T(1).isnan);
                testf(T(-1).isnan);
                testf(T.infinity.isnan);
                testf((-T.infinity).isnan);
                /// Test detection of subnormal
                testf(T(0).issubnormal);
                testf((-T(0)).issubnormal);
                testf(T(1).issubnormal);
                testf(T(-1).issubnormal);
                testf(T.infinity.issubnormal);
                testf((-T.infinity).issubnormal);
                testf(T.nan.issubnormal);
                /// Test detection of unnormal
                testf(T(0).isunnormal);
                testf((-T(0)).isunnormal);
                testf(T(1).isunnormal);
                testf(T(-1).isunnormal);
                testf(T.infinity.isunnormal);
                testf((-T.infinity).isunnormal);
                testf(T.nan.isunnormal);
            });
        }
        tests("Subnormal and unnormal values", {
            {
                // Subnormal float
                uint subfi = 0x007fffff;
                float subf = *(cast(float*) &subfi);
                test(subf.issubnormal);
                testf(subf.isunnormal);
                testf(subf.isnormal);
                testf(subf.iszero);
                testf(subf.isinf);
                testf(subf.isnan);
            }{
                // Subnormal double
                ulong subdi = 0x000fffffffffffff;
                double subd = *(cast(double*) &subdi);
                test(subd.issubnormal);
                testf(subd.isunnormal);
                testf(subd.isnormal);
                testf(subd.iszero);
                testf(subd.isinf);
                testf(subd.isnan);
            }
            // TODO: Is it feasible that a big endian CPU could fail these tests?
            static if(IEEEFormatOf!real is IEEEFormat.Extended){
                // Subnormal x86 extended float
                uint[3] subi = [
                    0xffffffff,
                    0xffffffff,
                    0x00000000,
                ];
                real sub = *(cast(real*) &subi);
                test(sub.issubnormal);
                testf(sub.isunnormal);
                testf(sub.isnormal);
                testf(sub.iszero);
                testf(sub.isinf);
                testf(sub.isnan);
                /// Unnormal x86 extended float
                uint[3] uni = [
                    0xffffffff,
                    0x7fffffff,
                    0x00000001,
                ];
                real un = *(cast(real*) &uni);
                test(un.isunnormal);
                testf(un.issubnormal);
                testf(un.isnormal);
                testf(un.iszero);
                testf(un.isinf);
                testf(un.isnan);
            }
        });
    });
    tests("Integral properties", {
        foreach(i; [0, 1, -1, 10, -10, 100, -100, 256, -256, 12345, -12345]){
            testeq(i.iszero, i == 0);
            test(i.isnormal);
            testf(i.issubnormal);
            testf(i.isunnormal);
            testf(i.isinf);
            testf(i.isnan);
        }
    });
}
