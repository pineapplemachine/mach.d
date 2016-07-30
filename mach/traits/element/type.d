module mach.traits.element.type;

private:

import mach.traits.array : isArray;
import mach.traits.op : hasOpApply, hasOpApplyReverse;
import mach.traits.range : isRange;
import mach.traits.element.array;
import mach.traits.element.ealias;
import mach.traits.element.opapply;
import mach.traits.element.range;

public:



/// Determine whether getting ElementType of some type is a meaningful operation.
template canGetElementType(Tx...) if(Tx.length == 1){
    alias T = Tx[0];
    enum bool canGetElementType = (
        isArray!T || isRange!T ||
        hasElementAlias!T ||
        hasOpApply!T || hasOpApplyReverse!T
    );
}



/// Get the element type of some collection.
template ElementType(alias T) if(canGetElementType!T){
    alias ElementType = ElementType!(typeof(T));
}
/// ditto
template ElementType(T) if(canGetElementType!T){
    static if(isArray!T){
        alias ElementType = ArrayElementType!T;
    }else static if(isRange!T){
        alias ElementType = RangeElementType!T;
    }else static if(hasElementAlias!T){
        alias ElementType = T.Element;
    }else static if(hasOpApply!T){
        alias ElementType = OpApplyElementType!T;
    }else static if(hasOpApplyReverse!T){
        alias ElementType = OpApplyReverseElementType!T;
    }else{
        // This shouldn't happen
        static assert("Failed to determine element type for " ~ T.stringof);
    }
}



// TODO: Move to a more appropriate location
template isTemplatePredicate(alias pred, Tx...) if(Tx.length == 1){
    enum bool isTemplatePredicate = __traits(compiles, {
        enum bool R = pred!(Tx[0]);
    });
}



/// Determine whether some collection contains elements of a given type.
template hasElementType(Element, Tx...) if(Tx.length == 1){
    static if(canGetElementType!(Tx[0])){
        enum bool hasElementType = is(ElementType!(Tx[0]) == Element);
    }else{
        enum bool hasElementType = false;
    }
}

/// Determine whether some collection contains elements of a type matching the
/// given template predicate.
template hasElementType(alias pred, Tx...) if(Tx.length == 1){
    static if(canGetElementType!(Tx[0])){
        enum bool hasElementType = pred!(ElementType!(Tx[0]));
    }else{
        enum bool hasElementType = false;
    }
}



unittest{
    struct Range{enum bool empty = false; @property int front(){return 0;} void popFront();}
    struct EAlias{alias Element = int;}
    struct OpApply{int opApply(int delegate(ref int)){return 0;}}
    struct OpApplyRev{int opApplyReverse(int delegate(ref int)){return 0;}}
    Range range;
    EAlias ealias;
    OpApply apply;
    OpApplyRev applyrev;
    static assert(canGetElementType!range);
    static assert(canGetElementType!Range);
    static assert(canGetElementType!(int[]));
    static assert(!canGetElementType!int);
    static assert(!canGetElementType!void);
    static assert(is(ElementType!(int[]) == int));
    static assert(is(ElementType!(int[][]) == int[]));
    static assert(is(ElementType!range == int));
    static assert(is(ElementType!Range == int));
    static assert(is(ElementType!ealias == int));
    static assert(is(ElementType!EAlias == int));
    static assert(is(ElementType!apply == int));
    static assert(is(ElementType!OpApply == int));
    static assert(is(ElementType!applyrev == int));
    static assert(is(ElementType!OpApplyRev == int));
}

unittest{
    int[] ints;
    static assert(hasElementType!(int, ints));
    static assert(hasElementType!(int, int[]));
    static assert(hasElementType!(int[], int[][]));
    static assert(!hasElementType!(string, int[]));
    static assert(!hasElementType!(int, int));
}
unittest{
    enum bool isInt(T) = is(T == int);
    int[] ints;
    static assert(hasElementType!(isInt, ints));
    static assert(hasElementType!(isInt, int[]));
    static assert(!hasElementType!(isInt, string));
    static assert(!hasElementType!(isInt, int));
}
