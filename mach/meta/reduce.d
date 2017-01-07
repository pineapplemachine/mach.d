module mach.meta.reduce;

private:

import mach.meta.aliases;

/++ Docs: mach.meta.reduce

Provides an implementation of the
[reduce higher-order function](https://en.wikipedia.org/wiki/Fold_(higher-order_function)),
operating upon a sequence of template arguments.

The first argument of the `Reduce` template is an accumulation function,
and it is applied sequentially to the following template arguments.

+/

unittest{ /// Example
    enum sum(alias a, alias b) = a + b;
    static assert(Reduce!(sum, 1, 2, 3, 4) == 10);
}

unittest{ /// Example
    enum max(alias a, alias b) = a > b ? a : b;
    static assert(Reduce!(max, 0, 1, 7, 3) == 7);
}

unittest{ /// Example
    template larger(a, b){
        static if(a.sizeof > b.sizeof) alias larger = a;
        else alias larger = b;
    }
    static assert(is(Reduce!(larger, short, byte, long, int) == long));
}

public:



/// Given a reduction function and a sequence of types at least one type long,
/// perform a reduce higher-order function over the input sequence.
template Reduce(alias func, T...) if(T.length){
    static if(T.length == 1){
        alias Reduce = Alias!(T[0]);
    }else static if(T.length == 2){
        alias Reduce = func!(T[0], T[1]);
    }else{
        alias Reduce = Reduce!(
            func, func!(T[0], T[1]), T[2 .. $]
        );
    }
}



version(unittest){
    template first(a, b){
        alias first = a;
    }
    template sum(alias a, alias b){
        enum sum = a + b;
    }
}
unittest{
    static assert(is(Reduce!(first, void) == void));
    static assert(is(Reduce!(first, int) == int));
    static assert(is(Reduce!(first, int, void) == int));
    static assert(is(Reduce!(first, void, int, int, void) == void));
    static assert(Reduce!(sum, 0) == 0);
    static assert(Reduce!(sum, 0, 1) == 1);
    static assert(Reduce!(sum, 1, 2, 3) == 6);
}
