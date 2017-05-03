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



/// Get the product of all values in an iterable.
/// TODO: Reimplement in mach.math package like with sum
alias product = EagerReductionTemplate!((a, b) => (a * b));



private version(unittest){
    import mach.test;
}
unittest{
    tests("Product", {
        testeq([2, 2, 2].product, 8);
    });
}
