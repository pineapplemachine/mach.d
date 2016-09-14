module mach.traits.index;

private:

import std.meta : AliasSeq;
import std.traits : Parameters;
import std.traits : isNumeric, isArray, isAssociativeArray, KeyType;

public:



/// Get whether a type can be indexed using the given argument types.
enum bool canIndex(alias T, Index...) = canIndex!(typeof(T), Index);
/// ditto
template canIndex(T, Index...){
    enum bool canIndex = is(typeof({auto x = T.init[Index.init];}));
}

/// Get whether a type can be indexed using a single numeric argument.
enum hasNumericIndex(alias T) = hasNumericIndex!(typeof(T));
/// ditto
enum hasNumericIndex(T) = is(typeof({auto x = T.init[0];}));

/// Get the type returned when indexing some type with the given arguments.
template IndexType(alias T, Index...) if(canIndex!(T, Index)){
    alias IndexType = IndexType!(typeof(T), Index);
}
/// ditto
template IndexType(T, Index...) if(canIndex!(T, Index)){
    alias IndexType = typeof(T.init[Index.init]);
}



version(unittest){
    private struct IndexTest{
        int value;
        int opIndex(in int index) const{return 0;}
    }
    private struct IndexMultiTest{
        real value;
        int opIndex(in real x, in float y) const{return 0;}
    }
}
unittest{
    static assert(canIndex!(string, size_t));
    static assert(canIndex!("hi", size_t));
    static assert(canIndex!(IndexTest, int));
    static assert(canIndex!(int[], size_t));
    static assert(canIndex!(int[][], size_t));
    static assert(canIndex!(string, size_t));
    static assert(canIndex!(IndexMultiTest, real, real));
    static assert(!canIndex!(int, int));
    static assert(!canIndex!(string, string));
    static assert(!canIndex!(IndexMultiTest, int));
}
unittest{
    static assert(hasNumericIndex!(string));
    static assert(hasNumericIndex!("hi"));
    static assert(hasNumericIndex!(int[]));
    static assert(hasNumericIndex!(IndexTest));
    static assert(!hasNumericIndex!(0));
    static assert(!hasNumericIndex!(int));
    static assert(!hasNumericIndex!(IndexMultiTest));
}
unittest{
    static assert(is(IndexType!(int[], size_t) == int));
    static assert(is(IndexType!(string[], size_t) == string));
    static assert(is(IndexType!(IndexMultiTest, real, float) == int));
}
