module mach.meta.predicates;

private:

//

public:



template NegatePredicate(alias func){
    auto NegatePredicate(Args...)(auto ref Args args) if(is(typeof({return !func(args);}))){
        return !func(args);
    }
}



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
