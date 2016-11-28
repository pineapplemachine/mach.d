module mach.traits.element.type;

private:

import mach.traits.array : isArray;
import mach.traits.associativearray : isAssociativeArray, ArrayValueType;
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
        isArray!T || isAssociativeArray!T || isRange!T ||
        hasElementAlias!T ||
        hasOpApply!T || hasOpApplyReverse!T
    );
}



/// Get the element type of some collection.
template ElementType(T) if(canGetElementType!T){
    static if(isArray!T){
        alias ElementType = ArrayElementType!T;
    }else static if(isAssociativeArray!T){
        alias ElementType = ArrayValueType!T;
    }else static if(isRange!T){
        alias ElementType = RangeElementType!T;
    }else static if(hasElementAlias!T){
        // TODO: Maybe this isn't the greatest idea and should be removed?
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



version(unittest){
    private:
    import mach.meta.aliases : Aliases;
    struct IntRange{
        enum bool empty = false;
        @property int front(){return 0;}
        void popFront(){}
    }
    struct StringRange{
        enum bool empty = false;
        @property string front(){return "";}
        void popFront(){}
    }
    struct IntAlias{
        alias Element = int;
    }
    struct StringAlias{
        alias Element = string;
    }
    struct IntOpApply{
        int opApply(int delegate(ref int)){return 0;}
    }
    struct IntOpApplyRev{
        int opApplyReverse(int delegate(ref int)){return 0;}
    }
}

unittest{
    static assert(canGetElementType!(int[]));
    static assert(canGetElementType!(int[int]));
    static assert(canGetElementType!IntRange);
    static assert(canGetElementType!StringRange);
    static assert(canGetElementType!IntAlias);
    static assert(canGetElementType!StringAlias);
    static assert(canGetElementType!IntOpApply);
    static assert(canGetElementType!IntOpApplyRev);
    static assert(!canGetElementType!int);
    static assert(!canGetElementType!void);
}

unittest{
    {
        foreach(T; Aliases!(
            int[], string[], int[int], int[string], string[int],
            IntRange, StringRange, IntOpApply
        )){
            T test;
            foreach(element; test){
                static assert(is(ElementType!T == typeof(element)));
                break;
            }
        }
    }{
        IntOpApplyRev test;
        foreach_reverse(element; test){
            static assert(is(ElementType!IntOpApplyRev == typeof(element)));
            break;
        }
    }{
        // TODO: Maybe this isn't the greatest idea and should be removed?
        static assert(is(ElementType!IntAlias == int));
        static assert(is(ElementType!StringAlias == string));
    }
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
