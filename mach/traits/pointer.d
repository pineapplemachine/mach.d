module mach.traits.pointer;

private:

import mach.traits.primitives : isPointer;

/++ Docs

The `PointerType` template accepts a pointer type as input and aliases to
the type that the pointer refers to.

It also provides an overload of the `isPointer` template which can be used
to determine whether a pointer refers to a type satisfying some predicate
template.

+/

unittest{ /// Example
    static assert(is(PointerType!(int*) == int));
    static assert(is(PointerType!(string**) == string*));
}

unittest{ /// Example
    import mach.traits.primitives : isIntegral, isFloatingPoint;
    static assert(isPointer!(isIntegral, int*));
    static assert(isPointer!(isFloatingPoint, float*));
}

public:



/// Get the type of the value that a pointer refers to.
template PointerType(T : T*){
    alias PointerType = T;
}

/// Get whether a type is a pointer, pointing to a value of a type which
/// meets a template predicate.
template isPointer(alias pred, T){
    static if(isPointer!T){
        enum bool isPointer = pred!(PointerType!T);
    }else{
        enum bool isPointer = false;
    }
}



private version(unittest){
    import mach.meta.aliases : Aliases;
    import mach.traits.primitives : isBoolean, isIntegral;
}

unittest{ /// PointerType
    struct Struct{int x;}
    class Class{int x;}
    foreach(T; Aliases!(
        void, void*,
        int, int*, int**, int[], int[4],
        const(int), uint, long, float,
        Struct, Struct*, Class, Class*
    )){
        static assert(is(PointerType!(T*) == T));
        static if(!isPointer!T){
            static assert(!is(typeof({alias x = PointerType!T;})));
        }
    }
}

unittest{ /// isPointer with type
    static assert(isPointer!(const(int*)));
    static assert(isPointer!(const(void*)));
}
unittest{ /// isPointer with type and predicate
    static assert(isPointer!(isBoolean, bool*));
    static assert(isPointer!(isIntegral, int*));
    static assert(isPointer!(isIntegral, long*));
    static assert(isPointer!(isPointer, int**));
    static assert(!isPointer!(isIntegral, void));
    static assert(!isPointer!(isIntegral, int));
    static assert(!isPointer!(isIntegral, float*));
}
