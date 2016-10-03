module mach.range.chain.simple;

private:

import mach.traits : isTemplateOf;
import mach.range.chain.singular;
import mach.range.chain.plural;

public:



enum canChain(Iter) = (
    canChainIterables!Iter ||
    canChainIterableOfIterables!Iter
);



auto ref chain(Iters...)(auto ref Iters iters) if(
    Iters.length > 1 && canChainIterables!Iters
){
    return chainiters(iters);
}

auto ref chain(Iters...)(auto ref Iters iters) if(
    Iters.length == 1 && canChain!(Iters[0])
){
    static if(canChainIterableOfIterables!(Iters[0])){
        return chainiter(iters[0]);
    }else{
        return chainiters(iters);
    }
}



unittest{
    static assert(isTemplateOf!(
        typeof(chain(new int[0])), ChainRange
    ));
    static assert(isTemplateOf!(
        typeof(chain(new int[0], new int[0])), ChainRange
    ));
    static assert(isTemplateOf!(
        typeof(chain(new int[][0])), ChainRandomAccessIterablesRange
    ));
}
