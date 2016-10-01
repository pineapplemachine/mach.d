module mach.range.reduce;

private:

import mach.traits : isIterable, isFiniteIterable, ElementType;
import mach.traits : isRange, isSavingRange, hasNumericLength, Unqual;
import mach.range.asrange : asrange, validAsRange;

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

template validReduceFunction(Iter, Acc, alias func){
    enum bool validReduceFunction = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        auto element = Element.init;
        Acc first = func(Acc.init, element);
        Acc second = func(first, element);
        Acc third = func(second, element);
    }));
}



alias reduce = reduceeager;

auto reduceeager(alias func, Iter)(auto ref Iter iter) if(canReduceEager!(Iter, func)){
    return reduceeager!(func, ElementType!Iter, Iter)(iter);
}

auto reduceeager(alias func, Acc, Iter)(auto ref Iter iter, auto ref Acc initial) if(
    canReduceEager!(Iter, Acc, func)
){
    Acc* acc = &initial;
    foreach(element; iter){
        Acc result = func(*acc, element);
        acc = &result;
    }
    return *acc;
}

auto reduceeager(alias func, Acc, Iter)(auto ref Iter iter) if(canReduceEager!(Iter, Acc, func)){
    import std.stdio;
    bool first = true;
    Acc* acc;
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



auto reducelazy(alias func, Iter)(auto ref Iter iter) if(canReduceLazy!(Iter, func)){
    return reducelazy!(func, ElementType!Iter, Iter)(iter);
}

auto reducelazy(alias func, Acc, Iter)(auto ref Iter iter, Acc initial) if(
    canReduceLazy!(Iter, Acc, func)
){
    auto range = iter.asrange;
    return ReduceRange!(typeof(range), Acc, func, true)(range, initial);
}

auto reducelazy(alias func, Acc, Iter)(auto ref Iter iter) if(canReduceLazy!(Iter, Acc, func)){
    auto range = iter.asrange;
    return ReduceRange!(typeof(range), Acc, func, false)(range);
}



struct ReduceRange(Range, Acc, alias func, bool seeded = true) if(
    canReduceLazyRange!(Range, Acc, func) &&
    (seeded || is(typeof({Acc x = ElementType!Range.init;})))
){
    import core.stdc.stdlib : malloc, free;
    import core.stdc.string : memcpy;
    
    Range source;
    Acc* valueptr;
    bool empty;
    
    this(Range source, Acc value, bool empty = false){
        this.source = source;
        this.value = value;
        this.empty = empty;
    }
    this(Range source, Acc* valueptr, bool empty = false){
        this.source = source;
        this.valueptr = valueptr;
        this.empty = empty;
    }
    
    // Makes unittests fail with a "pointer being freed was not allocated" error?
    // TODO: I really need to just use some kind of Rebindable template
    //~this(){
    //    if(this.valueptr){
    //        free(this.valueptr);
    //        this.valueptr = null;
    //    }
    //}
    
    @property Acc value() const{
        return *(this.valueptr);
    }
    @property void value()(in Acc value){
        if(this.valueptr) free(cast(void*) this.valueptr);
        this.valueptr = cast(Acc*) malloc(Acc.sizeof);
        assert(this.valueptr !is null, "Failed to allocate memory.");
        memcpy(cast(void*) this.valueptr, &value, Acc.sizeof);
    }
    
    static if(!seeded){
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
            return this.source.length + seeded;
        }
        alias opDollar = length;
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save, this.value, this.empty);
        }
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
        int[] array = [1, 2, 3, 4];
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
            fail("Empty source, no seed", {
                array[0 .. 0].reduceeager!((a, n) => (a));
            });
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
            tests("Const elements", {
                tests("Ints", {
                    auto range = (cast(const int[]) array).reducelazy!sum;
                    test(range.equals([1, 3, 6, 10]));
                });
                tests("Struct with const member", {
                    struct ConstMember{const int x;}
                    auto input = [ConstMember(0), ConstMember(1), ConstMember(2)];
                    auto range = input.reducelazy!((a, n) => (a + n.x))(0);
                });
            });
            fail("Empty source, no seed", {
                array[0 .. 0].reducelazy!((a, n) => (a));
            });
        });
    });
}
