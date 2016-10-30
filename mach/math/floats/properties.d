module mach.math.floats.properties;

private:

import mach.traits : isFloatingPoint, isIntegral, IEEEFormat, IEEEFormatOf;
import mach.math.bits.extract : extractbit, extractbits;
import mach.math.floats.extract : fextractexp, fextractsig;

public:



/// Get whether a floating point value represents an infinite value.
/// Also evaluates true for pseudo-infinity.
auto fisinf(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        return(
            value.fextractexp == Format.expmax &&
            value.extractbits!(0, 63) == 0
        );
    }else{
        return(
            value.fextractexp == Format.expmax &&
            value.fextractsig == 0
        );
    }
}

/// Get whether a floating point value represents positive infinity.
/// Also evaluates true for positive pseudo-infinity.
auto fisposinf(T)(T value) if(isFloatingPoint!T){
    return value.fisinf && value > 0;
}

/// Get whether a floating point value represents negative infinity.
/// Also evaluates true for negative pseudo-infinity.
auto fisneginf(T)(T value) if(isFloatingPoint!T){
    return value.fisinf && value < 0;
}

/// Get whether a floating point value represents NaN
/// Also evaluates true for pseudo not a number.
auto fisnan(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        return(
            value.fextractexp == Format.expmax &&
            value.extractbits!(0, 63) != 0
        );
    }else{
        return(
            value.fextractexp == Format.expmax &&
            value.fextractsig != 0
        );
    }
}

/// Get whether a floating point value represents a subnormal number.
/// Also evaluates true for pseudo-subnormals.
auto fissubnormal(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        return(
            value.fextractexp == 0 && (
                value.extractbit!63 ||
                value.extractbits!(0, 63) != 0
            )
        );
    }else{
        return(
            value.fextractexp == 0 &&
            value.fextractsig != 0
        );
    }
}

/// Get whether a floating point value represents a unnormal number.
/// Only meaningful for x86 extended precision prior to the 80387 processor.
auto fisunnormal(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format is IEEEFormat.Extended){
        immutable exp = value.fextractexp;
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
auto fisnormal(T)(T value) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    immutable exp = value.fextractexp;
    static if(Format is IEEEFormat.Extended){
        return(
            (exp == 0 && value.fextractsig == 0) ||
            (exp != 0 && exp != Format.expmax && value.extractbit!63 != 0)
        );
    }else{
        return(
            (exp == 0 && value.fextractsig == 0) ||
            (exp != 0 && exp != Format.expmax)
        );
    }
}

/// Get whether a floating point value represents zero.
auto fiszero(T)(T value) if(isFloatingPoint!T){
    return value.fextractexp == 0 && value.fextractsig == 0;
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
}
unittest{
    tests("Float properties", {
        foreach(T; Aliases!(float, double, real)){
            tests(T.stringof, {
                // Test detection of zero
                test(T(0).fiszero);
                test((-T(0)).fiszero);
                testf(T(1).fiszero);
                testf(T(-1).fiszero);
                testf(T.infinity.fiszero);
                testf((-T.infinity).fiszero);
                testf(T.nan.fiszero);
                // Test detection of normal
                test(T(0).fisnormal);
                test((-T(0)).fisnormal);
                test(T(1).fisnormal);
                test(T(-1).fisnormal);
                testf(T.infinity.fisnormal);
                testf((-T.infinity).fisnormal);
                testf(T.nan.fisnormal);
                // Test detection of infinity
                test(T.infinity.fisinf);
                test((-T.infinity).fisinf);
                testf(T(0).fisinf);
                testf(T(1).fisinf);
                testf(T(-1).fisinf);
                testf(T.nan.fisinf);
                test(T.infinity.fisposinf);
                testf((-T.infinity).fisposinf);
                testf(T(0).fisposinf);
                testf(T(1).fisposinf);
                testf(T(-1).fisposinf);
                testf(T.nan.fisposinf);
                test((-T.infinity).fisneginf);
                testf(T.infinity.fisneginf);
                testf(T(0).fisneginf);
                testf(T(1).fisneginf);
                testf(T(-1).fisneginf);
                testf(T.nan.fisneginf);
                // Test detection of NaN
                test(T.nan.fisnan);
                testf(T(0).fisnan);
                testf(T(1).fisnan);
                testf(T(-1).fisnan);
                testf(T.infinity.fisnan);
                testf((-T.infinity).fisnan);
                /// Test detection of subnormal
                testf(T(0).fissubnormal);
                testf((-T(0)).fissubnormal);
                testf(T(1).fissubnormal);
                testf(T(-1).fissubnormal);
                testf(T.infinity.fissubnormal);
                testf((-T.infinity).fissubnormal);
                testf(T.nan.fissubnormal);
                /// Test detection of unnormal
                testf(T(0).fisunnormal);
                testf((-T(0)).fisunnormal);
                testf(T(1).fisunnormal);
                testf(T(-1).fisunnormal);
                testf(T.infinity.fisunnormal);
                testf((-T.infinity).fisunnormal);
                testf(T.nan.fisunnormal);
            });
        }
        tests("Subnormal and unnormal values", {
            tests("Float", {
                // Subnormal float
                uint subfi = 0x007fffff;
                float subf = *(cast(float*) &subfi);
                test(subf.fissubnormal);
                testf(subf.fisunnormal);
                testf(subf.fisnormal);
                testf(subf.fiszero);
                testf(subf.fisinf);
                testf(subf.fisnan);
            });
            tests("Double", {
                // Subnormal double
                ulong subdi = 0x000fffffffffffff;
                double subd = *(cast(double*) &subdi);
                test(subd.fissubnormal);
                testf(subd.fisunnormal);
                testf(subd.fisnormal);
                testf(subd.fiszero);
                testf(subd.fisinf);
                testf(subd.fisnan);
            });
            // TODO: Probably fails on big endian
            static if(IEEEFormatOf!real is IEEEFormat.Extended){
                tests("Real", {
                    // Subnormal x86 extended float
                    uint[3] subi = [
                        0xffffffff,
                        0xffffffff,
                        0x00000000,
                    ];
                    real sub = *(cast(real*) &subi);
                    test(sub.fissubnormal);
                    testf(sub.fisunnormal);
                    testf(sub.fisnormal);
                    testf(sub.fiszero);
                    testf(sub.fisinf);
                    testf(sub.fisnan);
                    /// Unnormal x86 extended float
                    uint[3] uni = [
                        0xffffffff,
                        0x7fffffff,
                        0x00000001,
                    ];
                    real un = *(cast(real*) &uni);
                    test(un.fisunnormal);
                    testf(un.fissubnormal);
                    testf(un.fisnormal);
                    testf(un.fiszero);
                    testf(un.fisinf);
                    testf(un.fisnan);
                });
            }
        });
    });
}
