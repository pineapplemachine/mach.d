module mach.range.compareends;

private:

import mach.traits : hasNumericLength, LengthType;
import mach.range.ends : head, tail, canGetHead, canGetTail;
import mach.range.compare : compare, canCompareIterables;
import mach.range.asrange : validAsRange;

public:



alias DefaultCompareEnds = (a, b) => (a == b);



/// Determine whether the head of Iter be compared to Sub using the given predicate.
template canCompareHead(Iter, Sub, alias pred = DefaultCompareEnds){
    static if(validAsRange!Iter && validAsRange!Sub && hasNumericLength!Sub){
        enum bool canCompareHead = (
            canGetHead!(Iter) &&
            canCompareIterables!(pred, typeof(Iter.init.head(0)), Sub)
        );
    }else{
        enum bool canCompareHead = false;
    }
}

/// Determine whether the tail of Iter be compared to Sub using the given predicate.
template canCompareTail(Iter, Sub, alias pred = DefaultCompareEnds){
    static if(validAsRange!Iter && validAsRange!Sub && hasNumericLength!Sub){
        enum bool canCompareTail = (
            canGetTail!(Iter) &&
            canCompareIterables!(pred, typeof(Iter.init.tail(0)), Sub)
        );
    }else{
        enum bool canCompareTail = false;
    }
}



/// Compare the head of one iterable to another iterable. Like startsWith.
bool headis(alias pred = DefaultCompareEnds, Iter, Sub)(
    auto ref Iter iter, auto ref Sub sub
) if(canCompareHead!(Iter, Sub, pred)){
    return iter.head(cast(size_t) sub.length).compare!pred(sub);
}

/// Compare the tail of one iterable to another iterable. Like endsWith.
bool tailis(alias pred = DefaultCompareEnds, Iter, Sub)(
    auto ref Iter iter, auto ref Sub sub
) if(canCompareTail!(Iter, Sub, pred)){
    return iter.tail(cast(size_t) sub.length).compare!pred(sub);
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Compare ends", {
        tests("Head", {
            test("test".headis("te"));
            test("test".headis("test"));
            testf("test".headis("aa"));
            testf("test".headis("testaa"));
        });
        tests("Tail", {
            test("test".tailis("st"));
            test("test".tailis("test"));
            testf("test".tailis("aa"));
            testf("test".tailis("aatest"));
        });
    });
}
