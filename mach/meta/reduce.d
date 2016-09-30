module mach.meta.reduce;

private:

import mach.meta.aliases;

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
