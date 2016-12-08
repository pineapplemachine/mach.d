module mach.range.random.templates;

private:

import mach.traits : isInfiniteRange, hasEnumValue;

public:



enum isRNG(T) = (
    isInfiniteRange!T && hasEnumValue!(T, `rng`, true)
);



template RNGMixin(T){
    import mach.traits : isIntegral, isFloatingPoint, isNumeric, isUnsigned;
    import mach.traits : isEnumType, getEnumLength, getenummember;
    
    static enum bool rng = true;
    
    // This arithmetic is hard if T is signed so please don't make T signed
    static if(isNumeric!T && isUnsigned!T){
        /// Get the front of an RNG as a floating point number. Should be unbiased.
        /// The range is inclusive.
        As random(As)(in As low, in As high) if(isFloatingPoint!As){
            return this.random!As(high - low) + low;
        }
        
        /// ditto
        As random(As)(in As high) if(isFloatingPoint!As){
            return this.random!As * high;
        }
        
        /// ditto
        @property As random(As)() if(isFloatingPoint!As){
            scope(exit) this.popFront();
            return (cast(As) this.front) / (cast(As) T.max);
        }
        
        /// Get the front of a RNG as an integer. Not guaranteed to be unbiased,
        /// but in all but the most uncommon use cases it will be close enough
        /// that it really doesn't matter.
        As random(As)(in As low, in As high) if(
            isIntegral!As && As.sizeof <= T.sizeof
        ) in{
            assert(high - low <= T.max);
        }body{
            scope(exit) this.popFront();
            return cast(As)(low + this.front % (high - low));
        }
        
        /// ditto
        As random(As)(As high) if(
            isIntegral!As && As.sizeof <= T.sizeof
        ){
            scope(exit) this.popFront();
            return cast(As) (this.front % high);
        }
        
        /// ditto
        @property As random(As)() if(
            isIntegral!As && As.sizeof <= T.sizeof
        ){
            scope(exit) this.popFront();
            return cast(As) this.front; // Assumes overflow wraps around
        }
        
        /// Get the front of an RNG as a member of an enum.
        /// Not guaranteed to be unbiased, but should be close enough for almost
        /// any use case.
        As random(As)() if(isEnumType!As){
            scope(exit) this.popFront();
            return getenummember!As(this.random!size_t(getEnumLength!As));
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
    import mach.range.random.lcong : lcong;
    import mach.range.random.mersenne : mersenne;
    import mach.range.random.xorshift : xorshift;
    enum Enum{A, B, C}
}
unittest{
    // TODO
    static assert(isRNG!(typeof(lcong())));
    static assert(isRNG!(typeof(mersenne())));
    static assert(isRNG!(typeof(xorshift())));
    static assert(!isRNG!int);
    static assert(!isRNG!(int[]));
    foreach(RNG; Aliases!(lcong, mersenne, xorshift)){
        auto rng = RNG();
        Enum e = rng.random!Enum; // Enum
        foreach(test; 0 .. 20){
            foreach(low; [1, 0, -1, -2, -3, -4]){
                foreach(high; [2, 3, 4, 5, 6, 7, 8, 9]){
                    auto i = rng.random!int(low, high); // Signed int
                    assert(i >= low && i < high);
                    auto f = rng.random!double(low, high); // Float
                    assert(f >= low && f <= high);
                }
            }
        }
    }
}

