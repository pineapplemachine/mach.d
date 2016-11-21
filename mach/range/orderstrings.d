module mach.range.orderstrings;

private:

import mach.traits : ElementType;
import mach.range.asrange : asrange, validAsRange;

public:



/// Analog to alphabetical sorting. Whichever input has the first
/// lower element is considered to precede the other.
/// Returns +1 when A follows B.
/// Returns -1 when A precedes B.
/// Returns 0 when A and B are equivalent.
int orderstrings(A, B)(in A a, in B b) if(
    validAsRange!A && validAsRange!B && is(typeof({
        auto a = ElementType!A.init;
        auto b = ElementType!B.init;
        if(a > b){}
        if(a < b){}
    }))
){
    auto arange = a.asrange;
    auto brange = b.asrange;
    while(!arange.empty && !brange.empty){
        if(arange.front > brange.front) return 1;
        else if(arange.front < brange.front) return -1;
        arange.popFront();
        brange.popFront();
    }
    if(arange.empty){
        return brange.empty ? 0 : -1;
    }else{ // implies brange.empty
        return 1;
    }
}



version(unittest){
    private:
    import mach.test;
    void testorder(A, B)(int expected, A a, B b){
        testeq(orderstrings(a, b), expected);
        testeq(orderstrings(b, a), -expected);
    }
}
unittest{
    tests("Ordering", {
        testorder(0, "", "");
        testorder(0, new int[0], new int[0]);
        testorder(0, new int[0], new long[0]);
        testorder(1, "a", "");
        testorder(1, "x", "");
        testorder(1, "abc", "");
        testorder(1, "abc", "a");
        testorder(1, "x", "a");
    });
}
