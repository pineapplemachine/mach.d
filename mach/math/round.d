module mach.math.round;

private:

import mach.traits : isNumeric, isIntegral, isFloatingPoint;
import mach.math.abs : abs;
import mach.math.floats : ffloor, fceil, fisinf, fisnan;

/++ Docs

The `round`, `floor`, and `ceil` functions can be used to round a value to
near integers.
The `round` function rounds to the nearest integer, and rounds up when the
fractional part exactly equals 0.5.
The `floor` function rounds down to the nearest integer,
and the `ceil` function rounds up to the nearest integer.

Though these functions are implemented for all numeric primitives, note that
when their inputs are integers they will always return the input itself.
Actual computation really only happens when the input is a floating point value.

+/

unittest{ /// Example
    assert(floor(100) == 100);
    assert(floor(200.5) == 200);
    assert(floor(-200.5) == -201);
}

unittest{ /// Example
    assert(ceil(100) == 100);
    assert(ceil(200.5) == 201);
    assert(ceil(-200.5) == -200);
}

unittest{ /// Example
    assert(round(100) == 100);
    assert(round(200.25) == 200);
    assert(round(200.75) == 201);
    assert(round(-200.25) == -200);
    assert(round(-200.75) == -201);
}

public:



/// Round to the nearest whole number.
/// TODO: Write a more efficient implementation and put it in mach.math.floats
T round(T)(in T value) if(isNumeric!T){
    static if(isIntegral!T){
        return value;
    }else{
        if(value.fisnan || value.fisinf){
            return value;
        }else{
            auto remainder = value % 1;
            auto uremainder = value > 0 ? remainder : 1 + remainder;
            if(uremainder >= 0.5){
                return value.fceil;
            }else{
                return value.ffloor;
            }
        }
    }
}

/// Get the ceiling of one number divided by another.
/// TODO: There's probably a better place for this functionality than here.
R divceil(R = int, N)(in N x, in N y) if(isNumeric!N && isNumeric!R){
    static if(isIntegral!N){
        auto floor = x / y;
        return cast(R) (floor + (x % y > 0));
    }else{
        auto result = x / y;
        if(result % 1 == 0){
            return cast(R) result;
        }else if(result >= 0){
            return cast(R) (result + (1 - (result % 1)));
        }else{
            return cast(R) (result - result % 1);
        }
    }
}



/// Get a value, rounded down to the nearest integer.
T floor(T)(in T value) if(isIntegral!T){
    return value;
}
/// ditto
T floor(T)(in T value) if(isFloatingPoint!T){
    return ffloor(value);
}

/// Get a value, rounded up to the nearest integer.
T ceil(T)(in T value) if(isIntegral!T){
    return value;
}
/// Get a value, rounded up to the nearest integer.
T ceil(T)(in T value) if(isFloatingPoint!T){
    return fceil(value);
}



private version(unittest){
    import mach.meta : Aliases;
}

unittest{
    // Round integers
    assert(round(0) == 0);
    assert(round(1) == 1);
    assert(round(-1) == -1);
    // Round floats
    assert(round(0.0) == 0);
    assert(round(0.25) == 0);
    assert(round(0.5) == 1);
    assert(round(0.75) == 1);
    assert(round(1.0) == 1);
    assert(round(1.25) == 1);
    assert(round(1.5) == 2);
    assert(round(-0.25) == 0);
    assert(round(-0.5) == 0);
    assert(round(-0.75) == -1);
}

unittest{
    // Integers
    assert(divceil(10, 2) == 5);
    assert(divceil(10, 3) == 4);
    assert(divceil(-10, 3) == -3);
    assert(divceil!real(10, 2) == 5.0);
    assert(divceil!real(10, 3) == 4.0);
    assert(divceil!real(-10, 3) == -3.0);
    // Floats
    assert(divceil(10.0, 2.0) == 5);
    assert(divceil(10.0, 3.0) == 4);
    assert(divceil(-10.0, 3.0) == -3);
    assert(divceil!real(10.0, 2.0) == 5.0);
    assert(divceil!real(10.0, 3.0) == 4.0);
    assert(divceil!real(-10.0, 3.0) == -3.0);
}

unittest{
    foreach(T; Aliases!(ubyte, byte, uint, int, ulong, long, float, double, real)){
        assert(T(0).floor == 0);
        assert(T(1).floor == 1);
        assert(T(100).floor == 100);
        assert(T(0).ceil == 0);
        assert(T(1).ceil == 1);
        assert(T(100).ceil == 100);
    }
    foreach(T; Aliases!(byte, int, long, float, double, real)){
        assert(T(-1).floor == -1);
        assert(T(-100).floor == -100);
        assert(T(-1).ceil == -1);
        assert(T(-100).ceil == -100);
    }
    foreach(T; Aliases!(float, double, real)){
        assert(T(0.5).floor == 0);
        assert(T(-0.5).floor == -1);
        assert(T(0.5).ceil == 1);
        assert(T(-0.5).ceil == 0);
    }
}
