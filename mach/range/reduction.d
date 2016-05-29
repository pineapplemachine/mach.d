module mach.range.reduction;

private:

import mach.traits : ElementType;
import mach.range.reduce : reduce, canReduce;

public:



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
    private:
    import mach.error.unit;
}
unittest{
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

