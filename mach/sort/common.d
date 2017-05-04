module mach.sort.common;

private:

import mach.traits : ElementType, canGetElementType;
import mach.traits : hasNumericLength, isFiniteIterable;

public:



/// Default comparison function for sort functions.
alias DefaultSortCompare = (a, b) => (a < b);



template isSortComparison(alias compare, T){
    static if(canGetElementType!T){
        enum bool isSortComparison = is(typeof({
            if(compare(ElementType!T.init, ElementType!T.init)){}
        }));
    }else{
        enum bool isSortComparison = false;
    }
}



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
    enum bool canRandomAccessSort = (
        canRandomAccessSort!T && isSortComparison!(compare, T)
    );
}



/// Determine whether a type has numeric length and random-access reads and writes.
template canBoundedRandomAccessSort(T){
    enum bool canBoundedRandomAccessSort = (
        hasNumericLength!T && canRandomAccessSort!T
    );
}

/// Determine whether a type can be sorted via the given comparison function.
template canBoundedRandomAccessSort(alias compare, T){
    enum bool canBoundedRandomAccessSort = (
        canBoundedRandomAccessSort!T && isSortComparison!(compare, T)
    );
}



version(unittest){
    private:
    import mach.test;
    import mach.range.asrange : asrange;
    import mach.range.compare : equals;
    import mach.sort.issorted : issorted;
    public:
    /// Verify basic sorting test cases.
    void testsort(alias sort)(){
        tests("Empty input", {
            auto empty = new int[0];
            test!equals(sort(empty), empty);
            test!equals(sort([1]), [1]);
        });
        tests("Numbers", {
            test!equals(sort([1, 2]), [1, 2]);
            test!equals(sort([2, 1]), [1, 2]);
            test!equals(sort([1, 2, 3, 4]), [1, 2, 3, 4]);
            test!equals(sort([4, 2, 3, 1]), [1, 2, 3, 4]);
            test!equals(sort([4, 1, 3, 2]), [1, 2, 3, 4]);
            test!equals(sort([1, 1, 2, 1, 3, 2]), [1, 1, 1, 2, 2, 3]);
        });
        tests("Large input", {
            int[] a, b;
            foreach(i; 0 .. 51){
                immutable n = (i * 9431) % 53;
                a ~= n; b ~= n;
            }
            alias asc = (a, b) => (a < b);
            alias desc = (a, b) => (a > b);
            auto asorted = sort!asc(a);
            auto bsorted = sort!desc(b);
            test(asorted.issorted!asc);
            test(bsorted.issorted!desc);
        });
        tests("Range input", {
            auto range = [4, 2, 1, 3].asrange;
            test!equals(sort(range), [1, 2, 3, 4]);
        });
    }
    /// Verify behavior of sorts expected to be stable.
    void teststablesort(alias sort)(){
        tests("Stability", {
            struct Test{string data;}
            alias cmp = (a, b) => (a.data.length < b.data.length);
            test!equals(
                sort!cmp([Test("a"), Test("b"), Test("c")]),
                [Test("a"), Test("b"), Test("c")]
            );
            test!equals(
                sort!cmp([Test("xyz"), Test("y"), Test("z"), Test("ab"), Test("qqq")]),
                [Test("y"), Test("z"), Test("ab"), Test("xyz"), Test("qqq")]
            );
        });
    }
    /// Verify behavior of sorts expected not to modify their inputs.
    void testcopysort(alias sort)(){
        tests("Non-mutating", {
            auto i = [3, 1, 2];
            test!equals(sort(i), [1, 2, 3]);
            testeq(i, [3, 1, 2]);
        });
    }
}
