module mach.range.sort.common;

private:

import mach.traits : ElementType, hasNumericLength, isFiniteIterable;

public:



/// Default comparison function for sort functions.
alias DefaultSortCompare = (a, b) => (a < b);



/// Determine whether a type has random-access reads and writes.
template canRandomAccessSort(T){
    enum bool canRandomAccessSort = is(typeof({
        auto t = T.init;
        size_t i = 0;
        t[i] = t[i];
    }));
}

/// Determine whether a type can be sorted via the given comparison function.
template canRandomAccessSort(alias compare, T){
    static if(canRandomAccessSort!T){
        enum bool canRandomAccessSort = is(typeof({
            if(compare(ElementType!T.init, ElementType!T.init)){}
        }));
    }else{
        enum bool canRandomAccessSort = false;
    }
}



/// Determine whether a type has numeric length and random-access reads and writes.
template canBoundedRandomAccessSort(T){
    enum bool canBoundedRandomAccessSort = (
        hasNumericLength!T && canRandomAccessSort!T
    );
}

/// Determine whether a type can be sorted via the given comparison function.
template canBoundedRandomAccessSort(alias compare, T){
    static if(canBoundedRandomAccessSort!T){
        enum bool canBoundedRandomAccessSort = is(typeof({
            if(compare(ElementType!T.init, ElementType!T.init)){}
        }));
    }else{
        enum bool canBoundedRandomAccessSort = false;
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.asrange : asrange;
    import mach.range.sort.issorted : issorted;
    public:
    void testsort(alias sort)(){
        tests("Empty input", {
            auto empty = new int[0];
            testeq(sort(empty), empty);
            testeq(sort([1]), [1]);
        });
        tests("Numbers", {
            testeq(sort([1, 2]), [1, 2]);
            testeq(sort([2, 1]), [1, 2]);
            testeq(sort([1, 2, 3, 4]), [1, 2, 3, 4]);
            testeq(sort([4, 2, 3, 1]), [1, 2, 3, 4]);
            testeq(sort([4, 1, 3, 2]), [1, 2, 3, 4]);
            testeq(sort([1, 1, 2, 1, 3, 2]), [1, 1, 1, 2, 2, 3]);
        });
        tests("Large input", {
            int[] a, b;
            foreach(i; 0 .. 101){
                immutable n = (i * 9431) % 53;
                a ~= n; b ~= n;
            }
            alias asc = (a, b) => (a < b);
            alias desc = (a, b) => (a > b);
            test(sort!asc(a).issorted!asc);
            test(sort!desc(b).issorted!desc);
        });
        tests("Range input", {
            auto range = [4, 2, 1, 3].asrange;
            testeq(sort(range), [1, 2, 3, 4]);
        });
    }
    void teststablesort(alias sort)(){
        tests("Stability", {
            struct Test{string data;}
            alias cmp = (a, b) => (a.data.length < b.data.length);
            testeq(
                sort!cmp([Test("a"), Test("b"), Test("c")]),
                [Test("a"), Test("b"), Test("c")]
            );
            testeq(
                sort!cmp([Test("xyz"), Test("y"), Test("z"), Test("ab"), Test("qqq")]),
                [Test("y"), Test("z"), Test("ab"), Test("xyz"), Test("qqq")]
            );
        });
    }
}
