module mach.math.floats.compare;

private:

import mach.traits : isFloatingPoint, IEEEFormatOf;
import mach.math.bits : pow2d;

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



/// Returns true when a and b are exactly the same value.
@trusted bool fidentical(T)(in T a, in T b) if(isFloatingPoint!T){
    // TODO: This is pretty generic stuff actually
    // Sometime the logic should live in a mach.math.bits function and this
    // would just pass the values and the number of bits to check equality for.
    enum Format = IEEEFormatOf!T;
    static if(Format.size == 32){ // Float
        const aint = cast(uint*) &a;
        const bint = cast(uint*) &b;
        return *aint == *bint;
    }else static if(Format.size == 64){ // Double
        const aint = cast(ulong*) &a;
        const bint = cast(ulong*) &b;
        return *aint == *bint;
    }else static if(Format.size == 128 && is(ucent)){ // Something dang big
        const aint = cast(ucent*) &a;
        const bint = cast(ucent*) &b;
        return *aint == *bint;
    }else static if(Format.size == 80){ // Real
        const alow = cast(ulong*) &a;
        const blow = cast(ulong*) &b;
        const ahigh = cast(ushort*) &a;
        const bhigh = cast(ushort*) &b;
        return *alow == *blow && ahigh[4] == bhigh[4];
    }else{ // Something else
        enum words = Format.size / 64;
        enum remainder = Format.size % 64;
        const awords = cast(ulong*) &a;
        const bwords = cast(ulong*) &b;
        static if(words > 0){
            for(uint i = 0; i < words; i++){
                if(awords[i] != bwords[i]) return false;
            }
        }
        static if(remainder > 0){
            enum mask = pow2d!(remainder + 1);
            return (awords[words] & mask) == (bwords[words] & mask);
        }else{
            return true;
        }
    }
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
