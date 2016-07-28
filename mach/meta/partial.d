module mach.meta.partial;

private:

import mach.meta.aliases : Alias;

public:



private template PartialFrontImpl(alias target, alias Args, T...){
    alias PartialFrontImpl = Alias!(target!(Args, T));
}
template PartialFront(alias target, Args...){
    template PartialFront(T...){
        alias PartialFront = Alias!(target!(Args, T));
    }
}

template PartialBack(alias target, Args...){
    template PartialBack(T...){
        alias PartialBack = Alias!(target!(T, Args));
    }
}

alias Partial = PartialFront;



version(unittest){
    private:
    enum bool Same(A, B, C) = is(A == B) && is(B == C);
}
unittest{
    // TODO: More tests
    alias TestPartial = Partial!(Same, int);
    static assert(TestPartial!(int, int));
    static assert(!TestPartial!(int, float));
}
