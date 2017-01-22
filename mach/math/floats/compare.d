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
        immutable aint = *(cast(uint*) &a);
        immutable bint = *(cast(uint*) &b);
        return aint == bint;
    }else static if(Format.size == 64){ // Double
        immutable aint = *(cast(ulong*) &a);
        immutable bint = *(cast(ulong*) &b);
        return aint == bint;
    }else static if(Format.size == 128 && is(ucent)){ // Something dang big
        immutable aint = *(cast(ucent*) &a);
        immutable bint = *(cast(ucent*) &b);
        return aint == bint;
    }else{ // Probably real
        enum words = Format.size / 64;
        enum remainder = Format.size % 64;
        static if(words > 0){
            for(uint i = 0; i < words; i++){
                immutable aword = *(cast(ulong*) &a + i);
                immutable bword = *(cast(ulong*) &b + i);
                if(aword != bword) return false;
            }
        }
        static if(remainder > 0){
            enum mask = pow2d!(remainder + 1);
            immutable arem = *(cast(ulong*) &a + words) & mask;
            immutable brem = *(cast(ulong*) &b + words) & mask;
            return arem == brem;
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
