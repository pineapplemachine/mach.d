module mach.traits.element.array;

private:

import mach.traits.array : isArray;

/++ Docs

The `ArrayElementType` template may be used to get the element type of some
built-in array type, whether static or dynamic.

+/

unittest{ /// Example
    static assert(is(ArrayElementType!(int[]) == int));
}

public:



/// Get the element type of an array.
template ArrayElementType(T) if(isArray!T){
    alias ArrayElementType = typeof(T.init[0]);
}



unittest{
    static assert(is(ArrayElementType!(int[]) == int));
    static assert(is(ArrayElementType!(const(int)[]) == const(int)));
    static assert(is(ArrayElementType!(string[]) == string));
    static assert(is(ArrayElementType!(int[][]) == int[]));
    static assert(is(ArrayElementType!(int[4][]) == int[4]));
    static assert(is(ArrayElementType!(int[][4]) == int[]));
}

