module mach.traits.iter;

private:

import std.traits : isArray;
import std.math : isInfinity, isNaN;
import mach.traits.index : canIndex;

public:



enum bool isIterable(T) = is(typeof({
    foreach(elem; T.init){}
}));
enum bool isIterableReverse(T) = is(typeof({
    foreach_reverse(elem; T.init){}
}));



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

/// Unlike the phobos template, doesn't require the range to also be a ForwardRange.
template isBidirectionalRange(Range){
    enum bool isBidirectionalRange = isRange!Range && is(typeof((inout int = 0){
        Range range = Range.init;
        auto front = range.front;
        auto back = range.back;
        static assert(is(typeof(front) == typeof(back)));
        range.popBack();
    }));
}

/// Essentially the same as isForwardRange but not so confusingly named
template isSavingRange(Range){
    enum bool isSavingRange = isRange!Range && is(typeof((inout int = 0){
        Range range = Range.init;
        auto saved = range.save;
        static assert(is(typeof(saved) == Range));
    }));
}

enum isRandomAccessRange(Range) = isRange!Range && canIndex!Range;



enum hasEmptyEnum(T) = __traits(compiles, {enum empty = T.empty;});



/// This logic is meaningless when not combined with something like isIterable 
/// or isRange. If an `empty` enum is present, then its boolean value is used.
/// Otherwise, if the target has a length that isn't infinite or NaN upon
/// instantiation, then the target is considered finite.
template isFinite(Iter){
    static if(isArray!Iter){
        enum bool isFinite = true;
    }else static if(hasEmptyEnum!Iter){
        enum bool isFinite = Iter.empty;
    }else static if(isRange!Iter){
        // Assume that a valid range without empty defined as an enum is finite
        enum bool isFinite = true;
    }else{
        enum bool isFinite = is(typeof((inout int = 0){
            Iter iter = iter.init;
            auto length = iter.length;
            static if(isFloatingPoint!(typeof(length))){
                assert(!isInfinity(length) && !isNan(length));
            }
        }));
    }
}
enum isInfinite(Iter) = !isFinite!Iter;



enum isFiniteIterable(Iter) = isIterable!Iter && isFinite!Iter;
enum isInfiniteIterable(Iter) = isIterable!Iter && isInfinite!Iter;
enum isFiniteIterableReverse(Iter) = isIterableReverse!Iter && isFinite!Iter;
enum isInfiniteIterableReverse(Iter) = isIterableReverse!Iter && isInfinite!Iter;
enum isFiniteRange(Range) = isRange!Range && isFinite!Range;
enum isInfiniteRange(Range) = isRange!Range && isInfinite!Range;



unittest{
    // TODO
}
