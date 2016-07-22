module mach.meta.logical;

private:

//

public:



/// True when any of the types meet a predicate.
template Any(alias predicate, T...){
    static if(T.length == 0){
        enum bool Any = false;
    }else static if(T.length == 1){
        enum bool Any = predicate!(T[0]);
    }else{
        enum bool Any = (
            Any!(predicate, T[0]) ||
            Any!(predicate, T[1 .. $])
        );
    }
}
/// True when all of the types meet a predicate.
template All(alias predicate, T...){
    static if(T.length == 0){
        enum bool All = true;
    }else static if(T.length == 1){
        enum bool All = predicate!(T[0]);
    }else{
        enum bool All = (
            All!(predicate, T[0]) &&
            All!(predicate, T[1 .. $])
        );
    }
}

/// True when none of the types meet a predicate.
enum bool None(alias predicate, T...) = !Any!(predicate, T);

/// Returns the number of types meeting a predicate.
template Count(alias predicate, T...){
    static if(T.length == 0){
        enum size_t Count = 0;
    }else static if(T.length == 1){
        enum size_t Count = predicate!(T[0]) ? 1 : 0;
    }else{
        enum size_t Count = (
            Count!(predicate, T[0]) +
            Count!(predicate, T[1 .. $])
        );
    }
}

/// Returns the first element to meet a predicate.
template First(alias predicate, T...){
    static if(T.length == 0){
        alias First = void;
    }else static if(predicate!(T[0])){
        alias First = T[0];
    }else static if(T.length > 1){
        alias First = First!(predicate, T[1 .. $]);
    }else{
        alias First = void;
    }
}
/// Returns the last element to meet a predicate.
template Last(alias predicate, T...){
    static if(T.length == 0){
        alias Last = void;
    }else static if(predicate!(T[$-1])){
        alias Last = T[$-1];
    }else static if(T.length > 1){
        alias Last = Last!(predicate, T[0 .. $-1]);
    }else{
        alias Last = void;
    }
}



version(unittest){
    private:
    import std.traits : isIntegral;
}
unittest{
    // Any
    static assert(Any!(isIntegral, int, int, float));
    static assert(!Any!(isIntegral, float, float));
    // All
    static assert(All!(isIntegral, int, int));
    static assert(!All!(isIntegral, int, int, float));
    // None
    static assert(None!(isIntegral, float, float));
    // Count
    static assert(Count!(isIntegral, int, float, int) == 2);
    static assert(Count!(isIntegral, int) == 1);
    static assert(Count!(isIntegral, float) == 0);
    // First
    static assert(is(First!(isIntegral, real, double, int, long) == int));
    // Last
    static assert(is(Last!(isIntegral, real, double, int, long) == long));
}


