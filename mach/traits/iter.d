module mach.traits.iter;

private:

import std.traits : isImplicitlyConvertible;
import std.math : isInfinity, isNaN;
import mach.traits.array : isArray;
import mach.traits.element.type : ElementType, hasElementType;
import mach.traits.property : hasEnumType;

public:



enum bool isIterable(T) = is(typeof({
    foreach(elem; T.init){}
}));
enum bool isIterableReverse(T) = is(typeof({
    foreach_reverse(elem; T.init){}
}));



template isRandomAccessIterable(T){
    enum bool isRandomAccessIterable = isIterable!T && is(typeof({
        size_t index = 0;
        auto element = T.init[index];
        static assert(is(ElementType!T == typeof(element)));
    }));
}



template isIterableOf(T, Element){
    enum bool isIterableOf = isIterable!T && hasElementType!(Element, T);
}

template isIterableOf(T, alias pred){
    enum bool isIterableOf = isIterable!T && hasElementType!(Element, T);
}



/// This logic is meaningless when not combined with something like isIterable 
/// or isRange. If an `empty` enum is present, then its boolean value is used.
/// Otherwise, if the target has a length that isn't infinite or NaN upon
/// instantiation, then the target is considered finite.
template isFinite(Iter){
    import mach.traits.range : isRange, hasEmptyEnum; // TODO: Better organization
    static if(isArray!Iter){
        enum bool isFinite = true;
    }else static if(hasEmptyEnum!Iter){
        enum bool isFinite = Iter.empty;
    }else static if(isRange!Iter){
        // Assume that a valid range without empty defined as an enum is finite
        enum bool isFinite = true;
    }else{
        enum bool isFinite = is(typeof({
            Iter iter = iter.init;
            auto length = iter.length;
            static if(isFloatingPoint!(typeof(length))){
                static assert(!isInfinity(length) && !isNan(length));
            }
        }));
    }
}

enum isInfinite(Iter) = !isFinite!Iter;



enum isFiniteIterable(Iter) = isIterable!Iter && isFinite!Iter;
enum isInfiniteIterable(Iter) = isIterable!Iter && isInfinite!Iter;
enum isFiniteIterableReverse(Iter) = isIterableReverse!Iter && isFinite!Iter;
enum isInfiniteIterableReverse(Iter) = isIterableReverse!Iter && isInfinite!Iter;
