module mach.traits.pointer;

private:

import mach.traits.primitives : isPointer;

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



version(unittest){
    private:
    import mach.meta.aliases : Aliases;
    import mach.traits.primitives : isBoolean, isIntegral;
}

unittest{
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

unittest{
    static assert(isPointer!(const(int*)));
    static assert(isPointer!(const(void*)));
}

unittest{
    static assert(isPointer!(isBoolean, bool*));
    static assert(isPointer!(isIntegral, int*));
    static assert(isPointer!(isIntegral, long*));
    static assert(isPointer!(isPointer, int**));
    static assert(!isPointer!(isIntegral, void));
    static assert(!isPointer!(isIntegral, int));
    static assert(!isPointer!(isIntegral, float*));
}
