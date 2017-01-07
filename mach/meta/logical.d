module mach.meta.logical;

private:

/++ Docs: mach.meta.logical

The `Any`, `All`, and `None` templates evaluate whether a predicate,
described by the first template argument, evaluates true for any of the
subsequent template arguments.

+/

unittest{ /// Example
    enum isInt(T) = is(T == int);
    static assert(Any!(isInt, void, int));
    static assert(!Any!(isInt, void, void));
}

unittest{ /// Example
    enum isLong(T) = is(T == long);
    static assert(All!(isLong, long, long));
    static assert(!All!(isLong, long, void));
}

unittest{ /// Example
    enum isDouble(T) = is(T == double);
    static assert(None!(isDouble, void, void));
    static assert(!None!(isDouble, void, double));
}

/++ Docs: mach.meta.logical

The `First` and `Last` templates can be used to find the first or the last
item in their template arguments matching a predicate, respectively.
The first argument represents the predicate, and subsequent arguments
represent the sequence to be searched in.

These templates produce compile errors when the sequence contains no value
meeting the predicate.

+/

unittest{ /// Example
    enum isNum(T) = is(T == int) || is(T == long);
    static assert(is(First!(isNum, void, int, long) == int));
    static assert(is(Last!(isNum, void, int, long) == long));
}

unittest{ /// Example
    enum isNum(T) = is(T == int) || is(T == long);
    static assert(!is(typeof({
        // Fails to compile because no arguments satisfy the predicate.
        alias T = First!(isNum, void, void, void);
    })));
}

/++ Docs: mach.meta.logical

The `Count` template determines the number of elements meeting a predicate.
The first argument represents the predicate, and subsequent arguments
represent the sequence to be searched in.

+/

unittest{ /// Example
    enum isChar(T) = is(T == char);
    static assert(Count!(isChar, char, void, char) == 2);
    static assert(Count!(isChar, void) == 0);
}

public:



/// True when any of the inputs meet a predicate.
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
/// True when all of the inputs meet a predicate.
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

/// True when none of the inputs meet a predicate.
enum bool None(alias predicate, T...) = !Any!(predicate, T);



/// Returns the number of inputs meeting a predicate.
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
        static assert(false, "Found no elements matching the predicate.");
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
        static assert(false, "Found no elements matching the predicate.");
    }
}



version(unittest){
    private:
    import mach.traits.primitives : isIntegral;
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


