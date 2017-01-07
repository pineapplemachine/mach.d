module mach.meta.predicates;

private:

/++ Docs: mach.meta.predicates

Provides templates which apply logical operations to predicate functions.

`NegatePredicate` produces a predicate which is a logical negation of the input.
`AndPredicates` produces a predicate which is only satisfied when all of its
inputs are satisfied.
`OrPredicates` produces a predicate which is satisfied when anu of its
inputs are satisfied.

+/

unittest{ /// Example
    alias pred = (x) => (x == 0);
    assert(pred(0));
    assert(!pred(1));
    assert(NegatePredicate!pred(1));
    assert(!NegatePredicate!pred(0));
}

unittest{ /// Example
    alias a = (x) => (x != 1);
    alias b = (x) => (x != 2);
    assert(AndPredicates!(a, b)(0));
    assert(!AndPredicates!(a, b)(1));
    assert(!AndPredicates!(a, b)(2));
}

unittest{ /// Example
    alias a = (x) => (x == 1);
    alias b = (x) => (x == 2);
    assert(OrPredicates!(a, b)(1));
    assert(OrPredicates!(a, b)(2));
    assert(!OrPredicates!(a, b)(3));
}

public:



/// Given a predicate, produce a predicate function which is a logical negation
/// of that input predicate.
template NegatePredicate(alias func){
    auto NegatePredicate(Args...)(auto ref Args args) if(is(typeof({return !func(args);}))){
        return !func(args);
    }
}

/// Given some predicates, produce a predicate function which is satisfied only
/// when all of the input predicates are satisfied.
template AndPredicates(funcs...) if(funcs.length){
    static if(funcs.length == 1){
        alias AndPredicates = funcs[0];
    }else{
        auto AndPredicates(Args...)(auto ref Args args) if(is(typeof({
            foreach(func; funcs){if(!func(args)){}}
        }))){
            foreach(func; funcs){
                if(!func(args)) return false;
            }
            return true;
        }
    }
}

/// Given some predicates, produce a predicate function which is satisfied
/// when any of the input predicates are satisfied.
template OrPredicates(funcs...) if(funcs.length){
    static if(funcs.length == 1){
        alias OrPredicates = funcs[0];
    }else{
        auto OrPredicates(Args...)(auto ref Args args) if(is(typeof({
            foreach(func; funcs){if(func(args)){}}
        }))){
            foreach(func; funcs){
                if(func(args)) return true;
            }
            return false;
        }
    }
}



version(unittest){
    private:
    import mach.meta.aliases : Aliases;
}

unittest{
    alias apred = (x) => (x == 0);
    bool fpred(in int x){return x == 0;}
    static bool sfpred(in int x){return x == 0;}
    auto fppred = &fpred;
    bool delegate(in int) dgpred = (in int x){return x == 0;};
    foreach(pred; Aliases!(apred, fpred, sfpred, fppred, dgpred)){
        assert(pred(0));
        assert(!pred(1));
        assert(NegatePredicate!pred(1));
        assert(!NegatePredicate!pred(0));
    }
}
unittest{
    alias pred = (a, b) => (a == b);
    assert(pred(0, 0));
    assert(!pred(0, 1));
    assert(NegatePredicate!pred(0, 1));
    assert(!NegatePredicate!pred(0, 0));
}

unittest{
    alias pred = (x) => (x == 0);
    assert(AndPredicates!pred(0));
    assert(!AndPredicates!pred(1));
}
unittest{
    alias preda = (int x) => (x > 0);
    alias predb = (long x) => (x > 10);
    assert(AndPredicates!(preda, predb)(11));
    assert(!AndPredicates!(preda, predb)(0));
    assert(!AndPredicates!(preda, predb)(1));
}
unittest{
    alias preda = (x, y) => (x > 0);
    alias predb = (x, y) => (x > 10);
    assert(AndPredicates!(preda, predb)(11, 0));
    assert(!AndPredicates!(preda, predb)(0, 0));
    assert(!AndPredicates!(preda, predb)(1, 0));
}

unittest{
    alias pred = (x) => (x == 0);
    assert(OrPredicates!pred(0));
    assert(!OrPredicates!pred(1));
}
unittest{
    alias preda = (x) => (x == 0);
    alias predb = (x) => (x == 1);
    assert(OrPredicates!(preda, predb)(0));
    assert(OrPredicates!(preda, predb)(1));
    assert(!OrPredicates!(preda, predb)(2));
}
unittest{
    alias preda = (x, y) => (x == 0);
    alias predb = (x, y) => (x == 1);
    assert(OrPredicates!(preda, predb)(0, 0));
    assert(OrPredicates!(preda, predb)(1, 0));
    assert(!OrPredicates!(preda, predb)(2, 0));
}
