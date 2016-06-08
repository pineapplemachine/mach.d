module mach.range.random.templates;

private:

import mach.traits : isInfiniteRange, hasEnumValue;

public:



enum isRNG(T) = (
    isInfiniteRange!T && hasEnumValue!(T, `rng`, true)
);



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

