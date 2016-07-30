module mach.traits.element.array;

private:

import mach.traits.array : isArray;

public:



/// Get the element type of an array.
template ArrayElementType(alias T) if(isArray!(typeof(T))){
    alias ArrayElementType = typeof(T[0]);
}
/// ditto
template ArrayElementType(T) if(isArray!T){
    alias ArrayElementType = typeof(T.init[0]);
}



unittest{
    int[] ints;
    string[] strings;
    static assert(is(ArrayElementType!(ints) == int));
    static assert(is(ArrayElementType!(strings) == string));
    static assert(is(ArrayElementType!(int[]) == int));
    static assert(is(ArrayElementType!(string[]) == string));
    static assert(is(ArrayElementType!(int[][]) == int[]));
    static assert(is(ArrayElementType!(int[4][]) == int[4]));
    static assert(is(ArrayElementType!(int[][4]) == int[]));
}

