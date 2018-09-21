module mach.range.reduce;

private:

import mach.types : Rebindable, rebindable;
import mach.traits : ElementType, hasNumericLength, hasNumericRemaining;
import mach.traits : isIterable, isFiniteIterable, isRange, isSavingRange;
import mach.traits : isFiniteRange;
import mach.range.asrange : asrange, validAsRange;

/++ Docs

This module implements the
[reduce higher-order function](https://en.wikipedia.org/wiki/Fold_(higher-order_function))
for iterable inputs.

The `reduce` function accepts an accumulation function as its template argument,
and applies that function sequentially to the elements of an input iterable.
The function optionally accepts a seed, which sets the initial value of the
accumulator.
This module implements both `lazyreduce` and `eagerreduce`; the `reduce` symbol
aliases `eagerreduce` because it is by far the more common application of the
function.

An accumulation function must accept two arguments. The first is an accumulator,
which is either explicitly seeded or taken from the first element of the input.
The first is an element from the input. The function must return a new value
for the accumulator. The `reduce` function operates by repeatedly applying this
function, sequentially updating the accumulator value with the elements of the
input.

For example, a simple `sum` function can be implemented using `reduce`.

+/

unittest{ /// Example
    alias sum = (acc, next) => (acc + next);
    assert([1, 2, 3, 4].reduce!sum(10) == 20); // With seed
}

unittest{ /// Example
    alias sum = (acc, next) => (acc + next);
    assert([5, 6, 7].reduce!sum == 18); // No seed
}

/++ Docs

Both lazy and eager `reduce` functions will produce an error if the function
is not seeded with an initial value, and the input is empty.
In this case a `ReduceEmptyError` is thrown, except for code compiled in
release mode, for which this check is ommitted.

+/

unittest{ /// Example
    import mach.test.assertthrows : assertthrows;
    alias sum = (acc, next) => (acc + next);
    assertthrows!ReduceEmptyError({
        new int[0].reduceeager!sum;
    });
    assertthrows!ReduceEmptyError({
        new int[0].reducelazy!sum;
    });
}

public:



/// Exception thrown when attempting to reduce an empty input without
/// providing a seed.
class ReduceEmptyError: Error{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Cannot reduce empty input without an initial value.", file, line, next);
    }
}



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

/// Eagerly apply a reduction function to some input.
auto reduceeager(alias func, Iter)(auto ref Iter iter) if(canReduceEager!(Iter, func)){
    return reduceeager!(func, ElementType!Iter, Iter)(iter);
}

/// ditto
auto reduceeager(alias func, Acc, Iter)(auto ref Iter iter) if(
    canReduceEager!(Iter, Acc, func)
){
    bool first = true;
    Rebindable!Acc acc;
    foreach(element; iter){
        if(first){
            acc = cast(Acc) element;
            first = false;
        }else{
            acc = func(cast(Acc) acc, element);
        }
    }
    version(assert){
        static const error = new ReduceEmptyError();
        if(first) throw error;
    }
    return cast(Acc) acc;
}

/// Eagerly apply a reduction function to some input, given an initial value.
auto reduceeager(alias func, Acc, Iter)(auto ref Iter iter, auto ref Acc initial) if(
    canReduceEager!(Iter, Acc, func)
){
    Rebindable!Acc acc = rebindable(initial);
    foreach(element; iter){
        acc = func(cast(Acc) acc, element);
    }
    return cast(Acc) acc;
}



/// Lazily apply a reduction function to some input.
auto reducelazy(alias func, Iter)(auto ref Iter iter) if(canReduceLazy!(Iter, func)){
    return reducelazy!(func, ElementType!Iter, Iter)(iter);
}

/// ditto
auto reducelazy(alias func, Acc, Iter)(auto ref Iter iter) if(canReduceLazy!(Iter, Acc, func)){
    auto range = iter.asrange;
    return ReduceRange!(typeof(range), Acc, func, false)(range);
}

/// Lazily apply a reduction function to some input, given an initial value.
auto reducelazy(alias func, Acc, Iter)(auto ref Iter iter, Acc initial) if(
    canReduceLazy!(Iter, Acc, func)
){
    auto range = iter.asrange;
    return ReduceRange!(typeof(range), Acc, func, true)(range, initial);
}



/// Range for lazily evaluating a reduce function.
struct ReduceRange(Range, Acc, alias func, bool seeded) if(
    canReduceLazyRange!(Range, Acc, func) &&
    (seeded || is(typeof({Acc x = ElementType!Range.init;})))
){
    alias Accumulator = Rebindable!Acc;
    
    /// The input range that is being reduced.
    Range source;
    /// The current value of the accumulator.
    Accumulator accumulator;
    /// Whether this range is currently empty.
    static if(isFiniteRange!Range) bool isempty;
    
    static if(isFiniteRange!Range) this(Range source, Acc acc, bool isempty = false){
        this.source = source;
        this.accumulator = acc;
        this.isempty = isempty;
    }
    static if(!isFiniteRange!Range) this(Range source, Acc acc){
        this.source = source;
        this.accumulator = acc;
    }
    
    static if(!seeded) this(Range source) in{
        // Disallow inputting an empty range.
        static const error = new ReduceEmptyError();
        if(source.empty) throw error;
    }body{
        this.source = source;
        this.accumulator = this.source.front;
        static if(isFiniteRange!Range) this.isempty = false;
        this.source.popFront();
    }
    
    /// Get whether the range is empty.
    static if(isFiniteRange!Range){
        @property bool empty() const{
            return this.isempty;
        }
    }else{
        static enum bool empty = false;
    }
    
    /// Get the element at the front of the range.
    @property auto front() const in{assert(!this.empty);} body{
        return this.accumulator;
    }
    /// Pop the element at the front of the range.
    void popFront() in{assert(!this.empty);} body{
        static if(isFiniteRange!Range){
            if(this.source.empty){
                this.isempty = true;
                return;
            }
        }
        this.accumulator = func(cast(Acc) this.accumulator, this.source.front);
        this.source.popFront();
    }
    
    static if(hasNumericLength!Range){
        /// Get the total number of elements in the range.
        @property auto length(){
            return this.source.length + seeded;
        }
        /// Ditto
        alias opDollar = length;
    }
    static if(hasNumericRemaining!Range && isFiniteRange!Range){
        /// Get the number of elements remaining before the range is fully consumed.
        @property auto remaining(){
            return cast(size_t) this.source.remaining + !this.isempty;
        }
    }
    
    static if(isSavingRange!Range){
        /// Produce a copy of this range.
        @property typeof(this) save(){
            static if(isFiniteRange!Range){
                return typeof(this)(this.source.save, this.accumulator, this.isempty);
            }else{
                return typeof(this)(this.source.save, this.accumulator);
            }
        }
    }
}



private version(unittest){
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Reduce", {
        alias sum = (acc, next) => (acc + next);
        alias concat = (acc, next) => (acc ~ cast(string)([next + '0']));
        tests("Eager", {
            testeq([1, 2, 3, 4].reduceeager!sum, 10);
            testeq([1, 2, 3, 4].reduceeager!sum(2), 12);
            testeq([1, 2, 3, 4].reduceeager!concat(""), "1234");
            tests("Empty", {
                testfail({
                    // Empty source with no seed should fail
                    new int[0].reduceeager!((a, n) => (a));
                });
            });
        });
        tests("Lazy", {
            tests("No seed", {
                auto range = [1, 2, 3, 4].reducelazy!sum;
                testeq(range.length, 4);
                testeq(range.remaining, 4);
                testeq(range.front, 1);
                range.popFront();
                testeq(range.length, 4);
                testeq(range.remaining, 3);
                testeq(range.front, 3);
                range.popFront();
                testeq(range.remaining, 2);
                testeq(range.front, 6);
                range.popFront();
                testeq(range.remaining, 1);
                testeq(range.front, 10);
                range.popFront();
                testeq(range.remaining, 0);
                test(range.empty);
                testfail({auto x = range.front;});
                testfail({range.popFront();});
            });
            tests("With seed", {
                auto range = [1, 2, 3, 4].reducelazy!sum(2);
                testeq(range.length, 5);
                testeq(range.remaining, 5);
                testeq(range.front, 2);
                range.popFront();
                testeq(range.length, 5);
                testeq(range.remaining, 4);
                testeq(range.front, 3);
                range.popFront();
                testeq(range.remaining, 3);
                testeq(range.front, 5);
                range.popFront();
                testeq(range.remaining, 2);
                testeq(range.front, 8);
                range.popFront();
                testeq(range.remaining, 1);
                testeq(range.front, 12);
                range.popFront();
                testeq(range.remaining, 0);
                test(range.empty);
                testfail({auto x = range.front;});
                testfail({range.popFront();});
            });
            tests("Saving", {
                auto range = [1, 2, 3, 4].reducelazy!sum;
                auto saved = range.save;
                range.popFront();
                testeq(range.front, 3);
                testeq(saved.front, 1);
            });
            tests("Const elements", {
                tests("Ints", {
                    const(int)[] array = [1, 2, 3, 4];
                    auto range = array.reducelazy!sum;
                    test!equals(range, [1, 3, 6, 10]);
                });
                tests("Struct with const member", {
                    struct ConstMember{const int x;}
                    auto input = [ConstMember(0), ConstMember(1), ConstMember(2)];
                    auto range = input.reducelazy!((a, n) => (a + n.x))(0);
                });
            });
            tests("Empty", {
                testfail({
                    // Empty source with no seed should fail
                    new int[0].reducelazy!((a, n) => (a));
                });
            });
        });
    });
}
