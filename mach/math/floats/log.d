module mach.math.floats.log;

private:

import mach.traits.ieee : IEEEFormatOf;
import mach.traits.primitives : isFloatingPoint;
import mach.math.bits : injectbit, extractbit, pow2;
import mach.math.ints.intproduct : intproduct;
import mach.math.constants : e;
import mach.math.floats.properties : fisnan, fisinf, fisposinf, fiszero;
import mach.math.floats.extract;
import mach.math.floats.inject;

version(DigitalMars){
    import core.math : yl2x;
    enum InlineLog = true;
}else{
    enum InlineLog = false;
}

/++ Docs

This module implements the `log` function for floating point types.
The function accepts a base for the logarithm operation as a positive
nonzero template argument.

+/

unittest{ /// Example
    assert(log!2(2.0) == 1);
    assert(log!2(0.125) == -3);
}

unittest{ /// Example
    import mach.math.abs : abs;
    assert(abs(log!10(1000.0) - 3) < 1.0e-16);
}

/++ Docs

The `ln` function is a shortcut for `log!e`.

+/

unittest{ /// Example
    import mach.math.constants : e;
    assert(abs(ln(e) - 1) < 1.0e-16);
}

/++ Docs

Additionally, the `flog2` and `clog2` functions can be used to quickly
determine `floor(log!2(n))` and `ceil(log!2(n))`, respectively.
These functions assume a nonzero noninfinite non-nan input.
Negative inputs are treated as though they were positive.

+/

unittest{ /// Example
    assert(clog2(255.0) == 8);
    assert(flog2(255.0) == 7);
}

public:



/// Log base 2 of e.
enum real Log2_e = 1.442695040888963407359924681001892137426645954152985934135L;

/// Log base 2 of 10.
enum real Log2_10 = 3.321928094887362347870319429489390175864831393024580612054L;

/// Log base 10 of 2.
enum real Log10_2 = 0.301029995663981195213738894724493026768189881462108541310L;

/// Natural log of 2.
enum real Ln_2 = 0.693147180559945309417232121458176568075500134360255254120L;



/// Returns `floor(log2(abs(value)))` as a signed integer.
/// Behavior undefined for zero, nan, and infinite inputs.
@trusted pure nothrow @nogc int flog2(T)(in T value) if(isFloatingPoint!T){
    assert(!value.fiszero && !value.fisnan && !value.fisinf);
    return value.fextractsexp;
}

/// Returns `ceil(log2(abs(value)))` as a signed integer.
/// Behavior undefined for zero, nan, and infinite inputs.
@trusted pure nothrow @nogc int clog2(T)(in T value) if(isFloatingPoint!T){
    assert(!value.fiszero && !value.fisnan && !value.fisinf);
    return value.fextractsexp + (value.fextractsig != 0);
}



/// Convenience alias. Same as `log!e`.
@safe pure nothrow @nogc auto ln(T)(in T value) if(isFloatingPoint!T) {
    return log!e(value);
}



/// Returns the logarithm of the absolute value of an input.
/// Leverages x87 opcodes if available, otherwise falls back to an
/// implementation based loosely on Clay. S. Turner's algorithm.
@safe pure nothrow @nogc auto log(real base, T)(in T value) if(
    isFloatingPoint!T && base > 0
){
    static if(base == 1){
        return T.nan; // Log base 1 of anything is undefined.
    }else static if(InlineLog){
        return log87impl!base(value);
    }else{
        return lognativeimpl!base(value);
    }
}

/// Implementation of log function using `yl2x`.
static if(InlineLog) private @safe pure nothrow @nogc auto log87impl(real base, T)(
    in T value
) if(isFloatingPoint!T && base > 0){
    static if(base == 2){
        return yl2x(value, 1);
    }else static if(base == e){
        return yl2x(value, Ln_2);
    }else static if(base == 10){
        return yl2x(value, Log10_2);
    }else{
        static if(base < 1){
            // Without these checks, signs get reversed because
            // the second argument to `yl2x` is negative.
            if(value == 0) return -T.infinity;
            else if(value.fisposinf) return T.infinity;
        }
        return yl2x(value, 1 / yl2x(base, 1));
    }
}

/// Implementation of log function using native D code
/// based loosely on Clay. S. Turner's algorithm.
/// Takes substantially longer to evaluate than `log87impl`,
/// and is very slightly less accurate, but it gets the job done.
private @trusted pure nothrow @nogc T lognativeimpl(real base, T)(in T value) if(
    isFloatingPoint!T && base > 0
){
    if(value.fisnan){
        return value;
    }else if(value < 0){
        return T.nan;
    }else if(value.fisinf){
        return T.infinity;
    }else if(value.fiszero){
        return -T.infinity;
    }else static if(base == 2){
        enum Format = IEEEFormatOf!T;
        // Get unbiased exponent.
        immutable unbiasedexp = value.fextractexp;
        // Get normalized significand.
        enum sigbits = Format.sigsize + (!Format.intpart);
        ulong sig = cast(ulong) value.fextractnsig << (64 - sigbits);
        
        // Log is at least (low) and less than (low + 1).
        int low = void;
        if(unbiasedexp > 0){ // Normal
            low = unbiasedexp - Format.expbias;
        }else{ // Subnormal (non-zero, by virtue of conditional a few checks up)
            low = Format.nsexpmin;
            while(!(sig & pow2!63)){
                sig <<= 1;
                low--;
            }
        }
        
        /// Get log of value >= 2^0 and < 2^1.
        ulong flog = 0;
        static if(Format.intpart) flog |= pow2!(Format.sigsize - 1);
        immutable imax = Format.sigsize - Format.intpart;
        for(int i = imax - 1; i >= 0; i--){
            immutable sq = intproduct(sig, sig); // Square the significand
            if(sq.high & pow2!63){ // If new significand >= 2:
                // Capture new bits of significand (divided by 2).
                sig = sq.high;
                // Add 1/2, 1/4, 1/8, ... to the log.
                flog |= pow2!ulong(i);
            }else{
                // Capture new bits of significand.
                sig = (sq.high << 1) | (sq.low >> 63);
            }
        }
        
        // All done
        return (low - 1) + fcompose!T(false, Format.expbias, flog);
    }else static if(base == e){
        return lognativeimpl!2(value) / Log2_e;
    }else static if(base == 10){
        return lognativeimpl!2(value) / Log2_10;
    }else{
        return lognativeimpl!2(value) / lognativeimpl!2(base);
    }
}



private version(unittest){
    import mach.meta.aliases : Aliases;
    import mach.math.abs : abs;
    import mach.math.constants : pi;    
}

unittest{ /// Log base 2 accuracy
    foreach(T; Aliases!(float, double, real)){
        enum Format = IEEEFormatOf!T;
        // Error is measured as the scaled difference between `n` and `2 ^ log2(n)`.
        immutable maxerror = T(1).finjectsexp(
            -(Format.sigsize - Format.intpart - 2 - is(T == real))
        );
        immutable T[] values = [
            0.01, 0.025, 0.1, 0.125, 0.2, 0.25, 1.0, 1.1, 1.2, 1.3333333,
            3, 4, 5, 6, 6.5, 7, 8, 10, 11, 16, 20, 25, 81, 128, 255, 256,
            100, 1000, 9000.1, 123.456, 111.222, 1.234567, e, pi
        ];
        void TestValue(alias logfunc)(in T value){
            immutable l = cast(T) logfunc!2(value);
            immutable v = 2 ^^ l;
            immutable delta = abs(v - value);
            immutable error = delta == 0 ? 0 : delta / value;
            assert(error <= maxerror);
        }
        foreach(value; values){
            static if(InlineLog) TestValue!log87impl(value);
            TestValue!lognativeimpl(value);
            TestValue!log(value);
        }
    }
}

unittest{ /// Log base 1
    foreach(T; Aliases!(float, double, real)){
        assert(log!1(T(-1.0)).fisnan);
        assert(log!1(T(0.0)).fisnan);
        assert(log!1(T(1.0)).fisnan);
        assert(log!1(T(-0.5)).fisnan);
        assert(log!1(T(0.5)).fisnan);
    }
}

unittest{ /// Accuracy for other bases
    void assertnear(in double a, in double b){
        assert(abs(a - b) < 0.1e-13);
    }
    foreach(n; 0 .. 10){
        assertnear((3.0 ^^ n).log!3, n);
        assertnear((8.0 ^^ n).log!8, n);
        assertnear((10.0 ^^ n).log!10, n);
        assertnear((12.0 ^^ n).log!12, n);
        assertnear((15.0 ^^ n).log!15, n);
        assertnear((21.0 ^^ n).log!21, n);
        assertnear((100.0 ^^ n).log!100, n);
    }
}

unittest{ /// Special cases for bases other than 1
    foreach(T; Aliases!(float, double, real)){
        foreach(base; Aliases!(0.25, 0.5, 1.25, 1.5, 2, e, 5, 10, 200)){
            assert(lognativeimpl!base(T(-1.0)).fisnan);
            assert(lognativeimpl!base(-T.infinity).fisnan);
            assert(lognativeimpl!base(T(0.0)) == -T.infinity);
            assert(lognativeimpl!base(T.infinity) == T.infinity);
            static if(InlineLog){
                assert(log87impl!base(T(-1.0)).fisnan);
                assert(log87impl!base(-T.infinity).fisnan);
                assert(log87impl!base(T(0.0)) == -T.infinity);
                assert(log87impl!base(T.infinity) == T.infinity);
            }
        }
    }
}

unittest{ /// Subnormals
    // Floats
    void testfloat(int exp){
        assert(lognativeimpl!2(float(2) ^^ exp) == exp);
        static if(InlineLog) assert(log87impl!2(float(2) ^^ exp) == exp);
    }
    testfloat(-126); // Smallest normal
    testfloat(-127); // Largest power of 2 subnormal
    testfloat(-130);
    testfloat(-149); // Smallest subnormal
    //// Doubles
    assert(lognativeimpl!2(double(2) ^^ -1030) == -1030);
    static if(InlineLog) assert(log87impl!2(double(2) ^^ -1030) == -1030);
    // Reals
    // TODO: Why does `real(2) ^^ -16388` result in -infinity?
    import mach.math.floats.inject : fcomposeexp;
    assert(lognativeimpl!2(fcomposeexp!real(-16388)) == -16388);
    static if(InlineLog) assert(log87impl!2(fcomposeexp!real(-16388)) == -16388);
}
