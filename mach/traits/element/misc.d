module mach.traits.element.misc;

private:

import mach.meta : Map;
import mach.traits.element.type : ElementType, hasElementType, canGetElementType;

public:



/// Given a type that contains elements, determine if those elements can be
/// hashed.
template canHashElement(Tx...) if(Tx.length == 1 && canGetElementType!(Tx[0])){
    import mach.traits.hash : canHash;
    enum bool canHashElement = hasElementType!(canHash, Tx[0]);
}

/// Given a type that contains elements, determine whether those elements are
/// mutable.
template hasMutableElement(Tx...) if(Tx.length == 1 && canGetElementType!(Tx[0])){
    import mach.traits.mutability : isMutable;
    enum bool canHashElement = hasElementType!(isMutable, Tx[0]);
}

template isElementPredicate(alias pred, T...){
    import mach.traits.transform : isPredicate;
    enum bool isElementPredicate = isPredicate!(pred, Map!(ElementType, T));
}

template isElementTransformation(alias pred, T...){
    import mach.traits.transform : isTransformation;
    enum bool isElementTransformation = isTransformation!(pred, Map!(ElementType, T));
}



unittest{
    static assert(canHashElement!(string[]));
    static assert(canHashElement!(int[]));
    static assert(!canHashElement!(void[]));
}
