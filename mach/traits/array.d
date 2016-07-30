module mach.traits.array;

private:

//

public:



/// Determine whether some type is an array.
enum bool isArray(alias T) = isArray!(typeof(T));
/// ditto
template isArray(T){
    static import std.traits;
    enum bool isArray = std.traits.isArray!T;
}

/// Determine whether some type is an array of a specific element type.
enum isArrayOf(alias Array, Element) = isArrayOf!(typeof(Array), Element);
/// ditto
template isArrayOf(Array, Element){
    import mach.traits.element.array : ArrayElementType;
    enum bool isArrayOf = (
        isArray!Array && is(ArrayElementType!Array == Element)
    );
}



unittest{
    int[] ints;
    static assert(isArray!ints);
    static assert(isArray!(int[]));
    static assert(isArray!string);
    static assert(!isArray!int);
}
unittest{
    int[] ints;
    static assert(isArrayOf!(ints, int));
    static assert(isArrayOf!(int[], int));
    static assert(isArrayOf!(int[][], int[]));
    static assert(!isArrayOf!(int[], real));
    static assert(!isArrayOf!(real, real));
}
