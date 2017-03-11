module mach.math.floats.round;

private:

import mach.traits : IEEEFormatOf, isFloatingPoint;
import mach.math.bits : injectbits, extractbits;
import mach.math.floats.properties;
import mach.math.floats.extract;
import mach.math.floats.inject;

/++ Docs

This module implements the floor and ceil functions for floating point
primitives as `ffloor` and `fceil`.

+/

unittest{ /// Example
    assert(ffloor(1234.5) == 1234);
    assert(ffloor(-678.9) == -679);
}

unittest{ /// Example
    assert(fceil(1234.5) == 1235);
    assert(fceil(-678.9) == -678);
}

public:



/// Conventional floor floating point operation.
/// Get the greatest integer less than or equal to the input.
@trusted pure nothrow @nogc T ffloor(T)(in T value) if(isFloatingPoint!T){
    if(value.fisnan || value.fisinf || value.fiszero){
        return value;
    }else{
        if(__ctfe){
            return value >= 0 ? value - (value % 1) : value - (value % 1 + 1);
        }
        enum Format = IEEEFormatOf!T;
        immutable exp = value.fextractsexp;
        if(exp < 0){
            // Magnitude of the value is so small it has no integral part.
            return value > 0 ? T(0) : T(-1);
        }else if(exp >= Format.sigsize){
            // Magnitude of the value is too large to have a fractional part.
            return value;
        }else{
            // Explanation of what happens here:
            // The lower (significand size - biased exponent) bits are cleared,
            // thereby erasing the fractional part of the value.
            // Then, if (value < 0) and if there was any fractional part,
            // return (value - 1) since simply erasing the fractional part of a
            // negative value is really a `ceil` operation.
            immutable bits = Format.sigsize - Format.intpart - exp;
            immutable uresult = value.injectbits(Format.sigoffset, bits, ulong(0));
            if(value < 0 && value.extractbits!ulong(Format.sigoffset, bits)){
                return uresult - 1;
            }else{
                return uresult;
            }
        }
    }
}



/// Conventional ceil floating point operation.
/// Get the least integer greater than or equal to the input.
@trusted pure nothrow @nogc T fceil(T)(in T value) if(isFloatingPoint!T){
    if(value.fisnan || value.fisinf || value.fiszero){
        return value;
    }else{
        if(__ctfe){
            return value >= 0 ? value + (1 - value % 1) : value - (value % 1);
        }
        enum Format = IEEEFormatOf!T;
        immutable exp = value.fextractsexp;
        if(exp < 0){
            // Magnitude of the value is so small it has no integral part.
            return value > 0 ? T(1) : T(0);
        }else if(exp >= Format.sigsize){
            // Magnitude of the value is too large to have a fractional part.
            return value;
        }else{
            // Explanation of what happens here:
            // The lower (significand size - biased exponent) bits are cleared,
            // thereby erasing the fractional part of the value.
            // Then, if (value > 0) and if there was any fractional part,
            // return (value + 1) since simply erasing the fractional part of a
            // positive value is really a `floor` operation.
            immutable bits = Format.sigsize - Format.intpart - exp;
            immutable uresult = value.injectbits(Format.sigoffset, bits, ulong(0));
            if(value > 0 && value.extractbits!ulong(Format.sigoffset, bits)){
                return uresult + 1;
            }else{
                return uresult;
            }
        }
    }
}



private version(unittest){
    import mach.meta : Aliases;
}
unittest{
    foreach(T; Aliases!(float, double, real)){
        // Floor
        assert(ffloor(T.nan).fisnan);
        assert(ffloor(T.infinity).fisposinf);
        assert(ffloor(-T.infinity).fisneginf);
        assert(ffloor(T(0)) == 0);
        assert(ffloor(T(1)) == 1);
        assert(ffloor(T(-1)) == -1);
        assert(ffloor(T(0.5)) == 0);
        assert(ffloor(T(-0.5)) == -1);
        assert(ffloor(T(0.025)) == 0);
        assert(ffloor(T(-0.025)) == -1);
        assert(ffloor(T(0.75)) == 0);
        assert(ffloor(T(-0.75)) == -1);
        assert(ffloor(T(1.025)) == 1);
        assert(ffloor(T(-1.025)) == -2);
        assert(ffloor(T(10023)) == 10023);
        assert(ffloor(T(-10023)) == -10023);
        assert(ffloor(T(123.456)) == 123);
        assert(ffloor(T(-123.456)) == -124);
        // Ceil
        assert(fceil(T.nan).fisnan);
        assert(fceil(T.infinity).fisposinf);
        assert(fceil(-T.infinity).fisneginf);
        assert(fceil(T(0)) == 0);
        assert(fceil(T(1)) == 1);
        assert(fceil(T(-1)) == -1);
        assert(fceil(T(0.5)) == 1);
        assert(fceil(T(-0.5)) == 0);
        assert(fceil(T(0.025)) == 1);
        assert(fceil(T(-0.025)) == 0);
        assert(fceil(T(0.75)) == 1);
        assert(fceil(T(-0.75)) == 0);
        assert(fceil(T(1.025)) == 2);
        assert(fceil(T(-1.025)) == -1);
        assert(fceil(T(10023)) == 10023);
        assert(fceil(T(-10023)) == -10023);
        assert(fceil(T(123.456)) == 124);
        assert(fceil(T(-123.456)) == -123);
    }
}
