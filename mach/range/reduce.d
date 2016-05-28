module mach.range.reduce;

private:

import mach.traits : isFiniteIterable, ElementType;

public:



alias canReduce = isFiniteIterable;



auto reduce(alias func, Acc, Iter)(in Iter iter, in Acc initial) if(canReduce!Iter){
    const(Acc)* acc = &initial;
    foreach(element; iter){
        Acc result = func(*acc, element);
        acc = &result;
    }
    return *acc;
}
auto reduce(alias func, Iter)(in Iter iter) if(canReduce!Iter){
    return reduce!(func, ElementType!Iter, Iter)(iter);
}
auto reduce(alias func, Acc, Iter)(in Iter iter) if(canReduce!Iter){
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



template ReductionTemplate(alias func, string initial = ``){
    auto reducefunc(Iter)(in Iter iter) if(canReduce!Iter){
        return reducefunc!(ElementType!Iter, Iter)(iter);
    }
    auto reducefunc(Acc, Iter)(in Iter iter) if(canReduce!Iter){
        static if(initial){
            mixin(`return reduce!(func, Acc)(iter, ` ~ initial ~ `);`);
        }else{
            return reduce!(func, Acc)(iter);
        }
    }
    alias ReductionTemplate = reducefunc;
}



/// Get the lowest value in an iterable.
alias min = ReductionTemplate!((a, b) => (b < a ? b : a));
/// Get the highest value in an iterable.
alias max = ReductionTemplate!((a, b) => (b > a ? b : a));
/// Get the sum of all values in an iterable.
alias sum = ReductionTemplate!((a, b) => (a + b), `Acc.init`);
/// Get the product of all values in an iterable.
alias product = ReductionTemplate!((a, b) => (a * b));



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
        tests("Empty series", {
            fail({(new int[0]).min;});
            fail({(new int[0]).max;});
        });
        tests("Changing accumulator type", {
            testeq([1, 2].min!real, 1.0);
            testtype!real([1, 2].min!real);
        });
    });
    tests("Summation", {
        testeq([-2, 2].sum, 0);
        testeq([5, 5, 5].sum, 15);
        testeq("Empty series", (new int[0]).sum, 0);
    });
    tests("Product", {
        testeq([2, 2, 2].product, 8);
    });
}
