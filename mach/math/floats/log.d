module mach.math.floats.log;

private:

import mach.traits : IEEEFormatOf, isFloatingPoint;
import mach.math.bits : injectbit, extractbit, pow2;
import mach.math.ints.intproduct : intproduct;
import mach.math.constants : e;
import mach.math.floats.properties : fisnan, fisinf, fiszero;
import mach.math.floats.extract;
import mach.math.floats.inject;

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

`log` reports the logarithm of negative numbers as though the input was
positive; i.e. it returns the logarithm of the absolute value of the input.

+/

unittest{ /// Example
    assert(log!2(-4.0) == 2);
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
enum real LogE = 1.442695040888963407359924681001892137426645954152985934135L;

/// Log base 2 of 10.
enum real Log10 = 3.321928094887362347870319429489390175864831393024580612054L;




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

/// Returns the logarithm of the absolute value of an input.
/// Based loosely on Clay. S. Turner's algorithm.
/// http://www.claysturner.com/dsp/BinaryLogarithm.pdf
@trusted pure nothrow @nogc T log(double base, T)(in T value) if(
    isFloatingPoint!T && base > 0
){
    static if(base == 1){
        // Special case: log1 of anything is infinity,
        // except for log1(1) which is undefined.
        if(abs(value) == 1) return T.nan;
        else return T.infinity;
    }else{
        if(value.fisnan){
            return value;
        }else if(value.fisinf){
            return T.infinity;
        }else if(value.fiszero){
            return -T.infinity;
        }else{
            static if(base == 2){
                enum Format = IEEEFormatOf!T;
                T low = value.fextractsexp; // Log is at least (low) and less than (low + 1).
                enum sigbits = Format.sigsize + (!Format.intpart);
                ulong sig = cast(ulong) value.fextractnsig << (64 - sigbits);
                ulong flog = 0;
                static if(Format.intpart) flog |= pow2!(Format.sigsize - 1);
                immutable imax = Format.sigsize - Format.intpart;
                for(int i = imax - 1; i >= 0; i--){
                    immutable sq = intproduct(sig, sig); // Square the significand
                    if(sq.high & pow2!63){ // If new significand >= 2:
                        // Capture new bits of significand (divided by 2)
                        sig = sq.high;
                        // Add 1/2, 1/4, 1/8, ... to the log
                        flog |= pow2!ulong(i);
                    }else{
                        // Capture new bits of significand
                        sig = (sq.high << 1) | (sq.low >> 63);
                    }
                }
                return low + fcompose!T(false, Format.expbias, flog) - 1;
            }else static if(base == e){
                return log!2(value) / LogE;
            }else static if(base == 10){
                return log!2(value) / Log10;
            }else{
                return log!2(value) / log!2(base);
            }
        }
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.abs : abs;
    import mach.math.constants : pi;
}
unittest{
    foreach(T; Aliases!(float, double, real)){
        enum Format = IEEEFormatOf!T;
        // Essentially limits error to the two least significant bits of the
        // significand. Except for with reals, in which case limit to the
        // three least significant bits.
        // Error is measured as the scaled difference between `n` and `2 ^ log2(n)`.
        // Phobos' `log2` passes with this margin of error, just barely.
        immutable maxerror = T(1).finjectsexp(
            -(Format.sigsize - Format.intpart - 1 - is(T == real))
        );
        immutable T[] values = [
            0.01, 0.025, 0.1, 0.125, 0.2, 0.25, 1.0, 1.1, 1.2, 1.3333333,
            3, 4, 5, 6, 6.5, 7, 8, 10, 11, 16, 20, 25, 81, 128, 255, 256,
            100, 1000, 9000.1, 123.456, 111.222, 1.234567, e, pi
        ];
        foreach(value; values){
            immutable l = cast(T) log!2(value);
            immutable v = 2 ^^ l;
            immutable delta = abs(v - value);
            immutable error = delta == 0 ? 0 : delta / value;
            assert(error <= maxerror);
        }
    }
}
unittest{
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
