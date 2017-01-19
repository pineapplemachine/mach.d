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
    enum Format = IEEEFormatOf!T;
    static if(Format.expsize == 8){
        static immutable T[] pow10 = [
            10.0, 100.0, 1.0e4, 1.0e8, 1.0e16, 1.0e32, 1.0e64
        ];
    }else static if(Format.expsize == 11){
        static immutable T[] pow10 = [
            10.0, 100.0, 1.0e4, 1.0e8, 1.0e16, 1.0e32, 1.0e64, 1.0e128, 1.0e256
        ];
    }else static if(Format.expsize == 15){
        static immutable T[] pow10 = [
            10.0L, 100.0L, 1.0e4L, 1.0e8L, 1.0e16L, 1.0e32L, 1.0e64L, 1.0e128L,
            1.0e256L, 1.0e512L, 1.0e1024L, 1.0e2048L, 1.0e4096L, 1.0e8192L
        ];
    }else{
        static assert(false, "Unsupported floating point type.");
    }
    
    T fraction = cast(T) mantissa;
    int exp = exponent < 0 ? -exponent : exponent;
    // Keep exponent within sane limits. TODO: Why is the `/2` necessary??
    if(exp < Format.sexpmin / 2) exp = Format.sexpmin / 2;
    if(exp > Format.sexpmax / 2) exp = Format.sexpmax / 2;
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
/// If the exponent is too high to represent, returns infinity.
/// If the exponent is too low to represent, returns 0.
auto fcomposeexp(T)(in int exp) if(isFloatingPoint!T){
    enum Format = IEEEFormatOf!T;
    immutable int unbiasedexp = exp + cast(int) Format.expbias;
    if(unbiasedexp >= cast(int) Format.expmax){ // Infinity
        return T.infinity;
    }else if(unbiasedexp > 0){ // Normal
        static if(Format.intpart){
            enum intoffset = Format.intpartoffset;
            immutable T a = T(0).injectbit!(intoffset, true)(1);
        }else{
            immutable T a = T(0);
        }
        return a.finjectexp!true(cast(uint) unbiasedexp);
    }else{ // Subnormal or zero
        immutable offset = Format.sigsize - Format.intpart + unbiasedexp - 1;
        if(offset < Format.sigsize){
            return T(0).injectbit!true(offset, true); // Subnormal
        }else{
            return T(0); // Zero
        }
    }
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

/// Get a float same as the input, but with the given biased exponent.
auto finjectsexp(bool assumezero = false, T)(in T value, in int exp) if(
    isFloatingPoint!T
){
    enum Format = IEEEFormatOf!T;
    return finjectexp(value, cast(uint)(exp + Format.expbias));
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



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.floats.extract : fextractexp, fextractsexp, fextractsig;
}

unittest{ /// Compose raw
    struct Float{bool sgn; uint exp; ulong sig;}
    foreach(T; Aliases!(float, double, real)){
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
            assert(composed.fextractsgn == f.sgn);
            assert(composed.fextractexp == f.exp);
            assert(composed.fextractsig == f.sig);
        }
    }
}

unittest{ /// Compose decimal
    // Float
    assert(fcomposedec!float(false, 128u, 0) == 128);
    assert(fcomposedec!float(false, 128u, 2) == 12800);
    assert(fcomposedec!float(false, 125u, -2) == 1.25);
    // Double
    assert(fcomposedec!double(false, 128u, 0) == 128);
    assert(fcomposedec!double(false, 128u, 2) == 12800);
    assert(fcomposedec!double(false, 128u, -2) == 1.28);
    assert(fcomposedec!double(false, 125u, -20) == 1.25e-18);
    // Real
    assert(fcomposedec!real(false, 128u, 0) == 128);
    assert(fcomposedec!real(false, 128u, 2) == 12800);
    assert(fcomposedec!real(false, 128u, -2) == 1.28);
    assert(fcomposedec!real(false, 125u, -20) == 1.25e-18);
}

unittest{ /// Compose exp
    // Normals
    foreach(T; Aliases!(float, double, real)){
        enum Format = IEEEFormatOf!T;
        foreach(e; [
            0, 1, -1, 100, -100, 126, -127, 128, -128,
            -500, 500, 1000, -1000, 1022, -1023
        ]){
            if(e >= Format.nsexpmin && e <= Format.nsexpmax){
                assert(fcomposeexp!T(e) == T(2) ^^ e);
            }
        }
    }
    // Underflow/subnormals
    {
        // Floats
        assert(fcomposeexp!float(-126) == float(2) ^^ -126); // Smallest normal
        assert(fcomposeexp!float(-127) == float(2) ^^ -127); // Largest power of 2 subnormal
        assert(fcomposeexp!float(-130) == float(2) ^^ -130);
        assert(fcomposeexp!float(-149) == float(2) ^^ -149); // Smallest subnormal
        assert(fcomposeexp!float(-150) == 0.0); // Not representable
        // Doubles
        assert(fcomposeexp!double(-1030) == double(2) ^^ -1030);
        assert(fcomposeexp!double(-1090) == 0.0);
        // Reals
        // TODO: Why does `real(2) ^^ -16388` result in -infinity?
        import mach.math.floats.log;
        assert(fcomposeexp!real(-16388).log!2 == -16388);
        assert(fcomposeexp!real(-20000) == 0.0);
    }
    // Overflow/infinities
    {
        assert(fcomposeexp!float(127) == float(2) ^^ 127); // Largest power of 2
        assert(fcomposeexp!float(128) == float.infinity); // Too large
        assert(fcomposeexp!float(900) == float.infinity); // Ditto
    }
}

unittest{ /// Inject biased exponent
    foreach(T; Aliases!(float, double, real)){
        assert(T(1.0).finjectsexp(0).fextractsexp == 0);
        assert(T(1.0).finjectsexp(100).fextractsexp == 100);
        assert(T(1.0).finjectsexp(-100).fextractsexp == -100);
    }
}
