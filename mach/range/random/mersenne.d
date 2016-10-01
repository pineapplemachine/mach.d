module mach.range.random.mersenne;

private:

import mach.traits : isIntegral;
import mach.range.random.seed : seed;
import mach.range.random.templates : RNGMixin;

public:



// References:
// https://en.wikipedia.org/wiki/Mersenne_Twister#Pseudocode



enum canMersenne(T) = (
    isIntegral!T && (T.sizeof == 4 || T.sizeof == 8)
);



/// Create a range generating pseudorandom numbers using the Mersenne Twister
/// algorithm.
auto mersenne(T = ulong)() if(canMersenne!T){
    return mersenne!T(seed!T);
}

/// ditto
auto mersenne(T = ulong)(T seed) if(canMersenne!T){
    return MersenneRange!T(seed);
}



struct MersenneRange(T) if(canMersenne!T){
    mixin RNGMixin!T;
    
    static enum size_t seeds = 1;
    
    static if(T.sizeof == 4){
        static enum Constant : T{
            w = 32, n = 624, m = 397, r = 31,
            a = 0x9908B0DF,
            u = 11, d = 0xFFFFFFFF,
            s = 7, b = 0x9D2C5680,
            t = 15, c = 0xEFC60000,
            l = 18,
            f = 1812433253,
        }
    }else{
        static enum Constant : T{
            w = 64, n = 312, m = 156, r = 31,
            a = 0xB5026F5AA96619E9,
            u = 29, d = 0x5555555555555555,
            s = 17, b = 0x71D67FFFEDA60000,
            t = 37, c = 0xFFF7EEE000000000,
            l = 43,
            f = 6364136223846793005,
        }
    }
    
    static enum T LowerMask = (1 << Constant.r) - 1;
    static enum T UpperMask = !LowerMask;
    
    T front;
    size_t index;
    T[Constant.n] MT;
    
    this(typeof(this) range){
        this.MT[] = range.MT[];
        this.index = range.index;
        this.front = range.front;
    }
    this(T seed){
        this.seed(seed);
    }
    
    void seed(bool pop = true)(T seed){
        this.index = Constant.n;
        this.MT[0] = seed;
        foreach(size_t i; 1 .. Constant.n){
            this.MT[i] = (
                (this.MT[i - 1] ^ (this.MT[i - 1] >> (Constant.w - 2))) *
                Constant.f + i
            );
        }
        static if(pop) this.popFront();
    }
    
    enum bool empty = false;
    
    void popFront(){
        if(this.index >= Constant.n) this.twist();
        T y = this.MT[this.index++];
        y ^= ((y >> Constant.u) & Constant.d);
        y ^= ((y >> Constant.s) & Constant.b);
        y ^= ((y >> Constant.t) & Constant.c);
        y ^= y >> 1;
        this.front = y;
    }
    
    void twist(){
        this.index = 0;
        foreach(size_t i; 0 .. Constant.n){
            T x = (
                (this.MT[i] & UpperMask) +
                (this.MT[(i + 1) % Constant.n] & LowerMask)
            );
            T xA = x >> 1;
            if(x % 2 != 0) xA ^= Constant.a;
            this.MT[i] = this.MT[(i + Constant.m) % Constant.n] ^ xA;
        }
    }
    
    @property typeof(this) save(){
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
    tests("Mersenne Twister", {
        foreach(n; mersenne.map!(n => n % 10).head(10)){
            testgte(n, 0);
            testlt(n, 10);
        }
    });
}
