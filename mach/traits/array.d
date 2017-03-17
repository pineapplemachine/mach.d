module mach.traits.array;

private:

/++ Docs

The `isArray` template may be used to determine whether an input type is a
static or dynamic array.

+/

unittest{ /// Example
    static assert(isArray!(int[4]));
    static assert(isArray!(string));
    static assert(!isArray!(float));
}

/++ Docs

The `isArrayOf` template evaluates true when an input type is an array of
elements of a given type.

+/

unittest{ /// Example
    static assert(isArrayOf!(int, int[4]));
    static assert(isArrayOf!(immutable char, string));
    static assert(!isArrayOf!(int, float[]));
}

/++ Docs

The `isStaticArray` and `isDynamicArray` templates may be used to determine
whether a type is a statically-sized or dynamic array, respectively.

+/

unittest{ /// Example
    static assert(isStaticArray!(int[4]));
    static assert(isDynamicArray!(string));
}

public:



/// Determine if a type is a static or dynamic array.
template isArray(T){
    enum bool isArray = !is(T == typeof(null)) && is(typeof({
        auto x(X)(X[] y){}
        x(T.init);
    }));
}



/// Determine whether some type is an array of a specific element type.
template isArrayOf(E, T){
    enum bool isArrayOf = isArray!T && is(typeof({
        E[] x = T.init.dup;
    }));
}

/// Determine whether some type is an array of a type satisfying a predicate.
template isArrayOf(alias pred, T){
    static if(isArray!T){
        enum bool isArrayOf = pred!(typeof(T.init[0]));
    }else{
        enum bool isArrayOf = false;
    }
}



/// Determine if a type is a static array.
template isStaticArray(T){
    enum bool isStaticArray = is(typeof({
        auto x(X, size_t n)(X[n] y){}
        x(T.init);
    }));
}

/// Determine if a type is a dynamic array.
template isDynamicArray(T){
    enum bool isDynamicArray = isArray!T && !isStaticArray!T;
}



unittest{
    static assert(isArray!(int[0]));
    static assert(isArray!(int[1]));
    static assert(isArray!(int[2]));
    static assert(isArray!(string[4]));
    static assert(isArray!(int[]));
    static assert(isArray!(string[]));
    static assert(isArray!(int[][]));
    static assert(!isArray!(void));
    static assert(!isArray!(int));
    static assert(!isArray!(int[int]));
}
unittest{
    static assert(isArrayOf!(int, int[]));
    static assert(isArrayOf!(int, int[2]));
    static assert(isArrayOf!(int[], int[][]));
    static assert(isArrayOf!(const(int), const(int)[]));
    static assert(isArrayOf!(const(int), int[]));
    static assert(isArrayOf!(immutable(char), string));
    static assert(!isArrayOf!(void, void));
    static assert(!isArrayOf!(int, void));
    static assert(!isArrayOf!(void, int));
    static assert(!isArrayOf!(int, int));
    static assert(!isArrayOf!(int, double[]));
    static assert(!isArrayOf!(int[], int));
    static assert(!isArrayOf!(int, int[][]));
}
unittest{
    static assert(isArrayOf!(isArray, int[][]));
    static assert(!isArrayOf!(isArray, int[]));
    static assert(!isArrayOf!(isArray, int));
    static assert(!isArrayOf!(isArray, void));
}
unittest{
    static assert(isStaticArray!(int[0]));
    static assert(isStaticArray!(int[1]));
    static assert(isStaticArray!(int[2]));
    static assert(isStaticArray!(string[4]));
    static assert(!isStaticArray!(void));
    static assert(!isStaticArray!(int));
    static assert(!isStaticArray!(int[]));
    static assert(!isStaticArray!(string[]));
    static assert(!isStaticArray!(int[int]));
}
unittest{
    static assert(isDynamicArray!(int[]));
    static assert(isDynamicArray!(string));
    static assert(isDynamicArray!(int[][]));
    static assert(!isDynamicArray!(void));
    static assert(!isDynamicArray!(int));
    static assert(!isDynamicArray!(int[0]));
    static assert(!isDynamicArray!(int[1]));
    static assert(!isDynamicArray!(int[2]));
    static assert(!isDynamicArray!(string[4]));
    static assert(!isDynamicArray!(int[int]));
}
