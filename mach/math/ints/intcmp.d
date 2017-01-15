module mach.math.ints.intcmp;

private:

import mach.traits : isIntegral, isSignedIntegral, isUnsignedIntegral;

/++ Docs

This module provides functions for comparing integer primitives where one
type may be signed and another unsigned.
(When this is the case, comparison may fail because of unsigned coercion.)

The function `intgt` returns true when `a > b`, `intgte` when `a >= b`,
`intlt` when `a < b`, `intlte` when `a <= b`, and `inteq` when `a == b`.

+/

unittest{ /// Example
    // This happens because the `int` is coerced to a `uint` before comparing.
    assert(int(-1) > uint(0));
}

unittest{ /// Example
    // These functions do not suffer from the same limitation.
    assert(intgt(uint(0), int(-1)));
    assert(intgte(uint(0), int(-1)));
    assert(intlt(int(-1), uint(0)));
    assert(intlte(int(-1), uint(0)));
}

public:



/// True when the first input is greater than the second.
/// Intended for when signed and unsigned integral types may be mixed.
bool intgt(A, B)(in A a, in B b) if(isIntegral!A && isIntegral!B){
    static if(isSignedIntegral!A && isUnsignedIntegral!B){
        if(a < 0) return false;
    }else static if(isUnsignedIntegral!A && isSignedIntegral!B){
        if(b < 0) return true;
    }
    return a > b;
}

/// True when the first input is greater than or equal to the second.
/// Intended for when signed and unsigned integral types may be mixed.
bool intgte(A, B)(in A a, in B b) if(isIntegral!A && isIntegral!B){
    static if(isSignedIntegral!A && isUnsignedIntegral!B){
        if(a < 0) return false;
    }else static if(isUnsignedIntegral!A && isSignedIntegral!B){
        if(b < 0) return true;
    }
    return a >= b;
}

/// True when the first input is less than the second.
/// Intended for when signed and unsigned integral types may be mixed.
bool intlt(A, B)(in A a, in B b) if(isIntegral!A && isIntegral!B){
    static if(isSignedIntegral!A && isUnsignedIntegral!B){
        if(a < 0) return true;
    }else static if(isUnsignedIntegral!A && isSignedIntegral!B){
        if(b < 0) return false;
    }
    return a < b;
}

/// True when the first input is less than or equal to the second.
/// Intended for when signed and unsigned integral types may be mixed.
bool intlte(A, B)(in A a, in B b) if(isIntegral!A && isIntegral!B){
    static if(isSignedIntegral!A && isUnsignedIntegral!B){
        if(a < 0) return true;
    }else static if(isUnsignedIntegral!A && isSignedIntegral!B){
        if(b < 0) return false;
    }
    return a <= b;
}

/// True when the first input is equal to the second.
/// Intended for when signed and unsigned integral types may be mixed.
bool inteq(A, B)(in A a, in B b) if(isIntegral!A && isIntegral!B){
    static if(isSignedIntegral!A && isUnsignedIntegral!B){
        if(a < 0) return false;
    }else static if(isUnsignedIntegral!A && isSignedIntegral!B){
        if(b < 0) return false;
    }
    return a == b;
}



unittest{
    assert(intgt(uint(0), int(-1)));
    assert(intgt(int(-1), int(-2)));
    assert(intgt(uint(1), uint(0)));
    assert(!intgt(int(-1), uint(0)));
    assert(!intgt(int(-2), int(-1)));
    assert(!intgt(uint(0), uint(1)));
    assert(!intgt(int(0), uint(0)));
}
unittest{
    assert(intgte(uint(0), int(-1)));
    assert(intgte(int(-1), int(-2)));
    assert(intgte(uint(1), uint(0)));
    assert(!intgte(int(-1), uint(0)));
    assert(!intgte(int(-2), int(-1)));
    assert(!intgte(uint(0), uint(1)));
    assert(intgte(int(0), uint(0)));
}

unittest{
    assert(!intlt(uint(0), int(-1)));
    assert(!intlt(int(-1), int(-2)));
    assert(!intlt(uint(1), uint(0)));
    assert(intlt(int(-1), uint(0)));
    assert(intlt(int(-2), int(-1)));
    assert(intlt(uint(0), uint(1)));
    assert(!intlt(int(0), uint(0)));
}
unittest{
    assert(!intlte(uint(0), int(-1)));
    assert(!intlte(int(-1), int(-2)));
    assert(!intlte(uint(1), uint(0)));
    assert(intlte(int(-1), uint(0)));
    assert(intlte(int(-2), int(-1)));
    assert(intlte(uint(0), uint(1)));
    assert(intlte(int(0), uint(0)));
}

unittest{
    assert(inteq(uint(0), int(0)));
    assert(inteq(uint(1), int(1)));
    assert(!inteq(uint(-1), int(1)));
}
