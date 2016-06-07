module mach.range.random.lcong;

private:

import std.traits : isIntegral;
import std.math : abs;
import mach.math : flog2;
import mach.range.random.seed : seed;

public:



// References:
// https://en.wikipedia.org/wiki/Linear_congruential_generator



alias canLinearCongruential = isIntegral;



/// Create a range generating pseudorandom numbers using a linear congruential
/// generator.
auto lcong(T = ulong)() if(canLinearCongruential!T){
    return lcong!T(seed!T);
}

/// ditto
auto lcong(T = ulong)(T seed) if(canLinearCongruential!T){
    return LinearCongruentialRange!T(seed);
}

/// ditto
auto lcong(T = ulong)(T[3] seeds) if(canLinearCongruential!T){
    return LinearCongruentialRange!T(seeds);
}



struct LinearCongruentialRange(T) if(canLinearCongruential!T){
    static enum ubyte seeds = 1;
    
    T front, a, c; // m = T.sizeof * 8;
    
    this(typeof(this) range){
        this.seed!false(range.front, range.a, range.c);
    }
    this(T seed){
        this.seed(seed);
    }
    this(T[3] seeds){
        this.seed(seeds);
    }
    this(T front, T a, T c){
        this.seed(front, a, c);
    }
    
    void seed(bool pop = true)(T seed){
        this.seed!pop(seed, 1103515245, 12345);
    }
    void seed(bool pop = true)(T[3] seeds){
        this.seed!pop(seeds[0], seeds[1], seeds[2]);
    }
    void seed(bool pop = true)(T front, T a, T c){
        this.front = front;
        this.a = a;
        this.c = c;
        static if(pop) this.popFront();
    }
    
    enum bool empty = false;
    
    void popFront(){
        this.front = this.front * this.a + this.c;
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
    tests("LCG", {
        foreach(n; lcong.map!(n => n % 10).head(10)){
            testgte(n, 0);
            testlt(n, 10);
        }
    });
}
