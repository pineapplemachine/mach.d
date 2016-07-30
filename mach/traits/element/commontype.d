module mach.traits.element.commontype;

private:

import mach.meta : Map, All;
import mach.traits.element.type : canGetElementType, ElementType;

public:



/// Determine whether the given types share a common element type.
template hasCommonElementType(T...) if(All!(canGetElementType, T)){
    import mach.traits.common : hasCommonType;
    enum bool hasCommonElementType = hasCommonType!(Map!(ElementType, T)); 
}

/// Get the common element type of the given types.
template CommonElementType(T...) if(hasCommonElementType!T){
    import mach.traits.common : CommonType;
    alias CommonElementType = CommonType!(Map!(ElementType, T));
}



unittest{
    static assert(hasCommonElementType!(int[], real[]));
    static assert(!hasCommonElementType!(int[], string[]));
    static assert(is(CommonElementType!(int[], real[]) == real));
}
unittest{
    class Base{}
    class A: Base{}
    class B: Base{}
    static assert(hasCommonElementType!(A[], B[]));
    static assert(hasCommonElementType!(A[], B[], Base[]));
    static assert(!hasCommonElementType!(A[], int[]));
    static assert(is(CommonElementType!(A[], B[]) == Base));
    static assert(is(CommonElementType!(A[], B[], Base[]) == Base));
}
