module mach.math.normalize;

private:

import std.traits : isSigned, isIntegral, isFloatingPoint, isNumeric;

public:



/// Given a signed integral value, convert it to a floating point number
/// normalized to be between -1.0 and 1.0, inclusive.
/// If the input is unsigned, then the floating point will instead be
/// between 0.0 and 1.0, inclusive.
static FP normalize(FP = real, SI)(SI value) pure @safe @nogc nothrow if(
    /* isSigned!SI && */ isIntegral!SI && isFloatingPoint!FP
){
    if(value >= 0) return (cast(FP) value) / (cast(FP) SI.max);
    else return (cast(FP) value) / -(cast(FP) SI.min);
}

/// Given a floating point number between -1.0 and 1.0, inclusive, convert
/// to a signed integral within its maximum bounds.
/// If the output is unsigned, then the floating point must instead be
/// between 0.0 and 1.0, inclusive.
static SI denormalize(SI, FP)(FP value) pure @safe @nogc nothrow if(
    /* isSigned!SI && */ isIntegral!SI && isNumeric!FP
)in{
    assert(value >= -1.0 && value <= 1.0);
}body{
    if(value >= 0) return cast(SI)(value * (cast(FP) SI.max));
    else return cast(SI)(value * -(cast(FP) SI.min));
}



version(unittest){
    private:
    import mach.error.unit;
    import std.stdio;
}
unittest{
    tests("Normalize", {
        // Ought to be exactly equal
        testeq(int(0).normalize, 0.0);
        testeq(int.min.normalize, -1.0);
        testeq(int.max.normalize, 1.0);
        testeq(uint(0).normalize, 0.0);
        testeq(uint.min.normalize, 0.0);
        testeq(uint.max.normalize, 1.0);
        testeq(byte(0).normalize, 0.0);
        testeq(byte.min.normalize, -1.0);
        testeq(byte.max.normalize, 1.0);
        // Ought to be very close to equal
        enum real intepsilon = 1e-9;
        testnear(int(1 << 30).normalize, 0.5, intepsilon);
        testnear(int(1 << 29).normalize, 0.25, intepsilon);
        enum real byteepsilon = 1e-2;
        testnear(byte(1 << 6).normalize, 0.5, byteepsilon);
        testnear(byte(1 << 5).normalize, 0.25, byteepsilon);
        // Make sure denormalization yields the same as normalization input
        void detest(T)(T[] values...){
            foreach(value; values){
                testeq(value.normalize.denormalize!T, value);
            }
        }
        detest!uint(uint.min, uint.max, 0, 1, 2, 3, 4);
        detest!int(int.min, int.max, -2, -1, 0, 1, 2);
        detest!byte(byte.min, byte.max, byte(-2), byte(-1), byte(0), byte(1), byte(2));
    });
}
