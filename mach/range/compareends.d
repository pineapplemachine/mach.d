module mach.range.compareends;

private:

import mach.traits : isIterable, isFiniteIterable, isIterableReverse;
import mach.traits : ElementType;
import mach.range.asrange : asrange, validAsRange, validAsBidirectionalRange;
import mach.range.elementcount : elementcount, canGetElementCount;

/++ Docs

The `headis` and `tailis` functions can be used to compare the leading or
trailing elements of one iterable to another, respectively.
The first argument to either function is an iterable to be searched in,
and the second argument is the subject to be searched for. In the case of
`headis`, the leading elements of the first iterable must be equal to all the
elements of the second. In the case of `tailis`, the trailing elements of
the first iterable must be equal to all the elements of the second.

Note that attempting to call either function with two infinite iterables will
result in a compile error.

+/

unittest{ /// Example
    assert("hello world".headis("hello"));
    assert("hello world".tailis("world"));
}

unittest{ /// Example
    // An iterable always begins with an empty one.
    assert("greetings".headis(""));
    assert("salutations".tailis(""));
}

unittest{ /// Example
    // A finite iterable never begins or ends with an infinite one.
    import mach.range.rangeof : infrangeof;
    assert(!"yo".headis(infrangeof('k')));
    assert(!"hi".tailis(infrangeof('k')));
}

/++ Docs

Both functions optionally accept a comparison function as a template argument.
By default, the comparison between elements of the inputs is simple equality.

+/

unittest{ /// Example
    import mach.text.ascii : tolower;
    alias compare = (a, b) => (a.tolower == b.tolower);
    assert("Hello World".headis!compare("HELLO"));
}

public:



alias DefaultCompareEnds = (a, b) => (a == b);



/// Determine whether the head of Iter be compared to Subject using the given predicate.
/// Both inputs must be iterables,
/// and at least one must be valid as a range.
template canCompareHead(Iter, Subject, alias pred = DefaultCompareEnds){
    static if(
        isIterable!Iter && isIterable!Subject &&
        (validAsRange!Iter || validAsRange!Subject)
    ){
        enum bool canCompareHead = is(typeof({
            pred(ElementType!Iter.init, ElementType!Subject.init);
        }));;
    }else{
        enum bool canCompareHead = false;
    }
}

/// Determine whether the tail of Iter be compared to Subject using the given predicate.
/// Both inputs must be bidirectional iterables,
/// and at least one must be valid as a bidirectional range.
template canCompareTail(Iter, Subject, alias pred = DefaultCompareEnds){
    static if(
        isIterableReverse!Iter && isIterableReverse!Subject &&
        (validAsBidirectionalRange!Iter || validAsBidirectionalRange!Subject)
    ){
        enum bool canCompareTail = is(typeof({
            pred(ElementType!Iter.init, ElementType!Subject.init);
        }));;
    }else{
        enum bool canCompareTail = false;
    }
}



/// Compare the head of one iterable to another iterable.
bool headis(alias pred = DefaultCompareEnds, Iter, Subject)(
    auto ref Iter iter, auto ref Subject subject
) if(canCompareHead!(Iter, Subject, pred)){
    static if(isFiniteIterable!Subject){
        static if(canGetElementCount!Subject){
            // Zero-length subject always satisfies
            if(subject.elementcount == 0) return true;
            static if(canGetElementCount!Iter){
                // If the input is shorter than the subject, it can't contain it
                if(iter.elementcount < subject.elementcount) return false;
            }
        }
        static if(validAsRange!Iter){
            auto iterate = subject;
            auto range = iter.asrange;
            alias compare = pred;
        }else static if(validAsRange!Subject){
            auto iterate = iter;
            auto range = subject.asrange;
            alias compare = (a, b) => (pred(b, a)); // Maintain order of arguments
        }else{
            static assert(false); // Shouldn't happen
        }
        foreach(element; iterate){
            if(range.empty) return false;
            if(!pred(range.front, element)) return false;
            range.popFront();
        }
        return true;
    }else{
        static if(isFiniteIterable!Iter){
            return false;
        }else{
            static assert(false, "Cannot compare two infinite ranges.");
        }
    }
}

/// Compare the tail of one iterable to another iterable.
bool tailis(alias pred = DefaultCompareEnds, Iter, Subject)(
    auto ref Iter iter, auto ref Subject subject
) if(canCompareTail!(Iter, Subject, pred)){
    static if(isFiniteIterable!Subject){
        static if(canGetElementCount!Subject){
            // Zero-length subject always satisfies
            if(subject.elementcount == 0) return true;
            static if(canGetElementCount!Iter){
                // If the input is shorter than the subject, it can't contain it
                if(iter.elementcount < subject.elementcount) return false;
            }
        }
        static if(validAsBidirectionalRange!Iter){
            auto iterate = subject;
            auto range = iter.asrange;
            alias compare = pred;
        }else static if(validAsBidirectionalRange!Subject){
            auto iterate = iter;
            auto range = subject.asrange;
            alias compare = (a, b) => (pred(b, a)); // Maintain order of arguments
        }else{
            static assert(false); // Shouldn't happen
        }
        foreach_reverse(element; iterate){
            if(range.empty) return false;
            if(!pred(range.back, element)) return false;
            range.popBack();
        }
        return true;
    }else{
        static if(isFiniteIterable!Iter){
            return false;
        }else{
            static assert(false, "Cannot compare two infinite ranges.");
        }
    }
}



version(unittest){
    private:
    import mach.test;
    struct InfRange{
        enum bool empty = false;
        @property auto front(){return ' ';}
        void popFront(){}
        @property auto back(){return ' ';}
        void popBack(){}
    }
}
unittest{
    tests("Compare ends", {
        tests("Head", {
            test("".headis(""));
            testf("".headis("ok"));
            test("ok".headis(""));
            test("test".headis("te"));
            test("test".headis("test"));
            testf("test".headis("aa"));
            testf("test".headis("testaa"));
        });
        tests("Tail", {
            test("".tailis(""));
            testf("".tailis("ok"));
            test("ok".tailis(""));
            test("test".tailis("st"));
            test("test".tailis("test"));
            testf("test".tailis("aa"));
            testf("test".tailis("aatest"));
        });
        tests("Explicit predicate", {
            test("abc".headis!((a, b) => true)("xyz"));
            test("abc".tailis!((a, b) => true)("xyz"));
        });
        tests("Infinite subject", {
            // A finite input can't contain an infinite subject
            InfRange range;
            testf("".headis(range));
            testf("".tailis(range));
            // Can't compare two infinite ranges
            static assert(!is(typeof(range.headis(range))));
            static assert(!is(typeof(range.tailis(range))));
        });
    });
}
