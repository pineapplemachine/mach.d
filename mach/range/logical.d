module mach.range.logical;

private:

import std.traits : Unqual;
import mach.traits : isFiniteIterable, canIncrement, canCompare;

public:



alias DefaultLogicalPredicate = (x) => (x);

enum canCount(Iter, Count) = isFiniteIterable!Iter && canIncrement!Count;

enum canMore(Iter, Count) = (
    canCount!(Iter, Unqual!Count) && canCompare(Unqual!Count, Count, ">")
);
enum canLess(Iter, Count) = (
    canCount!(Iter, Unqual!Count) && canCompare(Unqual!Count, Count, "<")
);
enum canAtMost(Iter, Count) = (
    canCount!(Iter, Unqual!Count) && canCompare(Unqual!Count, Count, "<=")
);
enum canAtLeast(Iter, Count) = (
    canCount!(Iter, Unqual!Count) && canCompare(Unqual!Count, Count, ">=")
);



enum validExactlyCount(T) = (
    canIncrement!(Unqual!T) && // Can keep a count
    canCompare!(Unqual!T, T, ">") && // Can short-circuit when target count exceeded
    canCompare!(Unqual!T, T, "<") // Can count is not less than target
);

enum canExactly(Iter, Count) = isFiniteIterable!Iter && validExactlyCount!Count;



/// True if any element in an iterable matches the predicate.
bool any(alias pred = DefaultLogicalPredicate, Iter)(Iter iter) if(isFiniteIterable!Iter){
    foreach(item; iter){
        if(pred(item)) return true;
    }
    return false;
}

/// True if all elements in an iterable match the predicate.
bool all(alias pred = DefaultLogicalPredicate, Iter)(Iter iter) if(isFiniteIterable!Iter){
    foreach(item; iter){
        if(!pred(item)) return false;
    }
    return true;
}

/// True if no element in an iterable matches the predicate.
bool none(alias pred = DefaultLogicalPredicate, Iter)(Iter iter) if(isFiniteIterable!Iter){
    foreach(item; iter){
        if(pred(item)) return false;
    }
    return true;
}



auto count(
    alias pred = DefaultLogicalPredicate, Count = size_t, Iter
)(Iter iter) if(canCount!(Iter, Count)){
    Count count = Count.init;
    foreach(item; iter){
        if(pred(item)) count++;
    }
    return count;
}

bool exactly(
    alias pred = DefaultLogicalPredicate, Count, Iter
)(Iter iter, Count target) if(canExactly!(Iter, Count)){
    auto count = Unqual!Count.init;
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
        alias pred = DefaultLogicalPredicate, Count, Iter
    )(
        Iter iter, Count target
    ) if(
        canCount!(Iter, Unqual!Count) && canCompare!(Unqual!Count, Count, op)
    ){
        auto count = Unqual!Count.init;
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
    });
}
