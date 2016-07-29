module mach.traits.element;

private:

import std.meta : staticMap;
import std.traits : isArray, fullyQualifiedName;
import std.traits : Parameters;
import mach.traits.call : isDelegate, isCallableWith;
import mach.traits.common : hasCommonType, CommonType;
import mach.traits.hash : canHash;
import mach.traits.iter : isRange, isIterable;
import mach.traits.mutability : isMutable;
import mach.traits.op : hasOpApply, hasOpApplyReverse;
import mach.traits.transform : isTransformation, isPredicate;

public:



/// Get the element type of an array.
//template ArrayElementType(alias Array) if(isArray!(typeof(Array))){
//    alias ArrayElementType = ArrayElementType!(typeof(Array));
//}
/// ditto
template ArrayElementType(Array) if(isArray!Array){
    alias ArrayElementType = typeof(Array.init[0]);
}



/// Get the element type of a range.
//template RangeElementType(alias Range) if(isRange!(typeof(Range))){
//    alias RangeElementType = RangeElementType!(typeof(Range));
//}
/// ditto
template RangeElementType(Range) if(isRange!Range){
    static if(isCallableWith!(Range.init.front)){
        alias RangeElementType = typeof(Range.init.front());
    }else{
        alias RangeElementType = typeof(Range.init.front);
    }
}



/// Base template for getting the element type of some type implementing opApply
/// or opApplyReverse.
private template OpApplyGenericElementType(Iter, alias op){
    alias ApplyParams = Parameters!op;
    static assert(
        ApplyParams.length == 1 && isDelegate!(ApplyParams[0]),
        fullyQualifiedName!Iter ~ " has invalid arguments for opApply."
    );
    alias Delegate = ApplyParams[0];
    // TODO: What if there's more than one opApply?
    // Probably going to need a more robust Parameters template for that.
    alias DelegateParams = Parameters!Delegate;
    static assert(DelegateParams.length == 1);
    alias OpApplyGenericElementType = DelegateParams[0];
}

/// Get the element type of a type implementing opApply.
//template OpApplyElementType(alias Iter) if(hasOpApply!(typeof(Iter))){
//    alias OpApplyElementType = OpApplyElementType!(typeof(Iter));
//}
/// ditto
template OpApplyElementType(Iter) if(hasOpApply!Iter){
    alias OpApplyElementType = OpApplyGenericElementType!(Iter, Iter.opApply);
}

/// Get the element type of a type implementing opApplyReverse.
//template OpApplyReverseElementType(alias Iter) if(hasOpApplyReverse!(typeof(Iter))){
//    alias OpApplyReverseElementType = OpApplyReverseElementType!(typeof(Iter));
//}
/// ditto
template OpApplyReverseElementType(Iter) if(hasOpApplyReverse!Iter){
    alias OpApplyReverseElementType = OpApplyGenericElementType!(Iter, Iter.opApplyReverse);
}



/// Determine if a type has an Element alias member.
template hasElementAlias(Tx...) if(Tx.length == 1){
    enum bool hasElementAlias = __traits(compiles, {alias E = Iter.Element;});
}



/// Get the element type of some iterable type.
template ElementType(Iter){
    static if(isArray!Iter){
        alias ElementType = ArrayElementType!Iter;
    }else static if(isRange!Iter){
        alias ElementType = RangeElementType!Iter;
    }else static if(hasElementAlias!Iter){
        alias ElementType = Iter.Element;
    }else static if(hasOpApply!Iter){
        alias ElementType = OpApplyElementType!Iter;
    }else static if(hasOpApplyReverse!Iter){
        alias ElementType = OpApplyReverseElementType!Iter;
    }else{
        static assert(
            false, "Unable to determine element type for " ~ fullyQualifiedName!Iter ~ "."
        );
    }
}



template hasCommonElementType(Iters...){
    enum bool hasCommonElementType = hasCommonType!(staticMap!(ElementType, Iters)); 
}

template CommonElementType(Iters...) if(hasCommonElementType!Iters){
    alias CommonElementType = CommonType!(staticMap!(ElementType, Iters));
}



template isIterableOf(Iter, T){
    static if(isIterable!Iter){
        enum bool isIterableOf = is(ElementType!Iter == T);
    }else{
        enum bool isIterableOf = false;
    }
}

template isIterableOf(Iter, alias pred){
    static if(isIterable!Iter){
        enum bool isIterableOf = pred!(ElementType!Iter);
    }else{
        enum bool isIterableOf = false;
    }
}



enum canHashElement(Iter) = canHash!(ElementType!Iter);

enum hasMutableElement(Iter) = isMutable!(ElementType!Iter);

enum isElementPredicate(alias pred, Iters...) = (
    isPredicate!(pred, staticMap!(ElementType, Iters))
);

enum isElementTransformation(alias pred, Iters...) = (
    isTransformation!(pred, staticMap!(ElementType, Iters))
);



version(unittest){
    private:
    struct RangeElementTest{
        int value;
        @property auto front() const{return this.value;}
        void popFront(){this.value++;}
        enum bool empty = false;
    }
    struct ApplyElementTest{
        int opApply(in int delegate(ref string) each){return 0;}
    }
    struct ApplyReverseElementTest{
        int opApplyReverse(in int delegate(ref string) each){return 0;}
    }
}

unittest{
    static assert(is(ArrayElementType!(int[]) == int));
    static assert(is(ArrayElementType!(real[][]) == real[]));
    static assert(is(ArrayElementType!(const int[]) == const int));
    static assert(is(ArrayElementType!(immutable int[]) == immutable int));
}

unittest{
    static assert(is(ElementType!(int[]) == int));
    static assert(is(ElementType!(real[][]) == real[]));
    static assert(is(ElementType!RangeElementTest == const(int)));
    static assert(is(ElementType!ApplyElementTest == string));
    static assert(is(ElementType!ApplyReverseElementTest == string));
}

unittest{
    // Type
    static assert(isIterableOf!(int[], int));
    static assert(isIterableOf!(string, immutable char));
    static assert(!isIterableOf!(int, int));
    // Predicate
    static assert(isIterableOf!(int[][], isArray));
    static assert(!isIterableOf!(int[], isArray));
    static assert(!isIterableOf!(int, isArray));
}

unittest{
    static assert(hasCommonElementType!(int[], real[]));
    static assert(hasCommonElementType!(string[], ApplyElementTest));
    static assert(!hasCommonElementType!(int[], string[]));
    static assert(!hasCommonElementType!(int[], ApplyElementTest));
    static assert(is(CommonElementType!(int[], real[]) == real));
    static assert(is(CommonElementType!(string[], ApplyElementTest) == string));
}

unittest{
    alias even = (n) => (n % 2 == 0);
    alias index = (str) => (str[0] == '?');
    static assert(isElementPredicate!(even, int[]));
    static assert(isElementPredicate!(even, double[]));
    static assert(isElementPredicate!(index, string[]));
    static assert(!isElementPredicate!(even, string[]));
    static assert(!isElementPredicate!(index, int[]));
}
unittest{
    alias twice = (n) => (n + n);
    alias sum = (a, b) => (a + b);
    static assert(isElementTransformation!(twice, int[]));
    static assert(isElementTransformation!(sum, int[], int[]));
    static assert(!isElementTransformation!(sum, int[]));
    static assert(!isElementTransformation!(twice, int[], int[]));
}
