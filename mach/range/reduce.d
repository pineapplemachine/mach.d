module mach.range.reduce;

private:

import mach.traits : isFiniteIterable, ElementType;

public:



alias canReduce = isFiniteIterable;

enum canReduce(Iter, alias func) = canReduce!(Iter, ElementType!Iter, func);

template canReduce(Iter, Acc, alias func){
    enum bool canReduce = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        auto element = Element.init;
        auto first = func(Acc.init, element);
        auto second = func(first, element);
        auto third = func(second, element);
    }));
}



auto reduce(alias func, Acc, Iter)(in Iter iter, in Acc initial) if(
    canReduce!(Iter, Acc, func)
){
    const(Acc)* acc = &initial;
    foreach(element; iter){
        Acc result = func(*acc, element);
        acc = &result;
    }
    return *acc;
}
auto reduce(alias func, Iter)(in Iter iter) if(canReduce!(Iter, func)){
    return reduce!(func, ElementType!Iter, Iter)(iter);
}
auto reduce(alias func, Acc, Iter)(in Iter iter) if(canReduce!(Iter, Acc, func)){
    import std.stdio;
    bool first = true;
    const(Acc)* acc;
    foreach(element; iter){
        if(first){
            auto firstelem = cast(Acc) element;
            acc = &firstelem;
            first = false;
        }else{
            Acc result = func(*acc, element);
            acc = &result;
        }
    }
    assert(!first, "Cannot reduce empty range without an initial value.");
    return *acc;
}



version(unittest){
    private:
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
}
