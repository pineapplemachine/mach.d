module mach.algo.each;

private:

import std.traits : isIterable;
import mach.algo.traits : isIterableReverse;

public:

void each(alias func, Iter)(Iter iter) if(isIterable!Iter){
    foreach(item; iter){
        func(item);
    }
}

void each_reverse(alias func, Iter)(Iter iter) if(isIterableReverse!Iter){
    foreach_reverse(item; iter){
        func(item);
    }
}

unittest{
    // TODO
}
