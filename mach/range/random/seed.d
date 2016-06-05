module mach.range.random.seed;

private:

import core.stdc.stdlib : malloc, free;
import core.thread : MonoTime, Thread, getpid;
import std.algorithm : max;
import std.traits : isIntegral;
import mach.range.chunk : divide;
import mach.range.reduce : reduce;
import mach.range.map : map;

public:



/// Not guaranteed to be cryptographically secure.
auto seeds(T, size_t count)() if(isIntegral!T && count > 0){
    static T counter = 4;
    auto mem = malloc(size_t.sizeof); free(mem);
    // The more values are in this array, the better this function's entropy.
    auto entropy = [
        cast(const T) MonoTime.currTime.ticks,
        cast(const T) cast(void*) Thread.getThis(),
        cast(const T) getpid(),
        cast(const T) mem,
        cast(const T) counter,
    ];
    T[count] output;
    foreach(i; 0 .. max(count, entropy.length)){
        auto e = entropy[i % entropy.length];
        output[i % count] ^= e;
        counter *= e; counter ^= e;
    }
    return output;
}

auto seeds(size_t count)() if(count > 0){
    return seeds!(ulong, count);
}

auto seed(T)() if(isIntegral!T){
    return seeds!(T, 1)[0];
}



/// Generate a seed where performance is more important than entropy.
auto cheapseed(){
    return MonoTime.currTime.ticks ^ getpid();
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Seed", {
        testeq(seeds!2.length, 2);
        testeq(seeds!10.length, 10);
        testtype!uint(seed!uint);
        testtype!ulong(seed!ulong);
    });
}

/+
unittest{
    /// Strictly speaking nondeterministic, but if this test ever fails then
    /// something very probably went very wrong.
    import mach.range.distinct;
    import mach.range.ends;
    import mach.range.walk;
    struct Seeds{
        enum bool empty = false;
        ulong front;
        this(size_t front){
            this.front = seeds!ulong[0];
        }
        void popFront(){this.front = seeds!ulong[0];}
    }
    auto range = Seeds(0).head(1_000_000).distinct;
    assert(range.walk >= 999_990);
}
+/
