module mach.range.flatten;

private:

import mach.traits : ElementType;
import mach.range.asrange : validAsRange;
import mach.range.chain : chainiter, canChainIterableOfIterables;
import mach.range.map : map;

public:



template canFlatten(Iter){
    static if(canChainIterableOfIterables!Iter){
        enum bool canFlatten = (
            validAsRange!Iter ||
            !canChainIterableOfIterables!(ElementType!Iter)
        );
    }else{
        enum bool canFlatten = false;
    }
}



/// Given an iterable of iterables (possibly of iterables (possibly of iterables))
/// construct a range that iterates only through the atomic elements of each.
auto ref flatten(Iter)(auto ref Iter iter) if(canFlatten!Iter){
    static if(canChainIterableOfIterables!(ElementType!Iter)){
        return flatten(iter.map!(e => e.flatten));
    }else{
        return chainiter(iter);
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Flatten", {
        int[][][] input = [[[1, 2], [3, 4]], [[5, 6], [7, 8]]];
        auto range = input.flatten;
        testeq(range.length, 8);
        test(range.equals([1, 2, 3, 4, 5, 6, 7, 8]));
    });
}
