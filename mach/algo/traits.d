module mach.algo.traits;

private:

import std.traits : ReturnType, isIterable, isSomeFunction;

public:

/// Distinct from standard library template in that length is not required to
/// be implicitly convertible to ulong.
template hasLength(T){
    enum bool hasLength = is(typeof((inout int = 0){
        auto len = T.init.length;
    }));
}

template LengthType(T) if(hasLength!T){
    static if(isSomeFunction!(T.length)){
        alias LengthType = ReturnType!(T.length);
    }else{
        alias LengthType = typeof(T.length);
    }
}

/// Determine whether some type is a range.
/// Defined separately from std.range.primitives.isInputRange to avoid arrays-
/// masquarading-as-ranges tomfoolery.
template isRange(Range){
    enum bool isRange = is(typeof((inout int = 0){
        Range range = Range.init;
        if(range.empty){}
        auto element = range.front;
        range.popFront();
    }));
}

/// Distinct from standard library template in that it applies not only to
/// ranges with a false empty enum, but also to other iterable objects with any
/// length implementation.
template isInfinite(Iter) if(isIterable!Iter){
    static if(isRange!Iter){
        static if(__traits(compiles, {enum e = Iter.empty;})){
            enum bool isInfinite = !Iter.empty;
        }else{
            enum bool isInfinite = false;
        }
    }else{
        enum bool isInfinite = hasLength!Iter;
    }
}

enum isFinite(Iter) = !isInfinite!Iter;

template hasUnaryOp(T, string op){
    enum bool hasUnaryOp = is(typeof((inout int = 0){
        mixin(`T value = T.init; value++;`);
    }));
}
template hasBinaryOp(T, string op){
    enum bool hasBinaryOp = is(typeof((inout int = 0){
        mixin(`T value = T.init ` ~ op ~ ` T.init;`);
    }));
}

enum canIncrement(T) = hasUnaryOp!(T, "++");
enum canDecrement(T) = hasUnaryOp!(T, "--");

enum bool isIterableReverse(T) = is(typeof({foreach_reverse(elem; T.init){}}));
