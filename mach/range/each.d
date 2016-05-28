module mach.range.each;

private:

import mach.range.traits : isFiniteIterable, isFiniteIterableReverse;

public:

void each(alias func, Iter)(Iter iter) if(isFiniteIterable!Iter){
    foreach(item; iter){
        func(item);
    }
}

void each_reverse(alias func, Iter)(Iter iter) if(isFiniteIterableReverse!Iter){
    foreach_reverse(item; iter){
        func(item);
    }
}

unittest{
    // TODO
}
