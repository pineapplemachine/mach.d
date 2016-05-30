module mach.range.compare;

private:

import mach.range.asrange : asrange, validAsRange;
import mach.traits : ElementType, isFiniteIterable, isFiniteRange, canCompare;

public:



enum canCompareIterables(alias pred, IterA, IterB) = (
    validAsRange!IterA && validAsRange!IterB &&
    isFiniteIterable!IterA && isFiniteIterable!IterB &&
    is(typeof(pred(ElementType!IterA.init, ElementType!IterB.init)))
);

private alias EqualityComparison = (a, b) => (a == b);

enum canCompareIterablesEquality(IterA, IterB) = (
    canCompareIterables!(EqualityComparison, IterA, IterB)
);



bool compare(
    alias pred, bool length = true, IterA, IterB
)(
    IterA itera, IterB iterb
) if(canCompareIterables!(pred, IterA, IterB)){
    auto rangea = itera.asrange;
    auto rangeb = iterb.asrange;
    while(!rangea.empty && !rangeb.empty){
        auto elementa = rangea.front;
        auto elementb = rangeb.front;
        if(!pred(elementa, elementb)) return false;
        rangea.popFront();
        rangeb.popFront();
    }
    static if(length){
        return rangea.empty && rangeb.empty;
    }else{
        return true;
    }
}



/// Determine whether the values in two iterables are equal,
/// optionally ignoring length.
bool equals(bool length = true, IterA, IterB)(
    IterA itera, IterB iterb
) if(canCompareIterablesEquality!(IterA, IterB)){
    return compare!(EqualityComparison, length, IterA, IterB)(itera, iterb);
}



version(unittest){
    import mach.error.unit;
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
            test("Same type", [1, 2, 3, 4].equals([1, 2, 3, 4]));
            test("Different types", [1, 2, 3, 4].equals([1.0, 2.0, 3.0, 4.0]));
            test("Empty", (new int[0]).equals(new int[0]));
        });
        tests("Differing lengths", {
            testf([1, 2, 3].equals!true([1, 2, 3, 4]));
            test([1, 2, 3].equals!false([1, 2, 3, 4]));
        });
        tests("Ranges", {
            test(TestRange(2, 6).equals(TestRange(2, 6)));
            test(TestRange(2, 6).equals([2, 3, 4, 5]));
            test([2, 3, 4, 5].equals(TestRange(2, 6)));
        });
    });
}
