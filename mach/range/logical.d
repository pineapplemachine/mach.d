module mach.range.logical;

private:

import std.traits : Unqual, isImplicitlyConvertible, isNumeric;
import mach.traits : isIterable, isFiniteIterable, isIterableReverse;
import mach.traits : canIncrement, ElementType, isElementPredicate;

public:



alias DefaultLogicalPredicate = (x) => (x);

enum canCount(T) = isFiniteIterable!T;
enum canExactly(T) = isFiniteIterable!T;

enum canAnyAllNone(Iter, alias pred) = (
    isFiniteIterable!Iter && isElementPredicate!(pred, Iter)
);

alias canAny = canAnyAllNone;
alias canAll = canAnyAllNone;
alias canNone = canAnyAllNone;




/// True if any element in an iterable matches the predicate.
bool any(alias pred = DefaultLogicalPredicate, Iter)(auto ref Iter iter) if(
    canAny!(Iter, pred)
){
    foreach(ref item; iter){
        if(pred(item)) return true;
    }
    return false;
}

/// True if all elements in an iterable match the predicate.
bool all(alias pred = DefaultLogicalPredicate, Iter)(auto ref Iter iter) if(
    canAll!(Iter, pred)
){
    foreach(ref item; iter){
        if(!pred(item)) return false;
    }
    return true;
}

/// True if no element in an iterable matches the predicate.
bool none(alias pred = DefaultLogicalPredicate, Iter)(auto ref Iter iter) if(
    canNone!(Iter, pred)
){
    foreach(ref item; iter){
        if(pred(item)) return false;
    }
    return true;
}



enum canFindFirst(Iter) = isIterable!Iter;
enum canFindLast(Iter) = isIterableReverse!Iter;
enum canFindFirst(Iter, Fallback) = (
    canFindFirst!Iter && isImplicitlyConvertible!(ElementType!Iter, Fallback)
);
enum canFindLast(Iter, Fallback) = (
    canFindLast!Iter && isImplicitlyConvertible!(ElementType!Iter, Fallback)
);

enum canFindLast(Iter, alias pred) = (
    isFiniteIterable!Iter && isIterableReverse!Iter &&
    isElementPredicate!(pred, Iter)
);
enum canFindFirst(Iter, alias pred) = (
    isFiniteIterable!Iter &&
    isElementPredicate!(pred, Iter)
);
enum canFindLast(Iter, alias pred) = (
    isFiniteIterable!Iter && isIterableReverse!Iter &&
    isElementPredicate!(pred, Iter)
);
enum canFindFirst(Iter, Fallback, alias pred) = (
    canFindFirst!(Iter, Fallback) &&
    isElementPredicate!(pred, Iter)
);
enum canFindLast(Iter, Fallback, alias pred) = (
    canFindLast!(Iter, Fallback) &&
    isElementPredicate!(pred, Iter)
);

/// Get the first element
auto ref first(Iter, Fallback)(
    auto ref Iter iter, Fallback fallback
) if(canFindFirst!(Iter, Fallback)){
    foreach(ref item; iter) return item;
    return fallback;
}

/// ditto
auto ref first(Iter)(auto ref Iter iter) if(canFindFirst!Iter){
    return first!(Iter, ElementType!Iter)(iter, ElementType!Iter.init);
}

/// Get the first element matching a predicate.
auto ref first(alias pred, Iter, Fallback)(
    auto ref Iter iter, Fallback fallback
) if(canFindFirst!(Iter, Fallback)){
    foreach(ref item; iter){
        if(pred(item)) return item;
    }
    return fallback;
}

/// ditto
auto ref first(alias pred, Iter)(auto ref Iter iter) if(canFindFirst!Iter){
    return first!(pred, Iter, ElementType!Iter)(iter, ElementType!Iter.init);
}

/// Get the last element
auto ref last(Iter, Element)(
    auto ref Iter iter, Element fallback
) if(canFindLast!(Iter, Element)){
    foreach_reverse(ref item; iter) return item;
    return fallback;
}

/// ditto
auto ref last(Iter)(auto ref Iter iter) if(canFindLast!Iter){
    return last!(Iter, ElementType!Iter)(iter, ElementType!Iter.init);
}

/// Get the last element matching a predicate.
auto ref last(alias pred, Iter, Element)(
    auto ref Iter iter, Element fallback
) if(canFindLast!(Iter, Element)){
    foreach_reverse(ref item; iter){
        if(pred(item)) return item;
    }
    return fallback;
}

/// ditto
auto ref last(alias pred, Iter)(auto ref Iter iter) if(canFindLast!Iter){
    return last!(pred, Iter, ElementType!Iter)(iter, ElementType!Iter.init);
}



auto count(Iter, Element)(auto ref Iter iter, Element element) if(
    canCount!Iter
){
    return count!(e => e == element)(iter);
}

auto count(alias pred = DefaultLogicalPredicate, Iter)(auto ref Iter iter) if(
    canCount!Iter
){
    size_t count = 0;
    foreach(item; iter){
        if(pred(item)) count++;
    }
    return count;
}

auto exactly(Iter, Element)(auto ref Iter iter, Element element, in size_t target) if(canExactly!Iter){
    return exactly!(e => e == element)(iter, target);
}

bool exactly(alias pred = DefaultLogicalPredicate, Iter)(auto ref Iter iter, in size_t target) if(canExactly!Iter){
    size_t count = 0;
    foreach(item; iter){
        if(pred(item)){
            count++;
            if(count > target) return false;
        }
    }
    return !(count < target);
}



private template moreless(string name, string op, bool upon){
    private bool moreless(
        alias pred = DefaultLogicalPredicate, Iter
    )(auto ref Iter iter, in size_t target) if(canCount!Iter){
        size_t count = 0;
        mixin(`if(count ` ~ op ~ ` target) return upon;`);
        foreach(item; iter){
            if(pred(item)){
                count++;
                mixin(`if(count ` ~ op ~ ` target) return upon;`);
            }
        }
        return !upon;
    }
    mixin(`alias ` ~ name ~ ` = moreless;`);
}

mixin moreless!(`more`, `>`, true);
mixin moreless!(`less`, `>=`, false);
mixin moreless!(`atleast`, `>=`, true);
mixin moreless!(`atmost`, `>`, false);



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Logical", {
        alias pred = (n) => (n > 0);
        auto pos = [1, 1, 2, 2, 3, 3];
        auto zero = [0, 0, 0, 0];
        auto mixed = [1, 0, 2, 0, 3, 0];
        auto bools = [true, false, true, false];
        tests("Any", {
            test(pos.any!pred);
            testf(zero.any!pred);
            test(mixed.any!pred);
            test(bools.any);
        });
        tests("All", {
            test(pos.all!pred);
            testf(zero.all!pred);
            testf(mixed.all!pred);
            testf(bools.all);
        });
        tests("None", {
            testf(pos.none!pred);
            test(zero.none!pred);
            testf(mixed.none!pred);
            testf(bools.none);
        });
        tests("Count", {
            testeq(pos.count!pred, pos.length);
            testeq(zero.count!pred, 0);
            testeq(mixed.count!pred, mixed.length / 2);
            testeq(bools.count, bools.length / 2);
        });
        tests("Exactly", {
            test(pos.exactly!pred(pos.length));
            test(zero.exactly!pred(0));
            test(mixed.exactly!pred(mixed.length / 2));
            test(bools.exactly!pred(bools.length / 2));
        });
        tests("Count comparison", {
            tests("More", {
                test(pos.more!pred(0));
                testf(pos.more!pred(pos.length));
                testf(pos.more!pred(pos.length + 1));
                test(bools.more(0));
            });
            tests("Less", {
                testf(pos.less!pred(0));
                testf(pos.less!pred(pos.length));
                test(pos.less!pred(pos.length + 1));
                testf(bools.less(0));
            });
            tests("At least", {
                test(pos.atleast!pred(0));
                test(pos.atleast!pred(pos.length));
                testf(pos.atleast!pred(pos.length + 1));
                test(bools.atleast(0));
            });
            tests("At most", {
                testf(pos.atmost!pred(0));
                test(pos.atmost!pred(pos.length));
                test(pos.atmost!pred(pos.length + 1));
                testf(bools.atmost(0));
            });
        });
        tests("First", {
            testeq([0, 1, 2, 3, 4].first!((n) => (n <= 2)), 0);
            testeq([0, 1, 2, 3, 4].first!((n) => (n >= 2)), 2);
            testeq([0, 1, 2].first, 0);
        });
        tests("Last", {
            testeq([0, 1, 2, 3, 4].last!((n) => (n <= 2)), 2);
            testeq([0, 1, 2, 3, 4].last!((n) => (n >= 2)), 4);
            testeq([0, 1, 2].last, 2);
        });
    });
}
