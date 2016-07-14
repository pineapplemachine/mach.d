module mach.range.random.xorshift;

private:

import std.traits : isIntegral;
import mach.math : flog2;
import mach.range.random.seed : seeds;
import mach.range.random.templates : RNGMixin;

public:



// References:
// https://en.wikipedia.org/wiki/Xorshift#Example_implementation
// http://www.jstatsoft.org/v08/i14/paper



alias canXorshift = isIntegral;



/// Create a range generating pseudorandom numbers using the xorshift algorithm.
auto xorshift(T = ulong)() if(canXorshift!T){
    return xorshift!T(seeds!(T, 4));
}

/// ditto
auto xorshift(T = ulong)(T[4] seeds) if(canXorshift!T){
    return XorshiftRange!T(seeds);
}



struct XorshiftRange(T) if(canXorshift!T){
    mixin RNGMixin!T;
    
    static enum size_t seeds = 4;
    
    // Funky algorithm for selecting shifting primes based on the recommendation
    // of using [13, 7, 17] for 64-bit integers.
    static immutable ubyte[] Primes = [
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37
    ];
    static immutable ubyte[3] Shift = [
        Primes[flog2(T.sizeof) + 2],
        Primes[flog2(T.sizeof) + 0],
        Primes[flog2(T.sizeof) + 3],
    ];
    
    T front;
    T x, y, z;
    
    this(typeof(this) range){
        this.seed!false(range.front, range.x, range.y, range.z);
    }
    this(T[4] seeds){
        this.seed(seeds);
    }
    this(T front, T x, T y, T z){
        this.seed(front, x, y, z);
    }
    
    void seed(bool pop = true)(T seed){
        // Please don't use this
        this.seed!pop(T, T * 1571, T * 83, T * 18371);
    }
    void seed(bool pop = true)(T[4] seeds){
        this.seed!pop(seeds[0], seeds[1], seeds[2], seeds[3]);
    }
    void seed(bool pop = true)(T front, T x, T y, T z){
        this.front = front;
        this.x = x;
        this.y = y;
        this.z = z;
        static if(pop) this.popFront();
    }
    
    enum bool empty = false;
    
    void popFront(){
        T t = this.x;
        t ^= t << Shift[0];
        t ^= t >> Shift[1];
        this.x = this.y;
        this.y = this.z;
        this.z = this.front;
        this.front ^= this.front >> Shift[2];
        this.front ^= t;
    }
    
    @property typeof(this) save() const{
        return typeof(this)(this);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.ends : head;
    import mach.range.map : map;
}
unittest{
    tests("Xorshift", {
        static assert(canXorshift!uint);
        static assert(canXorshift!ulong);
        static assert(canXorshift!ushort);
        static assert(canXorshift!ubyte);
        static assert(!canXorshift!real);
        static assert(!canXorshift!string);
        foreach(n; xorshift.map!(n => n % 10).head(10)){
            testgte(n, 0);
            testlt(n, 10);
        }
    });
}
