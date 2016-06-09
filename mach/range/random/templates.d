module mach.range.random.templates;

private:

import mach.traits : isInfiniteRange, hasEnumValue;

public:



enum isRNG(T) = (
    isInfiniteRange!T && hasEnumValue!(T, `rng`, true)
);



template RNGMixin(T){
    import std.traits : isIntegral, isFloatingPoint, isNumeric, isUnsigned;
    
    static enum bool rng = true;
    
    // This arithmetic is hard if T is signed so please don't make T signed
    static if(isNumeric!T && isUnsigned!T){
        /// Get the front of an RNG as a floating point number. Should be unbiased.
        As random(As)(in As low, in As high) if(isFloatingPoint!As){
            return this.random!As(high) + low;
        }
        
        /// ditto
        As random(As)(in As high) if(isFloatingPoint!As){
            return this.random!As * high;
        }
        
        /// ditto
        @property As random(As)() if(isFloatingPoint!As){
            return cast(As) this.front / ((cast(As) T.max) + 1);
        }
        
        /// Get the front of a RNG as an integer. Not guaranteed to be unbiased,
        /// but in all but the most uncommon use cases it will be close enough
        /// that it really doesn't matter.
        As random(As)(in As low, in As high) if(
            isIntegral!As && As.sizeof <= T.sizeof
        ) in{
            assert(high - low <= T.max);
        }body{
            return low + this.front % (high - low);
        }
        
        /// ditto
        As random(As)(As high) if(
            isIntegral!As && As.sizeof <= T.sizeof
        ){
            return cast(As) (this.front % high);
        }
        
        /// ditto
        @property As random(As)() if(
            isIntegral!As && As.sizeof <= T.sizeof
        ){
            return cast(As) this.front; // Assumes overflow wraps around
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.random.lcong : lcong;
    import mach.range.random.mersenne : mersenne;
    import mach.range.random.xorshift : xorshift;
}
unittest{
    static assert(isRNG!(typeof(lcong())));
    static assert(isRNG!(typeof(mersenne())));
    static assert(isRNG!(typeof(xorshift())));
    static assert(!isRNG!int);
    static assert(!isRNG!(int[]));
}

