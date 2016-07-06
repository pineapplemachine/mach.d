module mach.traits.iter;

private:

import std.traits : isArray, ReturnType, isImplicitlyConvertible;
import std.math : isInfinity, isNaN;
import mach.traits.element : ElementType;
import mach.traits.index : canIndex;
import mach.traits.property : hasEnumType;

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

enum isIndexedRange(Range) = (
    isRange!Range && canIndex!Range &&
    isImplicitlyConvertible!(ReturnType!(Range.opIndex), ElementType!Range)
);

template isRandomAccessRange(Range){
    enum bool isRandomAccessRange = isRange!Range && is(typeof((inout int = 0){
        size_t index = 0;
        Range range = Range.init;
        auto front = range.front;
        auto element = range[index];
        static assert(is(typeof(front) == typeof(element)));
    }));
}

template isSlicingRange(Range){
    enum bool isSlicingRange = isRange!Range && is(typeof((inout int = 0){
        auto slice = Range.init[0 .. 0];
        static assert(is(typeof(slice) == Range));
    }));
}

/// Ranges must explicitly declare mutability
template isMutableRange(Range){
    static if(__traits(compiles, {enum mutable = Range.mutable;})){
        enum bool isMutableRange = Range.mutable;
    }else{
        enum bool isMutableRange = false;
    }
}

/// Determine if the front element of a range be reassigned with the value persisting
template isMutableFrontRange(Range){
    enum bool isMutableFrontRange = isMutableRange!Range && is(typeof((inout int = 0){
        Range range = Range.init;
        auto front = range.front;
        range.front = front;
    }));
}

/// Determine if the back element of a range be reassigned with the value persisting
template isMutableBackRange(Range){
    enum bool isMutableBackRange = isMutableRange!Range && is(typeof((inout int = 0){
        Range range = Range.init;
        auto back = range.back;
        range.back = back;
    }));
}

/// Determine if a randomly-accessed element of a range be reassigned with the value persisting
template isMutableRandomRange(Range){
    enum bool isMutableRandomRange = isMutableRange!Range && is(typeof((inout int = 0){
        Range range = Range.init;
        auto front = range.front;
        range[0] = front;
    }));
}

/// Determine if a range can have an element safely added during consumption.
/// The added element should not be included in the range's iteration.
/// The addition should persist in whatever collection backs the range, if any.
template isMutableInsertRange(Range){
    enum bool isMutableInsertRange = isMutableRange!Range && is(typeof((inout int = 0){
        Range range = Range.init;
        auto front = range.front;
        range.insert(front);
    }));
}

/// Determine if a range can have the current front element safely removed.
/// Calling removeFront should also implicitly popFront.
/// The removal should persist in whatever collection backs the range, if any.
template isMutableRemoveFrontRange(Range){
    enum bool isMutableRemoveFrontRange = isMutableRange!Range && is(typeof((inout int = 0){
        Range range = Range.init;
        range.removeFront();
    }));
}

/// Determine if a range can have the current back element safely removed.
/// Calling removeBack should also implicitly popBack.
/// The removal should persist in whatever collection backs the range, if any.
template isMutableRemoveBackRange(Range){
    enum bool isMutableRemoveBackRange = (
        isMutableRange!Range && isBidirectionalRange!Range
    ) && is(typeof((inout int = 0){
        Range range = Range.init;
        range.removeBack();
    }));
}



template isRandomAccessIterable(T){
    enum bool isRandomAccessIterable = isIterable!T && is(typeof((inout int = 0){
        size_t index = 0;
        auto element = T.init[index];
        static assert(is(ElementType!T == typeof(element)));
    }));
}



enum hasEmptyEnum(T) = hasEnumType!(T, bool, `empty`);

template hasEmptyEnum(T, bool value){
    static if(hasEmptyEnum!T){
        enum bool hasEmptyEnum = T.empty is value;
    }else{
        enum bool hasEmptyEnum = false;
    }
}

enum hasTrueEmptyEnum(T) = hasEmptyEnum!(T, true);

enum hasFalseEmptyEnum(T) = hasEmptyEnum!(T, false);



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



version(unittest){
    private:
    struct EmptyEnumTrue{
        enum bool empty = true;
    }
    struct EmptyEnumFalse{
        enum bool empty = false;
    }
    struct EmptyEnumInt{
        enum int empty = 13;
    }
}
unittest{
    // TODO: More tests
    static assert(hasEmptyEnum!EmptyEnumTrue);
    static assert(hasEmptyEnum!EmptyEnumFalse);
    static assert(!hasEmptyEnum!EmptyEnumInt);
    static assert(hasEmptyEnum!(EmptyEnumTrue, true));
    static assert(hasEmptyEnum!(EmptyEnumFalse, false));
}
