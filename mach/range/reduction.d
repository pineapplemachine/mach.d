module mach.range.reduction;

private:

import mach.traits : ElementType;
import mach.range.reduce : reduceeager, reducelazy, canReduceEager;

public:



template EagerReductionTemplate(alias func, string initial = ``){
    auto reducefunc(Iter)(Iter iter) if(canReduceEager!(Iter, func)){
        return reducefunc!(ElementType!Iter, Iter)(iter);
    }
    auto reducefunc(Acc, Iter)(Iter iter) if(canReduceEager!(Iter, func)){
        static if(initial){
            mixin(`return reduceeager!(func, Acc)(iter, ` ~ initial ~ `);`);
        }else{
            return reduceeager!(func, Acc)(iter);
        }
    }
    alias EagerReductionTemplate = reducefunc;
}



/// Get the sum of all values in an iterable.
alias sum = EagerReductionTemplate!((a, b) => (a + b), `0`);
/// Get the product of all values in an iterable.
alias product = EagerReductionTemplate!((a, b) => (a * b));



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Summation", {
        testeq([-2, 2].sum, 0);
        testeq([5, 5, 5].sum, 15);
        testeq([1.0, 2.0].sum, 3.0);
        testeq((new int[0]).sum, 0);
    });
    tests("Product", {
        testeq([2, 2, 2].product, 8);
    });
}
