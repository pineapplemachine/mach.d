module mach.range.random.seed;

private:

import core.stdc.stdlib : malloc, free;
import core.thread : MonoTime, Thread, getpid;
import mach.meta : max = varmax;
import mach.traits : isIntegral, Unqual;
import mach.range.reduce : reduce;
import mach.range.map : map;

public:



/// Not guaranteed to be cryptographically secure.
auto seeds(T, size_t count)(T[] entropy...) @trusted nothrow if(
    isIntegral!T && count > 0
){
    static Unqual!T counter = 4;
    auto mem = malloc(size_t.sizeof); free(mem);
    // The more values are in this array, the better this function's entropy.
    auto seedentropy = entropy ~ [
        cast(T) MonoTime.currTime.ticks,
        cast(T) cast(void*) Thread.getThis(),
        cast(T) getpid(),
        cast(T) mem,
        cast(T) counter,
    ];
    T[count] output;
    enum shift = T.sizeof * 4;
    foreach(i; 0 .. max(count, seedentropy.length)){
        auto e = seedentropy[i % seedentropy.length];
        output[i % count] ^= e << shift;
        output[i % count] ^= e >> shift;
        output[i % count] *= e;
        counter *= e;
        counter ^= e >> shift;
    }
    return output;
}

auto seeds(size_t count, T = ulong)(T[] entropy...) @trusted nothrow if(count > 0){
    return seeds!(T, count);
}

auto seed(T)(T[] entropy...) @trusted nothrow if(isIntegral!T){
    return seeds!(T, 1)[0];
}



/// Generate a seed where performance is more important than entropy.
auto cheapseed() @trusted nothrow{
    return MonoTime.currTime.ticks ^ getpid();
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Seed", {
        testeq(seeds!2.length, 2);
        testeq(seeds!10.length, 10);
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
            this.front = seeds!(ulong, 1)[0];
        }
        void popFront(){this.front = seeds!(ulong, 1)[0];}
    }
    auto range = Seeds(0).head(1_000_000).distinct;
    assert(range.walklength >= 999_990);
}
+/
