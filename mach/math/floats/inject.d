module mach.math.floats.inject;

private:

import mach.traits : isFloatingPoint, isIntegral, isUnsignedIntegral;
import mach.traits : IEEEFormat, IEEEFormatOf;
import mach.math.bits.inject : injectbit, injectbits;
import mach.math.floats.extract : fextractsgn;

public:



/// Compose a floating point number given a sign, exponent, and significand.
auto fcompose(T, Sig)(in bool sgn, in uint exp, in Sig sig) if(
    isFloatingPoint!T && isIntegral!Sig
){
    return T(0).finjectsgn!true(sgn).finjectexp!true(exp).finjectsig!true(sig);
}



/// Compose a floating point number from decimal components.
/// Not guaranteed to work for especially large or small exponents.
/// sign: The sign of the mantissa, true implies negative.
/// mantissa: The mantissa expressed as an unsigned integral.
/// exponent: The signed base-10 exponent of the value.
auto fcomposedec(T, Mant)(
    in bool sign, in Mant mantissa, in int exponent
) if(isFloatingPoint!T && isUnsignedIntegral!Mant){
    static immutable T[] pow10 = [
        10, 100, 1.0e4, 1.0e8, 1.0e16, 1.0e32, 1.0e64, 1.0e128, 1.0e256
    ];
    T fraction = cast(T) mantissa;
    int exp = exponent < 0 ? -exponent : exponent;
    size_t d = 0;
    T fexp = 1.0;
    while(exp != 0){
        if(exp & 1) fexp *= pow10[d];
        exp >>= 1;
        d += 1;
    }
    if(exponent >= 0){
        T result = fraction * fexp;
        return sign ? -result : result;
    }else{
        T result = fraction / fexp;
        return sign ? -result : result;
    }
}



/// Get a float equal to `1 * 2 ^ x`.
/// The inputted exponent should be signed and biased, not a raw value.
auto fcomposeexp(T)(in int exp) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    static if(Format.intpart){
        enum intoffset = Format.intpartoffset;
        immutable T a = T(0).injectbit!(intoffset, true)(1);
    }else{
        immutable T a = T(0);
    }
    return a.finjectexp!true(cast(uint)(exp + Format.expbias));
}



/// Get a float the same as the input, but with the given sign.
auto finjectsgn(bool assumezero = false, T)(in T value, in bool sgn) if(
    isFloatingPoint!T
){
    enum offset = IEEEFormatOf!T.sgnoffset;
    return value.injectbit!(offset, assumezero)(sgn);
}

/// Get a float the same as the input, but with the given exponent bits.
auto finjectexp(bool assumezero = false, T)(in T value, in uint exp) if(
    isFloatingPoint!T
){
    enum Format = IEEEFormatOf!T;
    enum offset = Format.expoffset;
    enum size = Format.expsize;
    return value.injectbits!(offset, size, assumezero)(exp);
}

/// Get a float the same as the input, but with the given significand bits.
auto finjectsig(bool assumezero = false, T, Sig)(in T value, in Sig sig) if(
    isFloatingPoint!T && isIntegral!Sig
){
    enum Format = IEEEFormatOf!T;
    enum offset = Format.sigoffset;
    enum size = Format.sigsize;
    return value.injectbits!(offset, size, assumezero)(sig);
}



/// Get a float the same as `dst`, but with the same sign as `src`.
auto fcopysgn(Src, Dst)(in Src src, in Dst dst) if(
    isFloatingPoint!Src && isFloatingPoint!Dst
){
    return dst.finjectsgn(src.fextractsgn);
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
    import mach.math.floats.extract : fextractexp, fextractsig;
}
unittest{
    tests("Float inject", {
        tests("Compose full", {
            struct Float{bool sgn; uint exp; ulong sig;}
            foreach(T; Aliases!(float, double, real)){
                tests(T.stringof, {
                    foreach(f; [
                        Float(0, 0, 0),
                        Float(1, 0, 0),
                        Float(0, 1, 0),
                        Float(1, 1, 0),
                        Float(0, 0, 1),
                        Float(1, 0, 1),
                        Float(0, 120, 32000),
                        Float(1, 120, 32000),
                        Float(0, 127, 0),
                        Float(1, 127, 0),
                        Float(0, 127, 8388607),
                        Float(1, 127, 8388607),
                    ]){
                        auto composed = fcompose!T(f.sgn, f.exp, f.sig);
                        testeq(composed.fextractsgn, f.sgn);
                        testeq(composed.fextractexp, f.exp);
                        testeq(composed.fextractsig, f.sig);
                    }
                });
            }
        });
        tests("Compose decimal", {
            testeq(fcomposedec!double(false, 128u, 0), 128);
            testeq(fcomposedec!double(false, 128u, 2), 12800);
            testeq(fcomposedec!double(false, 128u, -2), 1.28);
            testeq(fcomposedec!double(false, 128u, -20), 1.28e-18);
        });
        tests("Compose exp", {
            foreach(T; Aliases!(float, double, real)){
                enum Format = IEEEFormatOf!T;
                tests(T.stringof, {
                    foreach(e; [
                        0, 1, -1, 100, -100, 126, -127, 128, -128,
                        -500, 500, 1000, -1000, 1022, -1023
                    ]){
                        if(e >= Format.sexpmin && e <= Format.sexpmax){
                            testeq(fcomposeexp!T(e), T(2) ^^ e);
                        }
                    }
                });
            }
        });
    });
}
