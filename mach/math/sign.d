module mach.math.sign;

private:

import mach.traits : isNumeric, isSignedIntegral, isUnsignedIntegral;
import mach.math.floats : fiszero, fextractsgn;

/++ Docs

The `signof` function can be used to acquire the sign of a numeric input as
a member of the `Sign` enum, whose members are `Sign.Positive`, `Sign.Negative`,
and `Sign.Zero`.

+/

unittest{ /// Example
    assert(signof(1) is Sign.Positive);
    assert(signof(-1) is Sign.Negative);
    assert(signof(0) is Sign.Zero);
}

public:



/// Enumeration of possible signs of real numbers.
enum Sign: int{
    Positive = 1,
    Negative = -1,
    Zero = 0
}



/// Get the sign of a numeric value as type Sign.
/// For floats, positive and negative zero both result in Sign.Zero.
/// Otherwise, its sign bit decides the output.
Sign signof(T)(in T value) if(isNumeric!T){
    static if(isUnsignedIntegral!T){
        return value == 0 ? Sign.Zero : Sign.Positive;
    }else static if(isSignedIntegral!T){
        if(value == 0) return Sign.Zero;
        else if(value > 0) return Sign.Positive;
        else return Sign.Negative;
    }else{
        if(value.fiszero) return Sign.Zero;
        else if(value.fextractsgn) return Sign.Negative;
        else return Sign.Positive;
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.traits : isSigned;
}

unittest{
    foreach(T; Aliases!(byte, ubyte, int, uint, long, ulong, float, double, real)){
        assert(T(0).signof is Sign.Zero);
        assert(-T(0).signof is Sign.Zero);
        assert(T(1).signof is Sign.Positive);
        static if(isSigned!T) assert(T(-1).signof is Sign.Negative);
    }
}
unittest{
    assert((float.infinity).signof is Sign.Positive);
    assert((-float.infinity).signof is Sign.Negative);
    assert((float.nan).signof is Sign.Positive);
    assert((-float.nan).signof is Sign.Negative);
}
unittest{
    assert(Sign.Positive == 1);
    assert(Sign.Negative == -1);
    assert(Sign.Zero == 0);
}
