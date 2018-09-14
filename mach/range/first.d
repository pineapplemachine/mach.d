module mach.range.first;

private:

import mach.types : Rebindable;
import mach.traits : ElementType;
import mach.range.asrange : asrange, validAsRange;

/++ Docs

This module implements `first` and `last` functions for finding the first or
the last element of some iterable meeting a predicate function.
The predicate function is passed as a template argument for `first` and `last`
or, if the argument is omitted, a default function matching any element is
used.
(In this case, the functions simply retrieve the first or last element in the
iterable.)

Note that while `last` will work for any iterable, the implementation is
necessarily inefficient for inputs that are not bidirectional.

+/

unittest{ /// Example
    assert([0, 1, 2].first == 0);
    assert([0, 1, 2].first!(n => n % 2) == 1);
}

unittest{ /// Example
    assert([0, 1, 2].last == 2);
    assert([0, 1, 2].last!(n => n % 2) == 1);
}

/++ Docs

`first` and `last` can optionally be called with a fallback value to be returned
when no element of the input satisfies the predicate function, or when the
input iterable is empty.

+/

unittest{ /// Example
    assert([0, 1, 2].first!(n => n > 10)(-1) == -1);
    assert([0, 1, 2].last!(n => n > 10)(-1) == -1);
}

unittest{ /// Example
    auto empty = new int[0];
    assert(empty.first(1) == 1);
    assert(empty.last(1) == 1);
}

/++ Docs

If in these cases a fallback is not provided, an error is produced:
`first` throws a `NoFirstElementError` and `last` a `NoLastElementError`.

+/

unittest{ /// Example
    import mach.test.assertthrows : assertthrows;
    assertthrows!NoFirstElementError({
        [0, 1, 2].first!(n => n > 10); // No elements satisfy the predicate.
    });
}

public:



/// Error thrown when attempting to get the first element satisfying a
/// predicate where none exists, and no fallback was provided.
class NoFirstElementError: Error{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("No elements in the input matched the predicate.", file, line, next);
    }
}

/// Error thrown when attempting to get the last element satisfying a
/// predicate where none exists, and no fallback was provided.
class NoLastElementError: Error{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("No elements in the input matched the predicate.", file, line, next);
    }
}



/// Default predicate for `first` and `last` functions.
alias DefaultFirstPredicate = (e) => (true);

/// Determine whether `first` is valid for some given arguments.
template canFirst(alias pred, Iter){
    enum bool canFirst = is(typeof({
        foreach(element; Iter.init){
            if(pred(element)){}
        }
    }));
}

/// ditto
template canFirst(alias pred, Iter, Fallback){
    enum bool canFirst = canFirst!(pred, Iter) && is(typeof({
        foreach(element; Iter.init){
            auto x = 0 ? element : Fallback.init;
        }
    }));
}

/// Determine whether `last` is valid for some given arguments.
alias canLast = canFirst;

/// Determine whether a more efficient implementation of `last` is valid
/// for some given arguments.
template canReverseLast(alias pred, Iter){
    enum bool canReverseLast = is(typeof({
        foreach_reverse(element; Iter.init){
            if(pred(element)){}
        }
    }));
}



/// Get the first element in an iterable matching the predicate.
/// The default predicate matches everything.
/// If no elements match the predicate, a `NoFirstElementError` is thrown.
auto first(alias pred = DefaultFirstPredicate, Iter)(
    auto ref Iter iter
) if(canFirst!(pred, Iter)){
    foreach(element; iter){
        if(pred(element)) return element;
    }
    static const error = new NoFirstElementError();
    throw error; // No elements matched the predicate
}

/// Get the first element in an iterable matching the predicate.
/// The default predicate matches everything.
/// If no elements match the predicate, the fallback is returned.
auto first(alias pred = DefaultFirstPredicate, Iter, Fallback)(
    auto ref Iter iter, auto ref Fallback fallback
) if(canFirst!(pred, Iter, Fallback)){
    foreach(element; iter){
        if(pred(element)) return element;
    }
    return fallback;
}



/// Get the last element in an iterable matching the predicate.
/// The default predicate matches everything.
/// If no elements match the predicate, a `NoLastElementError` is thrown.
/// If the input doesn't support `foreach_reverse`, then the entire
/// thing will be consumed to find the last matching element.
auto last(alias pred, Iter)(
    auto ref Iter iter
) if(canLast!(pred, Iter)){
    static if(canReverseLast!(pred, Iter)){
        foreach_reverse(element; iter){
            if(pred(element)) return element;
        }
    }else{
        alias Element = ElementType!Iter;
        Rebindable!Element last;
        bool bound = false;
        foreach(element; iter){
            if(pred(element)){
                last = element;
                bound = true;
            }
        }
        if(bound) return cast(Element) last;
    }
    static const error = new NoLastElementError();
    throw error; // No elements matched the predicate
}

/// Get the last element in an iterable matching the predicate.
/// The default predicate matches everything.
/// If no elements match the predicate, the fallback is returned.
/// If the input doesn't support `foreach_reverse`, then the entire
/// thing will be consumed to find the last matching element.
auto last(alias pred, Iter, Fallback)(
    auto ref Iter iter, auto ref Fallback fallback
) if(canLast!(pred, Iter, Fallback)){
    static if(canReverseLast!(pred, Iter)){
        foreach_reverse(element; iter){
            if(pred(element)) return element;
        }
    }else{
        alias Element = ElementType!Iter;
        Rebindable!Element last;
        bool bound = false;
        foreach(element; iter){
            if(pred(element)){
                last = element;
                bound = true;
            }
        }
        if(bound) return cast(Element) last;
    }
    return fallback;
}

/// More optimal implementation for simply acquiring the last element of the input.
auto last(Iter)(auto ref Iter iter) if(
    validAsRange!Iter && canLast!(DefaultFirstPredicate, Iter)
){
    static if(canReverseLast!(DefaultFirstPredicate, Iter)){
        foreach_reverse(element; iter){
            return element;
        }
    }else{
        auto range = iter.asrange;
        while(!range.empty){
            auto element = range.front;
            range.popFront();
            if(range.empty) return element;
        }
    }
    static const error = new NoLastElementError();
    throw error; // No elements matched the predicate
}

/// Ditto
auto last(Iter, Fallback)(auto ref Iter iter, auto ref Fallback fallback) if(
    validAsRange!Iter && canLast!(DefaultFirstPredicate, Iter, Fallback)
){
    static if(canReverseLast!(DefaultFirstPredicate, Iter)){
        foreach_reverse(element; iter){
            return element;
        }
    }else{
        auto range = iter.asrange;
        while(!range.empty){
            auto element = range.front;
            range.popFront();
            if(range.empty) return element;
        }
    }
    return fallback;
}



version(unittest){
    private:
    import mach.test;
    struct TestRange{
        int low, high;
        int index = 0;
        @property bool empty() const{return this.index >= (this.high - this.low);}
        @property int front() const{return this.low + this.index;}
        void popFront(){this.index++;}
    }
}
unittest{
    tests("First", {
        tests("With fallback", {
            testeq([0, 1, 2].first(10), 0);
            testeq(new int[0].first(10), 10);
            testeq([0, 1, 2].first!(n => n > 10)(10), 10);
        });
        tests("No fallback", {
            testeq([0, 1, 2, 3, 4].first!((n) => (n <= 2)), 0);
            testeq([0, 1, 2, 3, 4].first!((n) => (n >= 2)), 2);
            testeq([0, 1, 2].first, 0);
            testfail!NoFirstElementError({new int[0].first;});
            testfail!NoFirstElementError({[0].first!(n => false);});
        });
    });
    tests("Last", {
        tests("Bidirectional", {
            tests("With fallback", {
                testeq([0, 1, 2].last(10), 2);
                testeq(new int[0].last(10), 10);
                testeq([0, 1, 2].last!(n => n > 10)(10), 10);
            });
            tests("No fallback", {
                testeq([0, 1, 2, 3, 4].last!((n) => (n <= 2)), 2);
                testeq([0, 1, 2, 3, 4].last!((n) => (n >= 2)), 4);
                testeq([0, 1, 2].last, 2);
                testfail!NoLastElementError({new int[0].last;});
                testfail!NoLastElementError({[0].last!(n => false);});
            });
        });
        tests("Forward only", {
            tests("With fallback", {
                testeq(TestRange(0, 6).last(10), 5);
                testeq(TestRange(0, 0).last(10), 10);
                testeq(TestRange(0, 6).last!(n => n > 10)(10), 10);
            });
            tests("No fallback", {
                testeq(TestRange(0, 6).last, 5);
                testeq(TestRange(0, 6).last!(n => n % 2 == 0), 4);
                testfail!NoLastElementError({TestRange(0, 0).last;});
                testfail!NoLastElementError({TestRange(0, 6).last!(n => false);});
            });
        });
    });
}
