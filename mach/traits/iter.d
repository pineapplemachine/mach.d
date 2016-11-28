module mach.traits.iter;

private:

import mach.traits.array : isArray;
import mach.traits.associativearray : isAssociativeArray;
import mach.traits.element.type : ElementType, hasElementType;
import mach.traits.property : hasEnumType;

public:




/// Determine whether some type can be iterated over using foreach.
/// Will not evaluate true for types such as tuples where all elements may
/// not be of the same type.
enum bool isIterable(T) = (
    is(typeof({
        // Must be iterable via foreach
        foreach(e; T.init){}
        // Indexes must not be known at compile-time
        // Because if they are, this is a tuple
        static if(is(typeof({foreach(i, e; T.init){}}))){
            foreach(i, e; T.init){
                static assert(!is(typeof({enum x = i;})));
            }
        }
    })) && !is(typeof({
        // Must not be an empty tuple
        foreach(e; T.init){
            static assert(false);
        }
    }))
);

/// Determine whether some type can be iterated over using foreach_reverse.
/// Will not evaluate true for types such as tuples where all elements may
/// not be of the same type.
enum bool isIterableReverse(T) = (
    is(typeof({
        // Must be iterable via foreach_reverse
        foreach_reverse(e; T.init){}
        // Indexes must not be known at compile-time
        // Because if they are, this is a tuple
        static if(is(typeof({foreach_reverse(i, e; T.init){}}))){
            foreach_reverse(i, e; T.init){
                static assert(!is(typeof({enum x = i;})));
            }
        }
    })) && !is(typeof({
        // Must not be an empty tuple
        foreach_reverse(e; T.init){
            static assert(false);
        }
    }))
);



/// Determine whether some type can be iterated over using foreach.
/// Will also evaluate true for types such as tuples where all elements may
/// not be of the same type.
enum bool isAnyIterable(T) = is(typeof({
    foreach(elem; T.init){}
}));

/// Determine whether some type can be iterated over using foreach_reverse.
/// Will also evaluate true for types such as tuples where all elements may
/// not be of the same type.
enum bool isAnyIterableReverse(T) = is(typeof({
    foreach_reverse(elem; T.init){}
}));



/// Determine whether a type is an iterable which supports random access.
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
template isFinite(T){
    static if(isIterable!T){
        import mach.traits.range : isRange, hasEmptyEnum; // TODO: Better organization
        static if(isArray!T || isAssociativeArray!T){
            enum bool isFinite = true;
        }else static if(hasEmptyEnum!T){
            enum bool isFinite = T.empty;
        }else static if(isRange!T){
            // Assumes that a valid range without empty defined as an enum is finite.
            enum bool isFinite = true;
        }else{
            static assert(false, "Unable to determine finiteness.");
        }
    }else{
        enum bool isFinite = false;
    }
}

template isInfinite(T){
    enum bool isInfinite = !isFinite!T;
}



template isFiniteIterable(T){
    static if(isIterable!T){
        enum bool isFiniteIterable = isFinite!T;
    }else{
        enum bool isFiniteIterable = false;
    }
}
template isInfiniteIterable(T){
    static if(isIterable!T){
        enum bool isInfiniteIterable = isInfinite!T;
    }else{
        enum bool isInfiniteIterable = false;
    }
}
template isFiniteIterableReverse(T){
    static if(isIterableReverse!T){
        enum bool isFiniteIterableReverse = isFinite!T;
    }else{
        enum bool isFiniteIterableReverse = false;
    }
}
template isInfiniteIterableReverse(T){
    static if(isIterableReverse!T){
        enum bool isInfiniteIterableReverse = isInfinite!T;
    }else{
        enum bool isInfiniteIterableReverse = false;
    }
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
    static assert(isIterable!string);
    static assert(isIterable!(int[]));
    static assert(isIterable!(immutable(int[])));
    static assert(isIterable!OpApply);
    static assert(isIterable!OpApplyBoth);
    static assert(isIterable!Range);
    static assert(isIterable!BiRange);
    static assert(isIterableReverse!string);
    static assert(isIterableReverse!(int[]));
    static assert(isIterableReverse!(immutable(int[])));
    static assert(isIterableReverse!OpApplyRev);
    static assert(isIterableReverse!OpApplyBoth);
    static assert(isIterableReverse!BiRange);
    static assert(!isIterable!int);
    static assert(!isIterable!void);
    static assert(!isIterable!OpApplyRev);
    static assert(!isIterableReverse!int);
    static assert(!isIterableReverse!void);
    static assert(!isIterableReverse!OpApply);
    static assert(!isIterableReverse!Range);
}
unittest{
    import mach.types.tuple : Tuple;
    static assert(!isIterable!(Tuple!()));
    static assert(!isIterable!(Tuple!(int)));
    static assert(!isIterable!(Tuple!(int, string)));
    static assert(!isIterable!(Tuple!(int, float)));
    static assert(!isIterable!(Tuple!(int, int)));
    static assert(!isIterable!(Tuple!(int, int, int)));
    static assert(!isIterableReverse!(Tuple!()));
    static assert(!isIterableReverse!(Tuple!(int)));
    static assert(!isIterableReverse!(Tuple!(int, string)));
    static assert(!isIterableReverse!(Tuple!(int, float)));
    static assert(!isIterableReverse!(Tuple!(int, int)));
    static assert(!isIterableReverse!(Tuple!(int, int, int)));
}

unittest{
    struct Range{
        enum bool empty = false; @property int front(){return 0;} void popFront(){}
    }
    struct RandomRange{
        enum bool empty = false; @property int front(){return 0;} void popFront(){}
        int opIndex(size_t){return 0;}
    }
    static assert(isRandomAccessIterable!string);
    static assert(isRandomAccessIterable!(int[]));
    static assert(isRandomAccessIterable!(immutable(int[])));
    static assert(isRandomAccessIterable!RandomRange);
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
    // isFiniteIterable
    static assert(isFiniteIterable!string);
    static assert(isFiniteIterable!(int[]));
    static assert(isFiniteIterable!(immutable(int[])));
    static assert(isFiniteIterable!EmptyRange);
    static assert(isFiniteIterable!FiniteRange);
    static assert(!isFiniteIterable!int);
    static assert(!isFiniteIterable!void);
    static assert(!isFiniteIterable!InfRange);
    // isInfiniteIterable
    static assert(isInfiniteIterable!InfRange);
    static assert(!isInfiniteIterable!string);
    static assert(!isInfiniteIterable!(int[]));
    static assert(!isInfiniteIterable!(immutable(int[])));
    static assert(!isInfiniteIterable!EmptyRange);
    static assert(!isInfiniteIterable!FiniteRange);
    static assert(!isInfiniteIterable!int);
    static assert(!isInfiniteIterable!void);
}

unittest{
    struct CharRange{
        enum bool empty = false;
        @property char front(){return 'x';}
        void popFront(){}
    }
    static assert(isIterableOf!(int[], int));
    static assert(isIterableOf!(int[4], int));
    static assert(isIterableOf!(const(int)[], const int));
    static assert(isIterableOf!(CharRange, char));
}


