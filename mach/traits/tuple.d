module mach.traits.tuple;

private:

import std.traits : TemplateArgsOf;
import std.typecons : Tuple;
import mach.traits.common : hasCommonType, CommonType;
import mach.traits.templates : isTemplateOf;

public:



enum isTuple(T) = isTemplateOf!(T, Tuple);

template hasCommonTupleType(T) if(isTuple!T){
    alias hasCommonTupleType = hasCommonType!(TemplateArgsOf!T);
}

template CommonTupleType(T) if(hasCommonTupleType!T){
    alias CommonTupleType = CommonType!(TemplateArgsOf!T);
}



unittest{
    // isTuple
    static assert(isTuple!(Tuple!int));
    static assert(isTuple!(Tuple!(string, real)));
    static assert(!isTuple!(int));
    static assert(!isTuple!(string));
    // hasCommonTupleType
    static assert(hasCommonTupleType!(Tuple!(int)));
    static assert(hasCommonTupleType!(Tuple!(int, int)));
    static assert(hasCommonTupleType!(Tuple!(int[], int[])));
    static assert(hasCommonTupleType!(Tuple!(int, byte, real)));
    static assert(hasCommonTupleType!(Tuple!(string, string)));
    static assert(!hasCommonTupleType!(Tuple!(string, int)));
    static assert(!hasCommonTupleType!(Tuple!(int[], real[])));
    // CommonTupleType
    static assert(is(CommonTupleType!(Tuple!(int)) == int));
    static assert(is(CommonTupleType!(Tuple!(int, int)) == int));
    static assert(is(CommonTupleType!(Tuple!(int[], int[])) == int[]));
    static assert(is(CommonTupleType!(Tuple!(int, byte, real)) == real));
    static assert(is(CommonTupleType!(Tuple!(string, string)) == string));
}
