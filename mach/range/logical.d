module mach.range.logical;

private:

import mach.traits : isFiniteIterable;

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
