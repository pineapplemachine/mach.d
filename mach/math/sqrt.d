module mach.math.sqrt;

private:

import core.math : coresqrt = sqrt;
import mach.traits : isFloatingPoint, isIntegral, isImaginary, isComplex;
import mach.traits : isSigned, FloatingPointType, ImaginaryType;
import mach.math.floats.properties : fiszero;
import mach.math.sign : signof;
import mach.math.abs : uabs;

/++ Docs

This module defines the `sqrt` and `isqrt` functions.

`sqrt` may be used to determine the square root of any numeric, imaginary, or
complex input.
When pasing an integer or float to `sqrt`, the return type is a float.
Negative inputs produce a NaN output. Infinity produces an infinite output.
When passing an imaginary or complex number to `sqrt`, the return type is a
complex number.

+/

unittest{ /// Example
    assert(sqrt(4) == 2);
    assert(sqrt(256) == 16);
}

/++ Docs

The `isqrt` function is an optimized equivalent to calling `floor(sqrt(abs(i)))`
for some integer input.
Its return type is the same as its input type.

+/

unittest{ /// Example
    assert(isqrt(4) == 2);
    assert(isqrt(15) == 3);
}

public:



/// Positive square root of 2.
enum real Sqrt2 = 1.414213562373095048801688724209698078569671875376948073176L;



/// Get the principal square root of an integer as a floating point number.
auto sqrt(T)(in T value) if(isIntegral!T){
    return sqrt(cast(real) value);
}

/// Get the principal square root of a floating point number.
auto sqrt(T)(in T value) if(isFloatingPoint!T){
    return coresqrt(value);
}

/// Get the principal square root of an imaginary number, which is a complex number.
auto sqrt(T)(in T value) if(isImaginary!T){
    alias F = FloatingPointType!T;
    return (F(1) / F(Sqrt2)) * (F(1) + T(1i)) * sqrt(value.im);
}

/// Get the principal square root of a complex number.
/// https://pdfs.semanticscholar.org/8895/3cfa5bc448cc007f23b48b04551cce8de444.pdf p. 2
auto sqrt(T)(in T value) if(isComplex!T){
    alias F = FloatingPointType!T;
    alias I = ImaginaryType!T;
    if(value.im.fiszero){
        if(value.re > 0){
            return cast(T)(sqrt(value.re) + I(0i));
        }else{
            return cast(T)(sqrt(-value.re) * I(1i));
        }
    }else{
        immutable x = sqrt(value.re * value.re + value.im * value.im);
        return (F(1) / F(Sqrt2)) * (
            sqrt(x + value.re) + sqrt(x - value.re) * signof(value.im) * I(1i)
        );
    }
}



/// Get floor(sqrt(abs(i))) of an integer as a value of the same integer type.
/// Credit http://stackoverflow.com/a/1101217/3478907
auto isqrt(T)(in T value) if(isIntegral!T){
    static if(isSigned!T){
        return cast(T) isqrt(uabs(value));
    }else{
        T one = T(1) << (T.sizeof * 8 - 2);
        T op = value;
        T result = 0;
        while(one > value) one >>= 2;
        while(one){
            if(op >= result + one){
                op -= result + one;
                result += one << 1;
            }
            result >>= 1;
            one >>= 2;
        }
        return result;
    }
}



private version(unittest){
    import mach.traits.primitives : NumericTypes, IntegralTypes, FloatingPointTypes;
    import mach.math.abs : abs;
    import mach.math.floats.properties;
    import mach.math.floats.compare : fidentical;
}

unittest{ /// Perfect squares
    foreach(T; NumericTypes){
        assert(sqrt(T(0)) == 0);
        assert(sqrt(T(1)) == 1);
        assert(sqrt(T(4)) == 2);
        assert(sqrt(T(64)) == 8);
        assert(sqrt(T(81)) == 9);
        assert(sqrt(T(100)) == 10);
    }
}

unittest{ /// Special float cases
    foreach(T; FloatingPointTypes){
        assert(sqrt(T(-0.0)) == 0);
        assert(sqrt(T.infinity).fisposinf);
        assert(sqrt(-T.infinity).fisnan);
        assert(sqrt(T.nan).fisnan);
        assert(sqrt(T(-1)).fisnan);
        assert(sqrt(T(-1000)).fisnan);
    }
}

unittest{ /// Negative integers
    assert(sqrt(int(-1)).fisnan);
    assert(sqrt(short.min).fisnan);
}

unittest{ /// Imaginary numbers
    assert(sqrt(0i) == 0);
    assert(fidentical(sqrt(8i).re, 2.0));
    assert(fidentical(sqrt(8i).im, 2.0));
    assert(fidentical(sqrt(128i).re, 8.0));
    assert(fidentical(sqrt(128i).im, 8.0));
    immutable result = sqrt(ireal(14i));
    immutable expected = 2.6457513110645905905016L;
    immutable epsilon = 1e-18;
    assert(result.re == result.im);
    assert(abs(expected - result.re) < epsilon);
}

unittest{ /// Complex numbers
    assert(sqrt(0 + 0i) == 0);
    assert(sqrt(64 + 0i) == 8);
    assert(sqrt(-64 + 0i) == 8i);
    immutable aresult = sqrt(creal(+64 + 64i));
    immutable bresult = sqrt(creal(-64 + 64i));
    immutable expectedre = 8.7894729077424797283184L;
    immutable expectedim = 3.6407188844978187304348L;
    immutable epsilon = 1e-18;
    assert(abs(expectedre - aresult.re) < epsilon);
    assert(abs(expectedim - aresult.im) < epsilon);
    assert(abs(expectedre - bresult.im) < epsilon);
    assert(abs(expectedim - bresult.re) < epsilon);
}

unittest{ /// Integer sqrt
    foreach(T; IntegralTypes){
        // Perfect squares
        assert(isqrt(T(0)) == 0);
        assert(isqrt(T(1)) == 1);
        assert(isqrt(T(4)) == 2);
        assert(isqrt(T(16)) == 4);
        assert(isqrt(T(100)) == 10);
        // Imperfect, rounded down
        assert(isqrt(T(2)) == 1);
        assert(isqrt(T(3)) == 1);
        assert(isqrt(T(5)) == 2);
        assert(isqrt(T(15)) == 3);
        assert(isqrt(T(120)) == 10);
        // Negative inputs
        static if(isSigned!T){
            assert(isqrt(T(-4)) == 2);
            assert(isqrt(T(-16)) == 4);
            assert(isqrt(T(-99)) == 9);
        }
    }
}
