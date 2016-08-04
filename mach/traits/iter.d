module mach.traits.iter;

private:

import std.traits : isImplicitlyConvertible;
import std.math : isInfinity, isNaN;
import mach.traits.array : isArray;
import mach.traits.element.type : ElementType, hasElementType;
import mach.traits.property : hasEnumType;

public:




/// Determine whether some type can be iterated over using foreach.
enum bool isIterable(alias T) = isIterable!(typeof(T));
/// ditto
enum bool isIterable(T) = is(typeof({
    foreach(elem; T.init){}
}));

/// Determine whether some type can be iterated over using foreach_reverse.
enum bool isIterableReverse(alias T) = isIterableReverse!(typeof(T));
/// ditto
enum bool isIterableReverse(T) = is(typeof({
    foreach_reverse(elem; T.init){}
}));



/// Determine whether a type is an iterable which supports random access.
enum bool isRandomAccessIterable(alias T) = isRandomAccessIterable!(typeof(T));
/// ditto
template isRandomAccessIterable(T){
    enum bool isRandomAccessIterable = isIterable!T && is(typeof({
        auto element = T.init[0];
        static assert(is(ElementType!T == typeof(element)));
    }));
}



/// Determine whether some type is an iterable of elements of the given type.
template isIterableOf(T, Element){
    enum bool isIterableOf = isIterable!T && hasElementType!(Element, T);
}

/// Determine whether some type is an iterable of elements whose type matches
/// the given predicate template.
template isIterableOf(T, alias pred){
    enum bool isIterableOf = isIterable!T && hasElementType!(pred, T);
}



/// This logic is meaningless when not combined with something like isIterable 
/// or isRange. If an `empty` enum is present, then its boolean value is used.
template isFinite(alias T) if(isIterable!T){
    enum bool isFinite = isFinite!(typeof(T));
}
/// ditto
template isFinite(T) if(isIterable!T){
    import mach.traits.range : isRange, hasEmptyEnum; // TODO: Better organization
    static if(isArray!T){
        enum bool isFinite = true;
    }else static if(hasEmptyEnum!T){
        enum bool isFinite = T.empty;
    }else static if(isRange!T){
        // Assumes that a valid range without empty defined as an enum is finite.
        enum bool isFinite = true;
    }else{
        static assert(false, "Failed to determine finiteness.");
    }
}

template isInfinite(Tx...) if(Tx.length == 1){
    enum bool isInfinite = !isFinite!(Tx[0]);
}



template isFiniteIterable(Tx...) if(Tx.length == 1){
    enum bool isFiniteIterable = isIterable!(Tx[0]) && isFinite!(Tx[0]);
}
template isInfiniteIterable(Tx...) if(Tx.length == 1){
    enum bool isInfiniteIterable = isIterable!(Tx[0]) && isInfinite!(Tx[0]);
}
template isFiniteIterableReverse(Tx...) if(Tx.length == 1){
    enum bool isFiniteIterableReverse = isIterableReverse!(Tx[0]) && isFinite!(Tx[0]);
}
template isInfiniteIterableReverse(Tx...) if(Tx.length == 1){
    enum bool isInfiniteIterableReverse = isIterableReverse!(Tx[0]) && isInfinite!(Tx[0]);
}



unittest{
    struct OpApply{int opApply(int delegate(ref int)){return 0;}}
    struct OpApplyRev{int opApplyReverse(int delegate(ref int)){return 0;}}
    struct OpApplyBoth{
        int opApply(int delegate(ref int)){return 0;}
        int opApplyReverse(int delegate(ref int)){return 0;}
    }
    struct Range{enum bool empty = false; @property int front(){return 0;} void popFront(){}}
    struct BiRange{
        enum bool empty = false;
        @property int front(){return 0;} void popFront(){}
        @property int back(){return 0;} void popBack(){}
    }
    string str; int i;
    static assert(isIterable!str);
    static assert(isIterable!string);
    static assert(isIterable!(int[]));
    static assert(isIterable!OpApply);
    static assert(isIterable!OpApplyBoth);
    static assert(isIterable!Range);
    static assert(isIterable!BiRange);
    static assert(isIterableReverse!str);
    static assert(isIterableReverse!string);
    static assert(isIterableReverse!(int[]));
    static assert(isIterableReverse!OpApplyRev);
    static assert(isIterableReverse!OpApplyBoth);
    static assert(isIterableReverse!BiRange);
    static assert(!isIterable!i);
    static assert(!isIterable!int);
    static assert(!isIterable!void);
    static assert(!isIterable!OpApplyRev);
    static assert(!isIterableReverse!i);
    static assert(!isIterableReverse!int);
    static assert(!isIterableReverse!void);
    static assert(!isIterableReverse!OpApply);
    static assert(!isIterableReverse!Range);
}

unittest{
    struct Range{
        enum bool empty = false; @property int front(){return 0;} void popFront(){}
    }
    struct RandomRange{
        enum bool empty = false; @property int front(){return 0;} void popFront(){}
        int opIndex(size_t){return 0;}
    }
    string str;
    int i;
    static assert(isRandomAccessIterable!str);
    static assert(isRandomAccessIterable!string);
    static assert(isRandomAccessIterable!(int[]));
    static assert(isRandomAccessIterable!RandomRange);
    static assert(!isRandomAccessIterable!i);
    static assert(!isRandomAccessIterable!int);
    static assert(!isRandomAccessIterable!void);
    static assert(!isRandomAccessIterable!Range);
}

unittest{
    struct InfRange{
        enum bool empty = false; @property int front(){return 0;} void popFront(){}
    }
    struct EmptyRange{
        enum bool empty = true; @property int front(){return 0;} void popFront(){}
    }
    struct FiniteRange{
        @property bool empty(){return true;}; @property int front(){return 0;} void popFront(){}
    }
    string str;
    static assert(isFiniteIterable!str);
    static assert(isFiniteIterable!string);
    static assert(isFiniteIterable!(int[]));
    static assert(isFiniteIterable!EmptyRange);
    static assert(isFiniteIterable!FiniteRange);
    //static 
}


