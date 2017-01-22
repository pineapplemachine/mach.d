module mach.math.floats.compare;

private:

import mach.traits : isFloatingPoint, IEEEFormatOf;
import mach.math.bits : pow2d, bitsidentical;

/++ Docs

The `fidentical` function can be used to check whether the internal
representation of two floating point values is exactly identical.

+/

unittest{ /// Example
    assert(fidentical(0.25, 0.25));
    assert(fidentical(double.nan, double.nan));
    assert(!fidentical(0.1, 0.2));
}

public:



/// Returns true when the inputs have exactly the same binary representation.
@safe bool fidentical(T)(in T a, in T b) if(isFloatingPoint!T){
    enum uint size = IEEEFormatOf!T.size;
    return bitsidentical!size(a, b);
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.math.floats.inject : fcompose;
    import mach.math.floats.properties : fisnan;
}
unittest{
    foreach(T; Aliases!(float, double, real)){
        // Identical
        assert(fidentical(T(0.0), T(0.0)));
        assert(fidentical(T(-0.0), T(-0.0)));
        assert(fidentical(T(0.5), T(0.5)));
        assert(fidentical(T(0.25), T(0.25)));
        assert(fidentical(T(-0.25), T(-0.25)));
        assert(fidentical(T.infinity, T.infinity));
        assert(fidentical(-T.infinity, -T.infinity));
        assert(fidentical(T.nan, T.nan));
        assert(fidentical(-T.nan, -T.nan));
        // Not identical
        assert(!fidentical(T(0.0), T(-0.0)));
        assert(!fidentical(T(1.0), T(-1.0)));
        assert(!fidentical(T(123456), T(12345)));
        assert(!fidentical(T.nan, T.infinity));
        assert(!fidentical(T.infinity, -T.infinity));
        assert(!fidentical(-T.infinity, T.infinity));
        assert(!fidentical(-T.nan, T.nan));
        assert(!fidentical(T.nan, -T.nan));
        // Differing representations of NaN
        enum Format = IEEEFormatOf!T;
        immutable x = fcompose!T(1, Format.expmax, 10002);
        immutable y = fcompose!T(1, Format.expmax, 10001);
        assert(x.fisnan);
        assert(y.fisnan);
        assert(fidentical(x, x));
        assert(fidentical(y, y));
        assert(!fidentical(x, y));
        assert(!fidentical(y, x));
    }
}
