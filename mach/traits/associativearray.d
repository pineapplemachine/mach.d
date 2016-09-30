module mach.traits.associativearray;

private:

//

public:



/// Determine if a type is an associative array.
enum isAssociativeArray(alias T) = isAssociativeArray!(typeof(T));
/// ditto
template isAssociativeArray(T){
    enum bool isAssociativeArray = is(typeof({
        auto x(K, V)(K[V] array){}
        x(T.init);
    }));
}



/// Get the key type for an associative array.
enum ArrayKeyType(alias T) = ArrayKeyType!(typeof(T));
/// ditto
template ArrayKeyType(T) if(isAssociativeArray!T){
    alias ArrayKeyType = typeof(T.init.keys[0]);
}

/// Get the value type for an associative array.
enum ArrayValueType(alias T) = ArrayValueType!(typeof(T));
/// ditto
template ArrayValueType(T) if(isAssociativeArray!T){
    alias ArrayValueType = typeof(T.init.values[0]);
}



unittest{
    int[int] aa;
    static assert(isAssociativeArray!(aa));
    static assert(isAssociativeArray!(int[int]));
    static assert(isAssociativeArray!(char[int]));
    static assert(isAssociativeArray!(const(int)[const(int)]));
    static assert(isAssociativeArray!(int[][string]));
    static assert(!isAssociativeArray!(null));
    static assert(!isAssociativeArray!(void));
    static assert(!isAssociativeArray!(int));
    static assert(!isAssociativeArray!(int[]));
    static assert(!isAssociativeArray!(string));
    static assert(!isAssociativeArray!(int[int][]));
}
unittest{
    static assert(is(ArrayKeyType!(int[int]) == int));
    static assert(is(ArrayKeyType!(double[int]) == int));
    static assert(is(ArrayKeyType!(int[double]) == double));
    static assert(is(ArrayKeyType!(int[string]) == string));
}
unittest{
    static assert(is(ArrayValueType!(int[int]) == int));
    static assert(is(ArrayValueType!(int[double]) == int));
    static assert(is(ArrayValueType!(double[int]) == double));
    static assert(is(ArrayValueType!(int[string]) == int));
}
