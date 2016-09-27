module mach.range.count;

private:

import mach.traits : isFiniteIterable;

public:



alias DefaultCountPredicate = (x) => (x);

/// Get whether count and related operations are meaningful for the given type.
enum canCount(T) = isFiniteIterable!T;
/// ditto
template canCount(T, Element){
    static if(canCount!T){
        enum bool canCount = is(typeof({
            foreach(item; T.init){
                if(item == Element.init){}
            }
        }));
    }else{
        enum bool canCount = false;
    }
}



/// Eagerly get the number of elements in an iterable which match a predicate.
auto count(alias pred = DefaultCountPredicate, Iter)(
    auto ref Iter iter
) if(canCount!Iter){
    size_t count = 0;
    foreach(item; iter){
        if(pred(item)) count++;
    }
    return count;
}

/// Eagerly get the number of elements in an iterable which are equal to the
/// given value.
auto count(Iter, Element)(
    auto ref Iter iter, auto ref Element element
) if(canCount!(Iter, Element)){
    return count!(e => e == element)(iter);
}



/// True when the number of elements in an iterable matching the predicate
/// is exactly the number expected.
bool exactly(alias pred = DefaultCountPredicate, Iter)(
    auto ref Iter iter, in size_t target
) if(canCount!Iter){
    size_t count = 0;
    foreach(item; iter){
        if(pred(item)){
            if(++count > target) return false;
        }
    }
    return count == target;
}

/// True when the number of elements in an iterable equal to the given value
/// is exactly the number expected.
auto exactly(Iter, Element)(
    auto ref Iter iter, in size_t target, auto ref Element element
) if(canCount!(Iter, Element)){
    return exactly!(e => e == element)(iter, target);
}



/// Common implementation backing morethan, lessthan, atleast, and atmost.
private template CmpCountTemplate(
    alias pred, alias compare, bool onmatch, bool onthru
){
    bool CmpCountTemplate(Iter)(
        auto ref Iter iter, in size_t target
    ) if(canCount!Iter){
        size_t count = 0;
        if(compare(count, target)) return onmatch;
        foreach(item; iter){
            if(pred(item)){
                if(compare(++count, target)) return onmatch;
            }
        }
        return onthru;
    }
}
/// ditto
private template CmpCountTemplate(
    alias compare, bool onmatch, bool onthru
){
    bool CmpCountTemplate(Iter, Element)(
        auto ref Iter iter, in size_t target, auto ref Element element
    ) if(canCount!(Iter, Element)){
        return .CmpCountTemplate!(
            e => e == element, compare, onmatch, onthru
        )(iter, target);
    }
}



/// True when the number of elements in an iterable matching the predicate
/// is more than the number expected.
template morethan(alias pred){
    alias morethan = CmpCountTemplate!(
        pred, (count, target) => (count > target), true, false
    );
}
/// True when the number of elements in an iterable equal to the given value
/// is more than the number expected.
template morethan(){
    alias morethan = CmpCountTemplate!(
        (count, target) => (count > target), true, false
    );
}



/// True when the number of elements in an iterable matching the predicate
/// is less than the number expected.
template lessthan(alias pred){
    alias lessthan = CmpCountTemplate!(
        pred, (count, target) => (count >= target), false, true
    );
}
/// True when the number of elements in an iterable equal to the given value
/// is less than the number expected.
template lessthan(){
    alias lessthan = CmpCountTemplate!(
        (count, target) => (count >= target), false, true
    );
}



/// True when the number of elements in an iterable matching the predicate
/// is at least the number expected.
template atleast(alias pred){
    alias atleast = CmpCountTemplate!(
        pred, (count, target) => (count >= target), true, false
    );
}
/// True when the number of elements in an iterable equal to the given value
/// is at least the number expected.
template atleast(){
    alias atleast = CmpCountTemplate!(
        (count, target) => (count >= target), true, false
    );
}



/// True when the number of elements in an iterable matching the predicate
/// is at most the number expected.
template atmost(alias pred){
    alias atmost = CmpCountTemplate!(
        pred, (count, target) => (count > target), false, true
    );
}
/// True when the number of elements in an iterable equal to the given value
/// is at most the number expected.
template atmost(){
    alias atmost = CmpCountTemplate!(
        (count, target) => (count > target), false, true
    );
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    alias even = (n) => (n % 2 == 0);
    int[0] empty;
    auto zeros = [0, 0, 0];
    auto odds = [1, 3, 5];
    auto evens = [4, 6, 8, 10];
    auto mixed = [0, 1, 2, 3];
    tests("Count", {
        testeq(empty.count!even, 0);
        testeq(odds.count!even, 0);
        testeq(evens.count!even, 4);
        testeq(mixed.count!even, 2);
        testeq(empty.count(0), 0);
        testeq(odds.count(0), 0);
        testeq(zeros.count(0), 3);
    });
    tests("Exactly", {
        test(empty.exactly!even(0));
        test(odds.exactly!even(0));
        test(evens.exactly!even(4));
        test(mixed.exactly!even(2));
        test(empty.exactly(0, 0));
        test(odds.exactly(0, 0));
        test(zeros.exactly(3, 0));
    });
    tests("Count comparison", {
        tests("More than", {
            testf(empty.morethan!even(0));
            testf(empty.morethan!even(1));
            testf(odds.morethan!even(0));
            test(evens.morethan!even(0));
            test(evens.morethan!even(3));
            testf(evens.morethan!even(4));
            test(mixed.morethan!even(0));
            test(mixed.morethan!even(1));
            testf(mixed.morethan!even(2));
            testf(empty.morethan(0, 0));
            testf(odds.morethan(0, 0));
            test(zeros.morethan(0, 0));
            test(zeros.morethan(2, 0));
            testf(zeros.morethan(3, 0));
        });
        tests("Less than", {
            testf(empty.lessthan!even(0));
            test(empty.lessthan!even(1));
            testf(odds.lessthan!even(0));
            testf(evens.lessthan!even(0));
            testf(evens.lessthan!even(4));
            test(evens.lessthan!even(5));
            testf(mixed.lessthan!even(0));
            testf(mixed.lessthan!even(1));
            test(mixed.lessthan!even(3));
            testf(empty.lessthan(0, 0));
            testf(odds.lessthan(0, 0));
            testf(zeros.lessthan(0, 0));
            testf(zeros.lessthan(2, 0));
            test(zeros.lessthan(4, 0));
        });
        tests("At least", {
            test(empty.atleast!even(0));
            testf(empty.atleast!even(1));
            test(odds.atleast!even(0));
            test(evens.atleast!even(0));
            test(evens.atleast!even(3));
            testf(evens.atleast!even(5));
            test(mixed.atleast!even(0));
            test(mixed.atleast!even(2));
            testf(mixed.atleast!even(3));
            test(empty.atleast(0, 0));
            testf(empty.atleast(1, 0));
            test(odds.atleast(0, 0));
            test(zeros.atleast(0, 0));
            testf(zeros.atleast(4, 0));
        });
        tests("At most", {
            test(empty.atmost!even(0));
            test(empty.atmost!even(1));
            test(odds.atmost!even(0));
            testf(evens.atmost!even(0));
            test(evens.atmost!even(4));
            test(evens.atmost!even(5));
            testf(mixed.atmost!even(0));
            testf(mixed.atmost!even(1));
            test(mixed.atmost!even(3));
            test(empty.atmost(0, 0));
            test(odds.atmost(0, 0));
            testf(zeros.atmost(0, 0));
            testf(zeros.atmost(2, 0));
            test(zeros.atmost(4, 0));
        });
    });
}
