module mach.range.reduction;

private:

import mach.traits : ElementType;
import mach.range.reduce : reduceeager, reducelazy, canReduceEager;

public:



template EagerReductionTemplate(alias func, string initial = ``){
    auto reducefunc(Iter)(in Iter iter) if(canReduceEager!(Iter, func)){
        return reducefunc!(ElementType!Iter, Iter)(iter);
    }
    auto reducefunc(Acc, Iter)(in Iter iter) if(canReduceEager!(Iter, func)){
        static if(initial){
            mixin(`return reduceeager!(func, Acc)(iter, ` ~ initial ~ `);`);
        }else{
            return reduceeager!(func, Acc)(iter);
        }
    }
    alias EagerReductionTemplate = reducefunc;
}



/// Get the sum of all values in an iterable.
alias sum = EagerReductionTemplate!((a, b) => (a + b), `Acc.init`);
/// Get the product of all values in an iterable.
alias product = EagerReductionTemplate!((a, b) => (a * b));



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Summation", {
        testeq([-2, 2].sum, 0);
        testeq([5, 5, 5].sum, 15);
        testeq("Empty series", (new int[0]).sum, 0);
    });
    tests("Product", {
        testeq([2, 2, 2].product, 8);
    });
}
