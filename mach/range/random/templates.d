module mach.range.random.templates;

private:

import mach.traits : isInfiniteRange, hasEnumValue;

public:



enum isRNG(T) = (
    isInfiniteRange!T && hasEnumValue!(T, `rng`, true)
);



template RNGMixin(T){
    import mach.traits : isIntegral, isFloatingPoint, isNumeric, isUnsigned;
    import mach.traits : isCharacter, isEnumType, getEnumLength, getenummember;
    import mach.traits : Unsigned, SmallerType;
    import mach.math : abs, intdiff, pow2d, round;
    
    static enum bool rng = true;
    
    // This arithmetic is hard if T is signed so please don't make T signed
    static if(isNumeric!T && isUnsigned!T){
        /// Get a random number of a given integral type.
        As random(As)() if(isIntegral!As || isCharacter!As){
            static if(As.sizeof <= T.sizeof){
                scope(exit) this.popFront();
                return cast(As) this.front;
            }else{
                alias Smaller = SmallerType!As;
                static assert(As.sizeof == Smaller.sizeof * 2); // Verify assumption
                enum shift = (As.sizeof - Smaller.sizeof) * 8;
                return cast(As)(
                    this.random!Smaller | (cast(As) this.random!Smaller << shift)
                );
            }
        }
        
        /// Get a given number of random bits stored in the lower bits of
        /// an unsigned integer.
        auto randombits(uint bits)(){
            static if(bits <= 32){
                return this.random!uint & pow2d!bits;
            }else static if(bits <= 64){
                return this.random!ulong & pow2d!bits;
            }else static if(bits <= 128 && is(ucent)){
                return this.random!ucent & pow2d!bits;
            }else{
                static assert(false, "Too many bits to fit into a primitive.");
            }
        }
        
        /// Get a random boolean.
        /// When the output of the PRNG algorithm is uniform, so is the choice
        /// of true or false.
        @property As random(As: bool)(){
            scope(exit) this.popFront();
            return (this.front & 1) != 0;
        }
        /// Get a random boolean, with a probability from 0 to 1 of outputting true.
        /// If the input is <= 0, the function always returns false.
        /// If the input is >= 1, the function always returns true.
        @property As random(As: bool)(in double ptrue){
            return this.random!double <= ptrue;
        }
        
        /// Get a random float in the range [0, 1).
        @property As random(As)() if(isFloatingPoint!As){
            return this.random!ulong / (cast(As) ulong.max + 1);
        }
        /// Get a random float in the range [0, high).
        @property As random(As)(in As high) if(isFloatingPoint!As){
            return this.random!As * high;
        }
        /// Get a random float in the range [low, high).
        @property As random(As)(in As low, in As high) if(isFloatingPoint!As){
            return this.random!As * (high - low) + low;
        }
        
        /// Get a random integer in the range [0, high].
        /// Favors uniformity over efficiency.
        As random(As)(in As high) if(isIntegral!As || isCharacter!As){
            return cast(As)(this.random!double * (cast(double) high + 1));
        }
        /// Get a random integer in the range [low, high].
        /// Favors uniformity over efficiency.
        As random(As)(in As low, in As high) if(isIntegral!As || isCharacter!As){
            return cast(As)(this.random!double * (cast(double) high - low + 1) + cast(double) low);
        }
        
        /// Get a random integer in the range [0, high].
        /// Favors efficiency over uniformity of output.
        As fastrandom(As)(in As high) if(isIntegral!As || isCharacter!As){
            static if(isUnsigned!As){
                if(high == As.max) return this.random!As;
                else return this.random!As % (high + 1);
            }else{
                immutable rand = this.random!As;
                if(high == As.max){
                    return rand == As.min ? 0 : abs(rand);
                }else{
                    return rand == As.min ? 0 : abs(rand) % (high + 1);
                }
            }
        }
        /// Get a random integer in the range [low, high].
        /// Favors efficiency over uniformity of output.
        As fastrandom(As)(in As low, in As high) if(isIntegral!As || isCharacter!As){
            if(high == As.max && low == As.min) return this.random!As;
            static if(isUnsigned!As){
                return low + (this.random!As % (high - low + 1));
            }else{
                alias UAs = Unsigned!As;
                return cast(As)(low + random!UAs(0, intdiff(high, low)));
            }
        }
        
        /// Get a random member of an enum.
        As random(As)() if(isEnumType!As){
            scope(exit) this.popFront();
            return getenummember!As(this.random!size_t(getEnumLength!As - 1));
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
        Enum e = rng.random!Enum;
        foreach(test; 0 .. 20){
            foreach(low; [1, 0, -1, -2, -3, -4]){
                foreach(high; [2, 3, 4, 5, 6, 7, 8, 9]){
                    auto i = rng.random!int(low, high); // Signed int
                    assert(i >= low && i <= high);
                    auto f = rng.random!double(low, high); // Float
                    assert(f >= low && f <= high);
                }
            }
        }
    }
}

