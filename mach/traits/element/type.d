module mach.traits.element.type;

private:

import mach.traits.array : isArray;
import mach.traits.op : hasOpApply, hasOpApplyReverse;
import mach.traits.qualifiers : Unqual;
import mach.traits.range : isRange;
import mach.traits.element.array;
import mach.traits.element.ealias;
import mach.traits.element.opapply;
import mach.traits.element.range;

public:



/// Determine whether getting ElementType of some type is a meaningful operation.
template canGetElementType(T){
    enum bool canGetElementType = (
        isArray!T || isRange!T ||
        hasElementAlias!T ||
        hasOpApply!T || hasOpApplyReverse!T
    );
}



/// Get the element type of some collection.
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



/// Determine whether some collection contains elements of a given type.
template hasElementType(E, T){
    static if(canGetElementType!T){
        // This oddness is to get around a couple of caveats:
        // 1. `typeof({E x = ElementType!T.init;})` won't work for
        //    cases e.g. `byte x = short.init`
        // 2. `ElementType!T x; E y = x;` won't work for types thet disable
        //    blitting.
        // But this implementation seems to work fine.
        enum bool hasElementType = is(typeof(
            (ElementType!T x){E y = x;}(ElementType!T.init)
        ));
    }else{
        enum bool hasElementType = false;
    }
}

/// Determine whether some collection contains elements of a type matching the
/// given template predicate.
template hasElementType(alias pred, T){
    static if(canGetElementType!T){
        enum bool hasElementType = pred!(ElementType!T);
    }else{
        enum bool hasElementType = false;
    }
}



unittest{
    struct Range{enum bool empty = false; @property int front(){return 0;} void popFront();}
    struct EAlias{alias Element = int;}
    struct OpApply{int opApply(int delegate(ref int)){return 0;}}
    struct OpApplyRev{int opApplyReverse(int delegate(ref int)){return 0;}}
    static assert(canGetElementType!Range);
    static assert(canGetElementType!(int[]));
    static assert(!canGetElementType!int);
    static assert(!canGetElementType!void);
    static assert(is(ElementType!(int[]) == int));
    static assert(is(ElementType!(int[][]) == int[]));
    static assert(is(ElementType!Range == int));
    static assert(is(ElementType!EAlias == int));
    static assert(is(ElementType!OpApply == int));
    static assert(is(ElementType!OpApplyRev == int));
}

unittest{
    static assert(hasElementType!(int, int[]));
    static assert(hasElementType!(int[], int[][]));
    static assert(hasElementType!(const int, const(int)[]));
    static assert(hasElementType!(const int, int[]));
    static assert(hasElementType!(int, const int[]));
    static assert(!hasElementType!(string, int[]));
    static assert(!hasElementType!(int, int));
    static assert(!hasElementType!(byte, short[]));
    static assert(!hasElementType!(byte, int[]));
    static assert(!hasElementType!(short, int[]));
    static assert(!hasElementType!(char, wchar[]));
    static assert(!hasElementType!(char, dchar[]));
    static assert(!hasElementType!(wchar, dchar[]));
}
unittest{
    enum bool isInt(T) = is(T == int);
    static assert(hasElementType!(isInt, int[]));
    static assert(!hasElementType!(isInt, string));
    static assert(!hasElementType!(isInt, int));
}
