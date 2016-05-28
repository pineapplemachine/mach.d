module mach.range.traits;

private:

import std.meta : staticIndexOf, AliasSeq;
import std.traits : Parameters, ReturnType, isSomeFunction, fullyQualifiedName;
import std.traits : isArray, isAssociativeArray, KeyType;
import std.math : isInfinity, isNaN;

public:

/// Distinct from standard library template in that length is not required to
/// be implicitly convertible to ulong.
template hasLength(T){
    enum bool hasLength = is(typeof((inout int = 0){
        auto len = T.init.length;
    }));
}

template LengthType(T) if(hasLength!T){
    static if(isArray!T){
        alias LengthType = size_t;
    }else static if(isSomeFunction!(T.length)){
        alias LengthType = ReturnType!(T.length);
    }else{
        alias LengthType = typeof(T.length);
    }
}



enum hasDollar(T) = is(typeof(T.opDollar));



enum canIndex(T) = isArray!T || isAssociativeArray!T || is(typeof(T.opIndex));

template IndexParameters(T) if(canIndex!T){
    static if(isArray!T){
        alias IndexParameters = AliasSeq!(size_t);
    }else static if(isAssociativeArray!T){
        alias IndexParameters = AliasSeq!(KeyType!T);
    }else{
        alias IndexParameters = Parameters!(T.opIndex);
    }
}

template hasSingleIndexParameter(T){
    enum bool hasSingleIndexParameter = canIndex!T && is(typeof((inout int = 0){
        static assert(IndexParameters!T.length == 1);
    }));
}

template SingleIndexParameter(T) if(hasSingleIndexParameter!T){
    alias SingleIndexParameter = IndexParameters!T[0];
}



enum bool isIterable(T) = is(
    typeof({
        foreach(elem; T.init){}
    })
);
enum bool isIterableReverse(T) = is(
    typeof({
        foreach_reverse(elem; T.init){}
    })
);



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

/// Distinct from standard library isInfinite in that it applies not only to
/// ranges with a false empty enum, but also to other iterable objects with a
/// length implementation.
enum isFiniteIterable(Iter) = isIterable!Iter && isFinite!Iter;
enum isInfiniteIterable(Iter) = isIterable!Iter && isInfinite!Iter;
enum isFiniteIterableReverse(Iter) = isIterableReverse!Iter && isFinite!Iter;
enum isInfiniteIterableReverse(Iter) = isIterableReverse!Iter && isInfinite!Iter;
enum isFiniteRange(Range) = isRange!Range && isFinite!Range;
enum isInfiniteRange(Range) = isRange!Range && isInfinite!Range;

template hasUnaryOp(T, string op){
    enum bool hasUnaryOp = is(typeof((inout int = 0){
        mixin(`T value = T.init; value++;`);
    }));
}

template hasBinaryOp(Lhs, Rhs, string op, Results...){
    enum bool hasBinaryOp = is(typeof((inout int = 0){
        mixin(`auto result = Lhs.init ` ~ op ~ ` Rhs.init;`);
        static assert(staticIndexOf!(typeof(result), Results) >= 0);
    }));
}
template hasBinaryOp(Lhs, string op){
    alias hasBinaryOp = hasBinaryOp!(Lhs, Lhs, op, Lhs);
}

enum canIncrement(T) = hasUnaryOp!(T, "++");
enum canDecrement(T) = hasUnaryOp!(T, "--");

enum hasComparison(Lhs, string op) = hasBinaryOp!(Lhs, Lhs, op, bool);
enum hasComparison(Lhs, Rhs, string op) = hasBinaryOp!(Lhs, Rhs, op, bool);

template hasOpApply(T){
    enum bool hasOpApply = is(typeof(T.opApply));
}
template hasOpApplyReverse(T){
    enum bool hasOpApplyReverse = is(typeof(T.opApplyReverse));
}

template canHash(T){
    enum bool canHash = is(typeof((inout int = 0){
        T thing = T.init;
        typeid(thing).getHash(&thing);
    }));
}



template isCastable(From, To){
    enum bool isCastable = is(From == To) || is(typeof((inout int = 0){
        From from = From.init;
        To to = cast(To) from;
    }));
}



template ArrayElementType(Array) if(isArray!Array){
    alias ArrayElementType = typeof(Array.init[0]);
}
template RangeElementType(Range) if(isRange!Range){
    static if(isSomeFunction!(Range.init.front)){
        alias RangeElementType = ReturnType!(Range.init.front);
    }else{
        alias RangeElementType = typeof(Range.init.front);
    }
}
private template OpApplyGenericElementType(Iter, op){
    alias Params = Parameters!(op);
    static assert(
        Params.length == 1 && isDelegate!(Params[0]),
        fullyQualifiedName!Iter ~ " has invalid arguments for opApply."
    );
    alias Param = Params[0];
    alias IterableElementType = Parameters!(Param[0])[0];
}
template OpApplyElementType(Iter) if(hasOpApply!Iter){
    alias OpApplyElementType = OpApplyGenericElementType!(Iter, Iter.opApply);
}
template OpApplyReverseElementType(Iter) if(hasOpApplyReverse!Iter){
    alias OpApplyReverseElementType = OpApplyGenericElementType!(Iter, Iter.opApplyReverse);
}

template ElementType(Iter){
    static if(isArray!Iter){
        alias ElementType = ArrayElementType!Iter;
    }else static if(isRange!Iter){
        alias ElementType = RangeElementType!Iter;
    }else static if(hasOpApply!Iter){
        alias ElementType = OpApplyElementType!Iter;
    }else static if(hasOpApplyReverse!Iter){
        alias ElementType = OpApplyReverseElementType!Iter;
    }else{
        static assert(false, "Unable to determine element type.");
    }
}



    import std.stdio;
    void writename(Name)(){
        import std.traits : fullyQualifiedName;
        writeln(fullyQualifiedName!Name);
    }



unittest{
    // TODO: more tests
    static assert(hasBinaryOp!(int, "+"));
    static assert(hasBinaryOp!(int, int, "+", int, long));
    static assert(!hasBinaryOp!(int, int, "+", long));
    static assert(isFinite!(int[]));
    static assert(canHash!string);
    static assert(is(ElementType!(int[]) == int));
}

version(unittest){
    struct LengthFieldTest{
        double length;
    }
    struct LengthPropertyTest{
        double len;
        @property auto length(){
            return this.len;
        }
    }
}
unittest{
    static assert(is(LengthType!(int[]) == size_t));
    static assert(is(LengthType!LengthFieldTest == double));
    static assert(is(LengthType!LengthPropertyTest == double));
}

version(unittest){
    struct IndexTest{
        int value;
        auto opIndex(in int index) const{
            return this.value + index;
        }
    }
    struct IndexMultiTest{
        real value;
        auto opIndex(in real x, in float y) const{
            return this.value + x + y;
        }
    }
}
unittest{
    // canIndex
    static assert(canIndex!(int[]));
    static assert(canIndex!IndexTest);
    static assert(canIndex!IndexMultiTest);
    // IndexParameters
    static assert(is(IndexParameters!(int[])[0] == size_t));
    static assert(is(IndexParameters!IndexTest[0] == const(int)));
    static assert(is(IndexParameters!IndexMultiTest[0] == const(real)));
    static assert(is(IndexParameters!IndexMultiTest[1] == const(float)));
    // hasSingleIndexParameter
    static assert(hasSingleIndexParameter!(int[]));
    static assert(hasSingleIndexParameter!IndexTest);
    static assert(!hasSingleIndexParameter!IndexMultiTest);
    // SingleIndexParameter
    static assert(is(SingleIndexParameter!(int[]) == size_t));
    static assert(is(SingleIndexParameter!IndexTest == const(int)));
}

version(unittest){
    struct RangeElementTest{
        int value;
        @property auto front() const{
            return this.value;
        }
        void popFront(){
            this.value++;
        }
        enum bool empty = false;
    }
}
unittest{
    static assert(is(ElementType!(int[]) == int));
    static assert(is(ElementType!(real[][]) == real[]));
    static assert(is(ElementType!RangeElementTest == const(int)));
}
