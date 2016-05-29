module mach.traits.array;

private:

import std.traits : isArray;
import mach.traits.element : ArrayElementType;

public:

enum isArrayOf(Array, Element) = (
    isArray!Array && is(ArrayElementType!Array == Element)
);

unittest{
    static assert(isArrayOf!(int[], int));
    static assert(isArrayOf!(int[][], int[]));
    static assert(!isArrayOf!(int[], real));
    static assert(!isArrayOf!(real, real));
}
