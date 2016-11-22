module mach.range.sort.issorted;

private:

import mach.traits : ElementType, isFiniteIterable;
import mach.range.asrange : asrange, validAsRange;
import mach.range.next : next;
import mach.range.sort.common : DefaultSortCompare;

public:



template canGetSorted(T){
    enum bool canGetSorted = isFiniteIterable!T && validAsRange!T;
}

template canGetSorted(alias compare, T){
    enum bool canGetSorted = canGetSorted!T && is(typeof({
        if(compare(ElementType!T.init, ElementType!T.init)){}
    }));
}



/// Determine whether the input is sorted according to a given comparison
/// function, such that when the comparison function returns true its first
/// input must precede its second.
bool issorted(alias compare = DefaultSortCompare, T)(auto ref T input) if(
    canGetSorted!(compare, T)
){
    auto range = input.asrange;
    if(range.empty){
        return true;
    }else{
        while(true){
            auto current = range.front;
            range.popFront();
            if(range.empty) return true;
            if(compare(range.front, current)) return false;
        }
    }
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Sorted", {
        {
            test(new int[0].issorted);
            test([0].issorted);
            test([1].issorted);
            test([1, 1].issorted);
            test([1, 1, 1].issorted);
            test([1, 1, 2, 2, 3].issorted);
            test([0, 1, 2, 3, 4].issorted);
            testf([1, 0].issorted);
            testf([0, 2, 1].issorted);
            testf([1, 1, 1, 1, 1, 0].issorted);
            testf([1, 1, 1, 1, 0, 1].issorted);
        }{
            alias cmp = (a, b) => (a > b);
            test(new int[0].issorted!cmp);
            test([0].issorted!cmp);
            test([1].issorted!cmp);
            test([1, 1].issorted!cmp);
            test([1, 1, 1].issorted!cmp);
            test([3, 2, 2, 1, 1].issorted!cmp);
            test([4, 3, 2, 1, 0].issorted!cmp);
            testf([0, 1].issorted!cmp);
            testf([0, 2, 1].issorted!cmp);
            testf([0, 1, 1, 1, 1, 1].issorted!cmp);
            testf([1, 0, 1, 1, 1, 1].issorted!cmp);
        }
    });
}
