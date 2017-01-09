module mach.range.logical;

private:

import mach.traits : isFiniteIterable;

/++ Docs

This module provides `any`, `all`, and `none` functions which operate based on
whether elements in an input iterable satisfy a predicate.
`any` returns true when at least one element satisfies the predicate.
`all` returns true when no element fails to satisfy the predicate.
`none` returns true when no element satisfies the predicate.

+/

unittest{ /// Example
    // Any element is greater than 1?
    assert([0, 1, 2, 3].any!(n => n > 1));
    // All elements are greater than or equal to 10?
    assert([10, 11, 12, 13].all!(n => n >= 10));
    // No elements are evenly divisible by 7?
    assert([5, 10, 15, 20].none!(n => n % 7 == 0));
}

/++ Docs

The predicate can be passed to these functions as a template argument.
When no predicate is passed, the default predicate evaluates truthiness
or falsiness of the elements themselves.

+/

unittest{ /// Example
    assert([false, false, true].any);
    assert([true, true, true].all);
    assert([false, false, false].none);
}

public:



alias DefaultLogicalPredicate = (e) => (e);

template canLogical(Iter, alias pred){
    static if(isFiniteIterable!Iter){
        enum bool canLogical = is(typeof({
            foreach(item; Iter.init){
                if(pred(item)){}
            }
        }));
    }else{
        enum bool canLogical = false;
    }
}



/// True if any element in an iterable matches the predicate.
bool any(alias pred = DefaultLogicalPredicate, Iter)(auto ref Iter iter) if(canLogical!(Iter, pred)){
    foreach(ref item; iter){
        if(pred(item)) return true;
    }
    return false;
}

/// True if all elements in an iterable match the predicate.
bool all(alias pred = DefaultLogicalPredicate, Iter)(auto ref Iter iter) if(canLogical!(Iter, pred)){
    foreach(ref item; iter){
        if(!pred(item)) return false;
    }
    return true;
}

/// True if no element in an iterable matches the predicate.
bool none(alias pred = DefaultLogicalPredicate, Iter)(auto ref Iter iter) if(canLogical!(Iter, pred)){
    foreach(ref item; iter){
        if(pred(item)) return false;
    }
    return true;
}



version(unittest){
    private:
    import mach.test;
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
    });
}
