module mach.meta.filter;

private:

import mach.meta.aliases : Aliases;

/++ Docs: mach.meta.filter

Given a sequence of values, `Filter` generates a new sequence containing
only those values which meet a predicate.

The first template argument must be a predicate,
and subsequent arguments constitute the sequence to be filtered.

+/

unittest{ /// Example
    enum bool NotVoid(T) = !is(T == void);
    static assert(is(Filter!(NotVoid, void, int, void, long) == Aliases!(int, long)));
}

unittest{ /// Example
    enum bool isInt(T) = is(T == int);
    static assert(is(Filter!(isInt, double, float, long) == Aliases!()));
}

public:



template Filter(alias predicate, T...){
    static if(T.length == 0){
        alias Filter = Aliases!();
    }else static if(T.length == 1){
        static if(predicate!(T[0])) alias Filter = T;
        else alias Filter = Aliases!();
    }else{
        alias Filter = Aliases!(
            Filter!(predicate, T[0]),
            Filter!(predicate, T[1 .. $])
        );
    }
}



version(unittest){
    private:
    import mach.traits.primitives : isFloatingPoint, isIntegral;
}
unittest{
    static assert(is(
        Filter!(isFloatingPoint, int, float, long, double) == Aliases!(float, double)
    ));
    static assert(is(
        Filter!(isIntegral, int, float, long, double) == Aliases!(int, long)
    ));
}
