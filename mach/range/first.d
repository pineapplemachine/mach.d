module mach.range.first;

private:

//

public:



alias DefaultFirstPredicate = (e) => (true);

template canFirst(alias pred, Iter){
    enum bool canFirst = is(typeof({
        foreach(item; Iter.init){
            if(pred(item)){}
        }
    }));
}
template canFirst(alias pred, Iter, Fallback){
    enum bool canFirst = canFirst!(pred, Iter) && is(typeof({
        foreach(item; Iter.init){
            auto x = 0 ? item : Fallback.init;
        }
    }));
}

template canLast(alias pred, Iter){
    enum bool canLast = is(typeof({
        foreach_reverse(item; Iter.init){
            if(pred(item)){}
        }
    }));
}
template canLast(alias pred, Iter, Fallback){
    enum bool canLast = canLast!(pred, Iter) && is(typeof({
        foreach_reverse(item; Iter.init){
            auto x = 0 ? item : Fallback.init;
        }
    }));
}



/// Get the first element in an iterable matching the predicate.
/// The default predicate matches everything.
/// If no elements match the predicate, an assertion failure results.
auto ref first(alias pred = DefaultFirstPredicate, Iter)(
    auto ref Iter iter
) if(canFirst!(pred, Iter)){
    foreach(item; iter){
        if(pred(item)) return item;
    }
    assert(false, "No items in range match the predicate.");
}

/// Get the first element in an iterable matching the predicate.
/// The default predicate matches everything.
/// If no elements match the predicate, the fallback is returned.
auto ref first(alias pred = DefaultFirstPredicate, Iter, Fallback)(
    auto ref Iter iter, auto ref Fallback fallback
) if(canFirst!(pred, Iter, Fallback)){
    foreach(item; iter){
        if(pred(item)) return item;
    }
    return fallback;
}



/// Get the last element in an iterable matching the predicate.
/// The default predicate matches everything.
/// If no elements match the predicate, an assertion failure results.
auto ref last(alias pred = DefaultFirstPredicate, Iter)(
    auto ref Iter iter
) if(canLast!(pred, Iter)){
    foreach_reverse(item; iter){
        if(pred(item)) return item;
    }
    assert(false, "No items in range match the predicate.");
}

/// Get the last element in an iterable matching the predicate.
/// The default predicate matches everything.
/// If no elements match the predicate, the fallback is returned.
auto ref last(alias pred = DefaultFirstPredicate, Iter, Fallback)(
    auto ref Iter iter, auto ref Fallback fallback
) if(canLast!(pred, Iter, Fallback)){
    foreach_reverse(item; iter){
        if(pred(item)) return item;
    }
    return fallback;
}



version(unittest){
    private:
    import mach.test;
}
unittest{
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
}
