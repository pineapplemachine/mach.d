module mach.range;

private:

/++ Docs

This package implements a variety of functions for performing operations
upon iterables, typically either ranges or ones that are valid as ranges.
The majority of functions that are possible to implement as lazy sequences
do in fact return ranges.

Please note that fully documenting this package is a work in progress.
If a module isn't documented here, comments and unit tests in the module
source should hopefully provide sufficient explanation of usage and
functionality.

### Range definition

A range *must* provide these methods and properites:

- `empty`
- `front` as a readable property, and optionally as an assignable one.
- `popFront`

A bidirectional range is one which implements:

- `back` as a readable property, and optionally as an assignable one.
- `popBack`

A random access range is one which implements:

- `opIndex` accepting a single integer argument.
- optionally `opIndexAssign` accepting an element to be assigned in addition
to a single integer argument.

A slicing range is one which implements:

- `opSlice` accepting two integer arguments.

A saving range is one which implements:

- `save`

And some additional properties that are common for ranges to support:

- `mutable`
- `length` and `opDollar`
- `remaining`
- `removeFront`
- `removeBack`

#### empty

All ranges must implement an `empty` property which returns true when the
range has been fully consumed, and false when there are any elements remaining.

+/

unittest{ /// Example
    import mach.range.asrange : asrange;
    auto range = "hi".asrange;
    assert(!range.empty); // Not empty...
    range.popFront();
    assert(!range.empty); // Still not empty...
    range.popFront();
    assert(range.empty); // Empty!
}

unittest{ /// Example
    // A range whose `empty` property is known at compile time to be `false`
    // is considered to be an infinite range.
    import mach.traits : isInfiniteRange;
    import mach.range.rangeof : infrangeof;
    auto infrange = infrangeof('x');
    static assert(isInfiniteRange!(typeof(infrange)));
    static assert(infrange.empty == false); // Value known at compile time
}

unittest{ /// Example
    // When the `empty` property is known at compile time but is true,
    // the range is always and completely empty.
    import mach.range.rangeof : emptyrangeof;
    auto emptyrange = emptyrangeof!int;
    static assert(is(typeof(emptyrange.front) == int));
    static assert(emptyrange.empty == true); // Value known at compile time
}

/++ Docs

#### front

All ranges must implement a `front` property which accesses the element
under the range's front cursor.

+/

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof(1, 2, 3);
    assert(range.front == 1);
}

/++ Docs

Some ranges may allow `front` to be used in assigments.
When an expression like `range.front = value;` compiles, and when
`range.mutable == true` (except for incorrect implementations, the first
condition should always imply the second — though not vice versa),
the range is considered to have a mutable front.

When a range is created from some backing data set, the satisfaction
of those two conditions implies that when the value is changed in the range,
it will persist when the front is re-accessed, and the change will also be
present in that backing data set.
(Ranges not created from backing data sets, and so having nowhere to persist
information to, are never mutable.)

+/

unittest{ /// Example
    import mach.traits : isMutableFrontRange;
    import mach.range.asrange : asrange;
    auto array = [1, 2, 3];
    auto range = array.asrange;
    // A range created from an array with mutable elements also allows mutation of its elements.
    static assert(isMutableFrontRange!(typeof(range)));
    assert(range.front == 1);
    range.front = 100;
    assert(range.front == 100);
    assert(array == [100, 2, 3]);
}

/++ Docs

Note that, in cases like this, mutating the backing data set will also mutate the range.
Depending on the form of mutation, this may result in strange behavior.
For practical purposes, one should always assume that modifying a backing data set
will invalidate any ranges currently enumerating that data set.

+/

unittest{ /// Example
    import mach.range.asrange : asrange;
    auto array = [1, 2, 3];
    auto range = array.asrange;
    array.length = 2; // `range` may no longer behave correctly!
}

/++ Docs

#### popFront

All ranges must implement a `popFront` method which consumes the front element,
progressing the front cursor to the next element.
After all the elements in a range have been consumed, e.g. by calls to
`popFront`, `range.empty` will be true and any further calls to `front` or
`popFront` will be thwarted by errors. (Except for in release mode, in which
case the checks necessary to perform such error reporting may be omitted,
and undefined behavior or nasty crashes will result instead.)

+/

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof(1, 2);
    assert(range.front == 1); // Check the first element,
    range.popFront(); // Consume it.
    assert(range.front == 2); // Now check the second element,
    range.popFront(); // And consume that one, too.
    assert(range.empty);
    // Now that the range has been fully consumed...
    import mach.error.mustthrow : mustthrow;
    mustthrow({
        range.front; // Accessing its front produces an error,
    });
    mustthrow({
        range.popFront(); // And so does calling `popFront`.
    });
}

/++ Docs

#### back and popBack

Ranges which support both the `back` property and `popBack` method are
bidirectional ranges.
Such ranges have not only a front cursor accessed and progressed by `front`
and `popFront` but also a back cursor accessed and progressed by their
complementary `back` and `popBack`.

+/

unittest{ /// Example
    import mach.traits : isBidirectionalRange;
    import mach.range.asrange : asrange;
    // Ranges produced from arrays are always bidirectional.
    auto range = [1, 2, 3].asrange;
    static assert(isBidirectionalRange!(typeof(range)));
    assert(range.back == 3);
    range.popBack();
    assert(range.back == 2);
    range.popBack();
    assert(range.back == 1);
    range.popBack();
    assert(range.empty);
    // Like `front` and `popFront`, `back` and `popBack` also fail for
    // ranges that have already been fully consumed.
    import mach.error.mustthrow : mustthrow;
    mustthrow({
        range.back;
    });
    mustthrow({
        range.popBack();
    });
}

/++ Docs

Like `front`, `back` may also allow assignment.

+/

unittest{ /// Example
    import mach.traits : isMutableBackRange;
    import mach.range.asrange : asrange;
    auto array = [1, 2, 3];
    auto range = array.asrange;
    static assert(isMutableBackRange!(typeof(range)));
    assert(range.back == 3);
    range.back = 300;
    assert(range.back == 300);
    assert(array == [1, 2, 300]);
}

/++ Docs

Any bidirectional range allows any combination of calls to `front` and `back`,
`popFront` and `popBack` over the course of consuming that range.
Though enumerating a range strictly in forward or reverse order is the most
common need, it's important to note that enumeration is not restricted to
that form of usage.

+/

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof(1, 2, 3);
    assert(range.front == 1);
    assert(range.back == 3);
    range.popFront();
    assert(range.front == 2);
    range.popBack();
    // Now the front and back cursor both point at the same, single remaining element.
    assert(range.back == 2);
    range.popFront();
    assert(range.empty);
}

/++ Docs

Unlike forward ranges (those which do not support `back` and `popBack`)
whose elements may be enumerated using `foreach` but not `foreach_reverse`,
bidirectional ranges may be operated upon using both loop types.

+/

unittest{ /// Example
    // The range produced by `rangeof` is bidirectional, and so it works with both...
    import mach.range.rangeof : rangeof;
    foreach(i; rangeof(1, 2, 3)){} // Forward enumeration via `foreach`,
    foreach_reverse(i; rangeof(4, 5, 6)){} // And backwards via `foreach_reverse`.
}

unittest{ /// Example
    // `recur` produces a forward range, so it works only with `foreach`.
    import mach.range.recur : recur;
    auto range = recur!(n => n + 1, n => n >= 10)(0);
    foreach(i; range){} // Forward enumeration ok!
    static assert(!is(typeof({ // Backwards enumeration not ok.
        foreach_reverse(i; range){}
    })));
}

/++ Docs

#### mutable

A range may have a compile-time `mutable` boolean property.
When `range.mutable == true`, that range supports some form of mutation of
its contents. (There are several such forms, and they may be present in
any combination — the only guarantee is that at least one of them is valid.)
When `range.mutable == false`, or when no `mutable` property is present,
the range supports no mutation of its contents.

The `isMutableRange` template implemented in `mach.traits` may be used
to determine whether `range.mutable` is both present and true.

+/

unittest{ /// Example
    import mach.traits : isMutableRange;
    import mach.range.asrange : asrange;
    // A mutable range built from a mutable array:
    int[] mutablearray = [1, 2, 3];
    auto mutablerange = mutablearray.asrange;
    static assert(isMutableRange!(typeof(mutablerange)));
    mutablerange.front = 100; // Ok!
    // A range of immutable elements built from an array of immutable elements:
    const(int)[] immutablearray = [4, 5, 6];
    auto immutablerange = immutablearray.asrange;
    static assert(!isMutableRange!(typeof(immutablerange)));
    static assert(!is(typeof({
        immutablerange.front = 200; // Not ok!
    })));
}

/++ Docs

#### length and opDollar

Many range types support a `length` property which indicates the total number
of elements that the range will have to consume from when it was initialized
before the range becomes empty.
When a range is enumerating some backing data set, `length` is typically the
number of elements in that data set.
The `length` property doesn't change depending on the location of a range's
front or back cursors.

Whenever a range has a `length` property, its type must be an integer.
Though it should be considered an error for generic code to incorrectly handle
length types other than `size_t`, the usefulness of using any other type
for a range's `length` is dubious at best.

+/

unittest{ /// Example
    import mach.range.asrange : asrange;
    auto range = "hello".asrange;
    assert(range.length == 5);
    foreach(i; 0 .. range.length){
        range.popFront();
    }
    assert(range.empty);
    assert(range.length == 5); // Length doesn't change as a result of consumption!
}

/++ Docs

Any range with a `length` property should also override the `opDollar` operator
and, when implemented, the value of a range's `opDollar` must always be the
same as its `length` property.

+/

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof(1, 2, 3);
    assert(range[$-1] == 3);
}

/++ Docs

#### remaining

Many ranges support a `remaining` property which indicates the total number
of elements that have yet to be consumed before the range is empty.
Like `length`, `remaining` must be an integer and should very probably always
be of type `size_t`.

When the range has just been initialized, `range.remaining == range.length`.
When the range has been fully consumed, `range.remaining == 0`.

+/

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof(1, 2, 3);
    assert(range.remaining == 3);
    range.popFront();
    assert(range.remaining == 2);
    range.popBack();
    assert(range.remaining == 1);
    range.popFront();
    assert(range.remaining == 0);
    assert(range.empty);
}

/++ Docs

#### opIndex and opIndexAssign

Ranges may support random access reading and/or writing by overloading the
`opIndex` and `opIndexAssign` operators.
Though a range may overload these operators with various arguments specific to
that range type, a range is considered to have random access reading when
`range[some_non_negative_integer]` is valid and is considered to have random
access writing when `range[some_non_negative_integer] = value;` is valid and
when `range.mutable == true`. (The first condition should always imply the
second; anything else is an error in the implementation.)

Attempting to read or write a negative index of a random access range should not
be expected to be valid.
Attempting to read or write an index greater than or equal to a random access
range's length (if it has a `length` property) should not be expected to be
valid.
(Though a range type is not absolutely required to fulfill either of these
expectations.)

+/

unittest{ /// Examples
    import mach.traits : isRandomAccessRange;
    import mach.range.rangeof : rangeof;
    auto range = rangeof(0, 1, 2);
    static assert(isRandomAccessRange!(typeof(range)));
    assert(range[0] == 0);
    assert(range[1] == 1);
    assert(range[2] == 2);
    // Like many range types, those produced by `rangeof` throw a `IndexOutOfBoundsError`
    // when an index is out of bounds.
    import mach.error : mustthrow, IndexOutOfBoundsError;
    mustthrow!IndexOutOfBoundsError({
        auto nope = range[3]; // Index out of bounds!
    });
}

unittest{ /// Examples
    import mach.traits : isMutableRandomRange;
    import mach.range.asrange : asrange;
    auto array = [1, 2, 3];
    auto range = array.asrange;
    static assert(isMutableRandomRange!(typeof(range)));
    assert(range[0] == 1);
    range[0] = 100;
    assert(range[0] == 100);
    assert(array == [100, 2, 3]);
}

/++ Docs

#### opSlice

Ranges may support slicing via the `opSlice` operator overload.
Attempting to acquire a slice which begins at an index less than 0 or which
ends at an index greater than a range's `length` should not be expected to be
a valid operation.
(Though a range type is not absolutely required to behave according to this
expectation.)

Most slicing ranges, when sliced, return the same type as the range that was
sliced. (This behavior should be maintained everywhere possible.)
Some ranges, however, may return a different type when slicing because the
operator could not otherwise be supported.

Currently, a range is strictly considered to support slicing (as it pertains
to ranges created from other ranges inheriting such traits, or to templates
such as `isSlicingRange` evaluating true for a range type) only when the
type returned by slicing is the same as the type that is being sliced.
Whether to extend support for slices of differing types, and how such support
should be implemented, is a design decision that has not yet been made.
Range slicing may or may not assume a more lenient definition in the future.

+/

unittest{ /// Example
    import mach.traits : isSlicingRange;
    import mach.range.asrange : asrange;
    import mach.range.compare : equals;
    auto range = "hello world".asrange;
    static assert(isSlicingRange!(typeof(range)));
    assert(range[0 .. 5].equals("hello"));
    assert(range[6 .. $].equals("world"));
}

/++ Docs

#### Save

Ranges may provide a `save` property, which returns a range that occupies the
same state as the saved range, but whose state is not affected by consuming
that saved range. (And similarly, consuming the produced range does not affect
the state of the original, saved range.)

`save` must always return a value of the same type as the range being saved.

+/

unittest{ /// Example
    import mach.traits : isSavingRange;
    import mach.range.rangeof : rangeof;
    auto range = rangeof(1, 2, 3);
    static assert(isSavingRange!(typeof(range)));
    auto saved = range.save;
    assert(range.front == 1);
    assert(saved.front == 1);
    range.popFront();
    assert(range.front == 2);
    assert(saved.front == 1);
}

/++ Docs

Mutating the contents of a range for which a saved copy has been acquired, or
the contents of that saved copy where the original range is still being
operated upon, should be considered to invalidate the behavior of the range
for which the mutation did not take place.

And as with any mutable ranges with a backing data set, mutating the backing
data set may invalidate the original range — as well as any saved copies of
that range.

+/

unittest{ /// Example
    import mach.range.asrange : asrange;
    auto range = [1, 2, 3].asrange;
    auto saved = range.save;
    range.front = 2; // `saved` may no longer behave correctly!
    auto savedagain = range.save; // Ok...
    savedagain.back = 4; // `range` may no longer behave correctly!
}

/++ Docs

#### removeFront and removeBack

Some ranges may support a `removeFront` and/or a `removeBack` method;
these would generally be ranges which enumerate the contents of a backing
data set.
Calling these methods consumes the front or back element, respectively,
removes it from the range and the backing data set, and reduces the range's
`length` and `remaining` properties (when available) each by 1.

When either of these methods are implemented for a range, `range.mutable`
must be `true`.
Additionally, `removeBack` is only valid for ranges that also support `back`
and `popBack`.

+/

unittest{ /// Example
    import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
    import mach.range.compare : equals;
    import mach.collect : DoublyLinkedList;
    auto list = new DoublyLinkedList!int([1, 2, 3]);
    auto range = list.values; // Acquire a range for enumerating the list's contents.
    static assert(isMutableRemoveFrontRange!(typeof(range)));
    static assert(isMutableRemoveBackRange!(typeof(range)));
    assert(list.values.equals([1, 2, 3]));
    // Remove the front element,
    assert(range.front == 1);
    range.removeFront();
    assert(range.front == 2);
    assert(list.values.equals([2, 3]));
    // Remove the back element,
    assert(range.back == 3);
    range.removeBack();
    assert(range.back == 2);
    assert(list.values.equals([2]));
    // And now remove the final remaining element.
    range.removeFront();
    assert(range.empty);
    assert(list.empty);
}

public:

import mach.range.asarray : asarray;
import mach.range.asrange : asrange, asindexrange, aspointerrange;
import mach.range.associate : associate, aagroup, aadistribution;
import mach.range.asstaticarray : asstaticarray;
import mach.range.bytecontent : bytecontent, bytecontentle, bytecontentbe;
import mach.range.cache : cache;
import mach.range.cartpower : cartpower;
import mach.range.chain : chain, chainiter, chainiters;
import mach.range.chunk : chunk;
import mach.range.compare : compare, equals, iterequals, recursiveequals;
import mach.range.compareends : headis, tailis;
import mach.range.consume : consume, consumereverse;
import mach.range.contains : contains, containsiter, containselement;
import mach.range.count : count;
import mach.range.distinct : distinct;
import mach.range.each : each, eachreverse;
import mach.range.elementcount : elementcount;
import mach.range.ends : head, tail;
import mach.range.enumerate : enumerate;
import mach.range.fill : fill;
import mach.range.filter : filter;
import mach.range.find : find, findfirst, findlast, findall;
import mach.range.first : first, last;
import mach.range.flatten : flatten;
import mach.range.group : group, distribution;
import mach.range.include : include, exclude;
import mach.range.indexof : indexof, indexofiter, indexofelement;
import mach.range.interpolate : interpolate, lerp, coslerp;
import mach.range.intersperse : intersperse;
import mach.range.join : join;
import mach.range.logical : any, all, none;
import mach.range.map : map;
import mach.range.mutate : mutate;
import mach.range.next : next, nextfront, nextback;
import mach.range.ngrams : ngrams;
import mach.range.orderstrings : orderstrings;
import mach.range.pad : pad, padfront, padback, padfrontcount, padbackcount;
import mach.range.pluck : pluck;
import mach.range.random : lcong, mersenne, xorshift, shuffle;
import mach.range.rangeof : rangeof, infrangeof, finiterangeof;
import mach.range.recur : recur;
import mach.range.reduce : reduce, reduceeager, reducelazy;
import mach.range.reduction : sum, product;
import mach.range.repeat : repeat;
import mach.range.retro : retro;
import mach.range.rotate : rotate;
import mach.range.select : select, from, until;
import mach.range.sort;
import mach.range.split : split;
import mach.range.stride : stride;
import mach.range.strip : strip, stripfront, stripback, stripboth;
import mach.range.stripends : striphead, striptail;
import mach.range.tap : tap;
import mach.range.top : top, bottom;
import mach.range.unique : unique;
import mach.range.walk : walklength, walkindex, walkslice;
import mach.range.zip : zip;



alias lpad = padfront;
alias rpad = padback;
alias lstrip = stripfront;
alias rstrip = stripback;



private version(unittest){
    import mach.test;
    import mach.traits;
}
unittest{
    tests("Combinations of functions", {
        tests("retro, pad, aadistribution, count", {
            auto input = "hello world";
            auto rev = input.retro;
            test(rev.equals("dlrow olleh"));
            auto padded = rev.padfrontcount('_', 2);
            test(padded.equals("__dlrow olleh"));
            auto distro = padded.aadistribution;
            testeq(distro['h'], 1);
            testeq(distro['l'], 3);
            testeq(distro['o'], 2);
            testeq(distro['_'], 2);
            foreach(key, value; distro) testeq(padded.count(key), value);
        });
        tests("lerp, tap, sum", {
            real counter = 0;
            real summed = lerp(0, 1, 32).tap!((e){counter += e;}).sum;
            testeq(counter, 16.0);
            testeq(counter, summed);
        });
        tests("chain, tap, consume", {
            auto range = ["abc", "def", "", "ghi"].chain;
            string str = "";
            range.tap!((e){str ~= e;}).consume;
            test(str.equals("abcdefghi"));
        });
        tests("map, chain", {
            auto range = "abcdefghi\0".map!(ch => [ch, ch + 1]).chain;
            test(range.equals("abbccddeeffgghhiij\0\1"));
        });
    });
}




