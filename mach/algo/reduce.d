module mach.algo.reduce;

private:

import std.traits : isIterable, isSomeFunction;
import std.range.primitives : ElementType;

public:

auto reduce(alias func, Acc, Iter)(in Iter iter, in Acc initial) if(isIterable!Iter){
    const(Acc)* acc = &initial;
    foreach(element; iter){
        Acc result = func(*acc, element);
        acc = &result;
    }
    return *acc;
}
auto reduce(alias func, Iter)(in Iter iter) if(isIterable!Iter){
    import std.stdio;
    bool first = true;
    alias Acc = ElementType!Iter;
    const(Acc)* acc;
    foreach(element; iter){
        if(first){
            auto firstelem = element;
            acc = &firstelem;
            first = false;
        }else{
            Acc result = func(*acc, element);
            acc = &result;
        }
    }
    assert(!first, "Cannot reduce an empty range without an initial value.");
    return *acc;
}



auto min(Iter)(in Iter iter) if(isIterable!Iter){
    return iter.reduce!((a, b) => (b < a ? b : a));
}
auto max(Iter)(in Iter iter) if(isIterable!Iter){
    return iter.reduce!((a, b) => (b > a ? b : a));
}
auto sum(Iter)(in Iter iter) if(isIterable!Iter){
    return iter.reduce!((a, b) => (a + b))(ElementType!Iter.init);
}



version(unittest){
    import mach.error.unit;
    import std.conv : to;
}
unittest{
    tests("Reduce", {
        auto arr = [1, 2, 3, 4];
        testeq(
            "No seed", arr.reduce!((acc, next) => (acc + next)), 10
        );
        testeq(
            "With seed", arr.reduce!((acc, next) => (acc + next))(2), 12
        );
        testeq(
            "Disparate types",
            arr.reduce!((acc, next) => (to!string(acc) ~ to!string(next)))(""),
            "1234"
        );
    });
    tests("Comparison", {
        testeq([0, 1, 2].min, 0);
        testeq([2, 1, 0].min, 0);
        testeq([0, 1, -1].min, -1);
        testeq([0, 1, 2].max, 2);
        testeq([2, 1, 0].max, 2);
        testeq([0, 1, -1].max, 1);
        fail({(new int[0]).min;});
        fail({(new int[0]).max;});
    });
    tests("Summation", {
        testeq([-2, 2].sum, 0);
        testeq([5, 5, 5].sum, 15);
        testeq("Sum of empty series", (new int[0]).sum, 0);
    });
}
