module mach.range.compare;

private:

import mach.range.asrange : asrange, validAsRange, AsRangeElementType;
import mach.traits : isFiniteIterable, hasNumericLength;

public:



/// Determine whether two iterables can be compared using a predicate.
template canCompareIterables(alias pred, IterA, IterB){
    static if(
        validAsRange!(isFiniteIterable, IterA) &&
        validAsRange!(isFiniteIterable, IterB)
    ){
        enum bool canCompareIterables = is(typeof({
            if(pred(AsRangeElementType!IterA.init, AsRangeElementType!IterB.init)){}
        }));
    }else{
        enum bool canCompareIterables = false;
    }
}

private alias EqualityComparison = (a, b) => (a == b);
private alias RecursiveEqualityComparison = (a, b) => (a.equals(b));

enum canCompareIterablesEquality(IterA, IterB) = (
    canCompareIterables!(EqualityComparison, IterA, IterB)
);
enum canCompareIterablesRecursiveEquality(IterA, IterB) = (
    canCompareIterables!(RecursiveEqualityComparison, IterA, IterB)
);



/// Compares the contents of two iterables until one or both of them has been
/// exhausted using the given predicate. If length is true, then when both
/// iterables have length and their lengths are unequal the function returns
/// false. If exhaust is true, then if one iterable is exhausted before the
/// other then false is returned, even if all of their elements satisfied the
/// predicate. By default, both length and exhaust are true.
bool compare(
    alias pred, bool length = true, bool exhaust = true, IterA, IterB
)(
    auto ref IterA itera, auto ref IterB iterb
) if(canCompareIterables!(pred, IterA, IterB)){
    static if(length && hasNumericLength!IterA && hasNumericLength!IterB){
        if(itera.length != iterb.length) return false;
    }
    auto rangea = itera.asrange;
    auto rangeb = iterb.asrange;
    while(!rangea.empty && !rangeb.empty){
        auto elementa = rangea.front;
        auto elementb = rangeb.front;
        if(!pred(elementa, elementb)) return false;
        rangea.popFront();
        rangeb.popFront();
    }
    static if(exhaust){
        return rangea.empty && rangeb.empty;
    }else{
        return true;
    }
}



/// Determine whether the values in two iterables are equal,
/// optionally ignoring length.
bool equals(bool length = true, bool exhaust = true, IterA, IterB)(
    auto ref IterA itera, auto ref IterB iterb
) if(
    canCompareIterablesEquality!(IterA, IterB) ||
    canCompareIterablesRecursiveEquality!(IterA, IterB)
){
    static if(canCompareIterablesEquality!(IterA, IterB)){
        return iterequals!(length, exhaust, IterA, IterB)(itera, iterb);
    }else{
        return recursiveequals!(length, exhaust, IterA, IterB)(itera, iterb);
    }
}

bool iterequals(bool length = true, bool exhaust = true, IterA, IterB)(
    auto ref IterA itera, auto ref IterB iterb
) if(
    canCompareIterablesEquality!(IterA, IterB)
){
    return compare!(EqualityComparison, length, exhaust, IterA, IterB)(itera, iterb);
}

bool recursiveequals(bool length = true, bool exhaust = true, IterA, IterB)(
    auto ref IterA itera, auto ref IterB iterb
) if(
    canCompareIterablesRecursiveEquality!(IterA, IterB)
){
    return compare!(RecursiveEqualityComparison, length, exhaust, IterA, IterB)(itera, iterb);
}



version(unittest){
    import mach.test;
    private struct TestRange{
        int value, end;
        @property auto front() const{
            return this.value;
        }
        void popFront(){
            this.value++;
        }
        @property bool empty() const{
            return value >= end;
        }
    }
}
unittest{ 
    tests("Equals", {
        tests("Arrays", {
            test([1, 2, 3, 4].equals([1, 2, 3, 4]));
            test([1, 2, 3, 4].equals([1.0, 2.0, 3.0, 4.0]));
            test((new int[0]).equals(new int[0]));
        });
        tests("Differing lengths", {
            testf([1, 2, 3].equals!true([1, 2, 3, 4]));
            test([1, 2, 3].equals!(false, false)([1, 2, 3, 4]));
        });
        tests("Recursive", {
            test(["abc", "xyz"].equals(["abc", "xyz"]));
            test([[0, 1], [2, 3]].equals([[0, 1], [2, 3]]));
        });
        tests("Ranges", {
            test(TestRange(2, 6).equals(TestRange(2, 6)));
            test(TestRange(2, 6).equals([2, 3, 4, 5]));
            test([2, 3, 4, 5].equals(TestRange(2, 6)));
            test([2, 3, 4, 5].asrange.equals(TestRange(2, 6)));
            test(TestRange(2, 6).equals([2, 3, 4, 5].asrange));
        });
    });
}
