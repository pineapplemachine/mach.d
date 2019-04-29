module mach.math.floats.inject;

private:

import mach.traits : isFloatingPoint, isIntegral, isUnsignedIntegral;
import mach.traits : IEEEFormat, IEEEFormatOf;
import mach.math.abs.ints : uabs;
import mach.math.bits.inject : injectbit, injectbits;
import mach.math.floats.extract : fextractsgn;

pure public:



/// Compose a floating point number given a sign, exponent, and significand.
auto fcompose(T, Sig)(in bool sgn, in uint exp, in Sig sig) if(
    isFloatingPoint!T && isIntegral!Sig
){
    return T(0).finjectsgn!true(sgn).finjectexp!true(exp).finjectsig!true(sig);
}



/// Compose a floating point number from decimal components.
/// sign: The sign of the mantissa, true implies negative.
/// mantissa: The mantissa expressed as an unsigned integral.
/// exponent: The signed base-10 exponent of the value.
T fcomposedec(T, Mant)(
    in bool sign, in Mant mantissa, in int exponent
) if(isFloatingPoint!T && isUnsignedIntegral!Mant){
    enum Format = IEEEFormatOf!T;
    static if(Format.expsize == 8){
        alias FType = double; // Intermediate type for performing calculations.
        static immutable FType[] pow10 = [ // Powers of 10
            10.0, 100.0, 1e4, 1e8, 1e16, 1e32, 1e64
        ];
        static immutable FType[] ipow10 = [ // Reciprocal powers of 10
            0.1, 0.01, 1e-4, 1e-8, 1.0e-16, 1e-32, 1e-64
        ];
    }else static if(Format.expsize == 11){
        alias FType = real; // Intermediate type for performing calculations.
        static immutable FType[] pow10 = [ // Powers of 10
            10.0, 100.0, 1e4, 1e8, 1e16, 1e32, 1e64, 1e128, 1e256
        ];
        static immutable FType[] ipow10 = [ // Reciprocal powers of 10
            0.1, 0.01, 1e-4, 1e-8, 1e-16, 1e-32, 1e-64, 1e-128, 1e-256
        ];
    }else static if(Format.expsize == 15){
        alias FType = T;
        static immutable FType[] pow10 = [ // Powers of 10
            10.0L, 100.0L, 1e4L, 1e8L, 1e16L, 1e32L, 1e64L, 1e128L,
            1e256L, 1e512L, 1e1024L, 1e2048L, 1e4096L
        ];
        static immutable FType[] ipow10 = [ // Reciprocal powers of 10
            0.1L, 0.01L, 1e-4L, 1e-8L, 1e-16L, 1e-32L, 1e-64L, 1e-128L,
            1e-256L, 1e-512L, 1e-1024L, 1e-2048L, 1e-4096L
        ];
    }else{
        static assert(false, "Unsupported floating point type.");
    }
    
    auto exp = uabs(exponent);
    size_t d = 0;
    FType value = cast(FType) mantissa;
    
    immutable p10 = exponent >= 0 ? pow10 : ipow10;
    while(exp != 0 && d < p10.length){
        if(exp & 1) value *= p10[d];
        exp >>= 1;
        d += 1;
    }
    if(exp != 0){
        immutable x = exponent > 0 ? T.infinity : T(0.0);
        return sign ? -x : x;
    }else{
        return cast(T)(sign ? -value : value);
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
/// Guaranteed to behave correctly with NaN inputs at runtime.
/// Not guaranteed to behave correctly with NaN inputs in CTFE. (TODO: How to fix?)
auto finjectsgn(bool assumezero = false, T)(in T value, in bool sgn) if(
    isFloatingPoint!T
){
    if(__ctfe) {
        return fextractsgn(value) == sgn ? value : -value;
    }else {
        enum offset = IEEEFormatOf!T.sgnoffset;
        return value.injectbit!(offset, assumezero)(sgn);
    }
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
    import mach.math.floats.compare : fidentical;
    import mach.math.floats.extract : fextractexp, fextractsexp, fextractsig;
    import mach.math.floats.properties : fisposinf;
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
    assert(fidentical(fcomposedec!float(false, 128u, 0), float(128)));
    assert(fidentical(fcomposedec!float(false, 128u, 2), float(12800)));
    assert(fidentical(fcomposedec!float(false, 125u, -2), float(1.25)));
    // Double
    assert(fidentical(fcomposedec!double(false, 128u, 0), double(128)));
    assert(fidentical(fcomposedec!double(false, 128u, 2), double(12800)));
    assert(fidentical(fcomposedec!double(false, 128u, -2), double(1.28)));
    assert(fidentical(fcomposedec!double(false, 125u, -20), double(1.25e-18)));
    assert(fidentical(fcomposedec!double(false, 5u, -4), double(0.0005)));
    // Real
    assert(fidentical(fcomposedec!real(false, 128u, 0), real(128)));
    assert(fidentical(fcomposedec!real(false, 128u, 2), real(12800)));
    assert(fidentical(fcomposedec!real(false, 128u, -2), real(1.28)));
    assert(fidentical(fcomposedec!real(false, 125u, -20), real(1.25e-18)));
    // Test succeeds on Win7 but fails on OSX
    //assert(fidentical(fcomposedec!real(false, 5u, -4), real(0.0005)));
    // Large values producing +inf
    assert(fidentical(fcomposedec!float(false, 1u, 38), float(1e38))); // Highest representable power of 10
    assert(fcomposedec!float(false, 1u, 39).fisposinf); // Too high
    assert(fidentical(fcomposedec!double(false, 1u, 308), double(1e308))); // Highest
    assert(fcomposedec!double(false, 1u, 309).fisposinf); // Too high
    // Test succeeds on OSX but fails on Win7
    //assert(fidentical(fcomposedec!real(false, 1u, 4932), real(1e4932L))); // Highest
    assert(fcomposedec!real(false, 1u, 4933).fisposinf); // Too high
    // Small values producing 0
    assert(fcomposedec!float(false, 1u, -128) == float(0));
    assert(fcomposedec!double(false, 1u, -2000) == double(0));
    assert(fcomposedec!real(false, 1u, -17000) == real(0));
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
