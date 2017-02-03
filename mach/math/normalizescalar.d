module mach.math.normalizescalar;

private:

import mach.traits : isSigned, isIntegral, isFloatingPoint, isNumeric;

/++ Docs

The `normalizescalar` function can be used to convert an integer to a float
in the range [-1, 1] (when signed) or [0, 1] (when unsigned).
The `denormalizescalar` goes in the opposite direction and converts a float
in the range [-1, 1] (for signed types) or [0, 1] (for unsigned) to an integral.
For signed integers, -1.0 corresponds to `T.min`, 0.0 to `T(0)`, and +1.0 to `T.max`.
For unsigned integers, 0.0 corresponds to `T(0)` and +1.0 to `T.max`.

+/

unittest{ /// Example
    assert(normalizescalar(int.max) == 1.0);
    assert(normalizescalar(int.min) == -1.0);
    assert(denormalizescalar!int(1.0) == int.max);
    assert(denormalizescalar!int(-1.0) == int.min);
}

public:



/// Given a signed integral value, convert it to a floating point number
/// normalized to be between -1.0 and 1.0, inclusive.
/// If the input is unsigned, then the floating point will instead be
/// between 0.0 and 1.0, inclusive.
F normalizescalar(F = double, T)(in T value) pure @safe @nogc nothrow if(
    isIntegral!T && isFloatingPoint!F
){
    static if(isSigned!F){
        if(value >= 0) return cast(F) value / cast(F) T.max;
        else return cast(F) value / -cast(F) T.min;
    }else{
        return cast(F) value / cast(F) T.max;
    }
}

/// Given a floating point number between -1.0 and 1.0, inclusive, convert
/// to a signed integral within its maximum bounds.
/// If the output is unsigned, then the floating point must instead be
/// between 0.0 and 1.0, inclusive.
T denormalizescalar(T, F)(in F value) pure @safe @nogc nothrow if(
    isIntegral!T && isFloatingPoint!F
){
    static if(isSigned!T){
        assert(value >= -1.0 && value <= 1.0);
        if(value >= 0) return cast(T)(value * T.max);
        else return cast(T)(value * -(cast(F) T.min));
    }else{
        assert(value >= 0.0 && value <= 1.0);
        return cast(T)(value * T.max);
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.math.abs : abs;
}
unittest{
    tests("Normalize", {
        // Ought to be exactly equal
        testeq(int(0).normalizescalar, 0.0);
        testeq(int.min.normalizescalar, -1.0);
        testeq(int.max.normalizescalar, 1.0);
        testeq(uint(0).normalizescalar, 0.0);
        testeq(uint.min.normalizescalar, 0.0);
        testeq(uint.max.normalizescalar, 1.0);
        testeq(byte(0).normalizescalar, 0.0);
        testeq(byte.min.normalizescalar, -1.0);
        testeq(byte.max.normalizescalar, 1.0);
        // Ought to be very close to equal
        enum real intepsilon = 1e-9;
        testlte(abs(int(1 << 30).normalizescalar - 0.5), intepsilon);
        testlte(abs(int(1 << 29).normalizescalar - 0.25), intepsilon);
        enum real byteepsilon = 1e-2;
        testlte(abs(byte(1 << 6).normalizescalar - 0.5), byteepsilon);
        testlte(abs(byte(1 << 5).normalizescalar - 0.25), byteepsilon);
        // Make sure denormalization yields the same as normalization input
        static if(real.sizeof > double.sizeof){ // Increased precision required for test
            void detest(T)(T[] values...){
                foreach(value; values){
                    // Note: Must normalize to reals for output to be sufficiently
                    // accurate to pass this test.
                    testeq(value.normalizescalar!real.denormalizescalar!T, value);
                }
            }
            detest!uint(uint.min, uint.max, 0, 1, 2, 3, 4);
            detest!int(int.min, int.max, -2, -1, 0, 1, 2);
            detest!byte(byte.min, byte.max, byte(-2), byte(-1), byte(0), byte(1), byte(2));
        }
    });
}
