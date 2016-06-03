module mach.range.reduce;

private:

import std.traits : isImplicitlyConvertible;
import mach.traits : isIterable, isFiniteIterable, ElementType;
import mach.traits : isRange, hasNumericLength;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canReduceEager(Iter, alias func) = (
    canReduceEager!(Iter, ElementType!Iter, func)
);
enum canReduceEager(Iter, Acc, alias func) = (
    isFiniteIterable!Iter && validReduceFunction!(Iter, Acc, func)
);

enum canReduceLazy(Iter, alias func) = (
    canReduceLazy!(Iter, ElementType!Iter, func)
);
enum canReduceLazy(Iter, Acc, alias func) = (
    validAsRange!Iter && validReduceFunction!(Iter, Acc, func)
);

enum canReduceLazyRange(Range, alias func) = (
    canReduceLazyRange!(Range, ElementType!Range, func)
);
enum canReduceLazyRange(Range, Acc, alias func) = (
    isRange!Range && validReduceFunction!(Range, Acc, func)
);

template validReduceFunction(Iter, Acc, alias func) if(isIterable!Iter){
    enum bool validReduceFunction = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        auto element = Element.init;
        auto first = func(Acc.init, element);
        auto second = func(first, element);
        auto third = func(second, element);
    }));
}



alias reduce = reduceeager;

auto reduceeager(alias func, Iter)(in Iter iter) if(canReduceEager!(Iter, func)){
    return reduceeager!(func, ElementType!Iter, Iter)(iter);
}

auto reduceeager(alias func, Acc, Iter)(in Iter iter, in Acc initial) if(
    canReduceEager!(Iter, Acc, func)
){
    const(Acc)* acc = &initial;
    foreach(element; iter){
        Acc result = func(*acc, element);
        acc = &result;
    }
    return *acc;
}

auto reduceeager(alias func, Acc, Iter)(in Iter iter) if(canReduceEager!(Iter, Acc, func)){
    import std.stdio;
    bool first = true;
    const(Acc)* acc;
    foreach(element; iter){
        if(first){
            auto firstelem = cast(Acc) element;
            acc = &firstelem;
            first = false;
        }else{
            Acc result = func(*acc, element);
            acc = &result;
        }
    }
    assert(!first, "Cannot reduce empty range without an initial value.");
    return *acc;
}



auto reducelazy(alias func, Iter)(in Iter iter) if(canReduceLazy!(Iter, func)){
    return reducelazy!(func, ElementType!Iter, Iter)(iter);
}

auto reducelazy(alias func, Acc, Iter)(in Iter iter, in Acc initial) if(
    canReduceLazy!(Iter, Acc, func)
){
    auto range = iter.asrange;
    return ReduceRange!(typeof(range), Acc, func, true)(range, initial);
}

auto reducelazy(alias func, Acc, Iter)(in Iter iter) if(canReduceLazy!(Iter, Acc, func)){
    auto range = iter.asrange;
    return ReduceRange!(typeof(range), Acc, func, false)(range);
}



struct ReduceRange(Range, Acc, alias func, bool seed = true) if(
    canReduceLazyRange!(Range, Acc, func) &&
    (!seed || isImplicitlyConvertible!(ElementType!Range, Acc))
){
    mixin MetaRangeMixin!(
        Range, `source`, `Save`
    );
    
    Range source;
    Acc value;
    bool empty;
    
    this(typeof(this) range){
        this(range.source, range.value);
    }
    this(Range source, Acc value, bool empty = false){
        this.source = source;
        this.value = value;
        this.empty = empty;
    }
    
    static if(!seed){
        this(Range source){
            this.source = source;
            this.empty = false;
            if(this.source.empty){
                assert(false, "Cannot reduce empty range without an initial value.");
            }else{
                this.value = this.source.front;
                this.source.popFront();
            }
        }
    }
    
    @property auto ref front() const{
        return this.value;
    }
    void popFront(){
        if(!this.source.empty){
            this.value = func(this.value, this.source.front);
            this.source.popFront();
        }else{
            this.empty = true;
        }
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length + seed;
        }
        alias opDollar = length;
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import std.conv : to;
}
unittest{
    tests("Reduce", {
        auto array = [1, 2, 3, 4];
        alias sum = (acc, next) => (acc + next);
        alias concat = (acc, next) => (to!string(acc) ~ to!string(next));
        tests("Eager", {
            testeq("No seed",
                array.reduceeager!sum, 10
            );
            testeq("With seed",
                array.reduceeager!((acc, next) => (acc + next))(2), 12
            );
            testeq("Disparate types",
                array.reduceeager!concat(""), "1234"
            );
        });
        tests("Lazy", {
            tests("No seed", {
                auto range = array.reducelazy!sum;
                testeq("Length", range.length, 4);
                test("Iteration", range.equals([1, 3, 6, 10]));
            });
            tests("With seed", {
                auto range = array.reducelazy!sum(2);
                testeq("Length", range.length, 5);
                test("Iteration", range.equals([2, 3, 5, 8, 12]));
            });
            tests("Saving", {
                auto range = array.reducelazy!sum;
                auto saved = range.save;
                range.popFront();
                testeq(range.front, 3);
                testeq(saved.front, 1);
            });
        });
    });
}
