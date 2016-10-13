# mach.meta

This package primarily contains templates useful for doing operations at compile time.

## mach.meta.adjoin

Adjoin can be used to generate a function from several different functions, where the returned value is a tuple containing each value returned from the adjoined functions.

``` D
alias fn = Adjoin!(e => e - 1, e => e + 1);
auto result = fn(0);
assert(result[0] == -1);
assert(result[1] == 1);
```

A function generated using Adjoin will return a tuple unconditionally, even when adjoining only one function.

To return a single untampered-with value when adjoining only a single function, use AdjoinFlat instead. In the case that a single function is passed to it, it will alias itself to that function. In all other cases, it evaluates the same as Adjoin.

``` D
alias astuple = Adjoin!(e => e);
assert(astuple(0)[0] == 0);
alias flat = AdjoinFlat!(e => e);
assert(flat(0) == 0);
```

## mach.meta.aliases

Provides templates that can be used to generate an alias referring to some value or sequence of values.

There is Alias for generating an alias to a single specific value, even values that cannot be aliased using `alias x = y;` syntax.

``` D
alias intalias = Alias!int;
static assert(is(intalias == int));
alias zero = Alias!0;
static assert(zero == 0);
```

And there is Aliases for generating an alias to a sequence of values.

``` D
alias ints = Aliases!(int, int, int);
static assert(ints.length == 3);
auto fn0(int, int, int){}
static assert(is(typeof({fn0(ints.init);})));
auto fn1(ints){}
static assert(is(typeof({fn1(ints.init);})));
```

## mach.meta.contains

Given at least one argument, determines whether the first argument is equivalent to any of the subsequent arguments.

``` D
static assert(Contains!(int, byte, short, int));
static assert(!Contains!(int, void, void, void));
```

This can be more intuitively expressed as:

``` D
alias nums = Aliases!(byte, short, int);
alias voids = Aliases!(void, void, void);
static assert(Contains!(int, nums));
static assert(!Contains!(int, voids));
```

## mach.meta.filter

Given a sequence of values, generate a new sequence containing only those values which meet a predicate.

``` D
enum bool NotVoid(T) = !is(T == void);
static assert(is(Filter!(NotVoid, void, void, int, void, long) == Aliases!(int, long)));
```

## mach.meta.indexof

``` D
// TODO: Document
```

## mach.meta.logical

``` D
// TODO: Document
```

## mach.meta.map

``` D
// TODO: Document
```

## mach.meta.predicates

Apply logical operations to predicate functions.

``` D
alias pred = (x) => (x == 0);
assert(pred(0));
assert(!pred(1));
assert(NegatePredicate!pred(1));
assert(!NegatePredicate!pred(0));
```

``` D
alias a = (x) => (x != 1);
alias b = (x) => (x != 2);
assert(AndPredicates!(a, b)(0));
assert(!AndPredicates!(a, b)(1));
assert(!AndPredicates!(a, b)(2));
```

``` D
alias a = (x) => (x == 1);
alias b = (x) => (x == 2);
assert(OrPredicates!(a, b)(1));
assert(OrPredicates!(a, b)(2));
assert(!OrPredicates!(a, b)(3));
```

## mach.meta.reduce

Implements the reduce higher-order function for template arguments.

``` D
template greater(alias a, alias b){
    enum greater = a > b ? a : b;
}
static assert(Reduce!(greater, 0, 4, 1, 7, 3) == 7);
```

``` D
template larger(a, b){
    static if(a.sizeof > b.sizeof) alias larger = a;
    else alias larger = b;
}
static assert(is(Reduce!(larger, short, byte, long, int) == long));
```

## mach.meta.repeat

Given a value or sequence of values, generate a new sequence which is the original sequence repeated and concatenated some number of times.

``` D
static assert(is(Repeat!(3, int) == Aliases!(int, int, int)));
static assert(is(Repeat!(2, int, void) == Aliases!(int, void, int, void)));
```

## mach.meta.retro

Given a sequence of values, generate a new sequence which is the same as the original but in reverse order.

``` D
static assert(is(Retro!(byte, short, int) == Aliases!(int, short, byte)));
```

## mach.meta.varfilter

Given a sequence of variadic arguments, return a tuple containing only those arguments whose types meet a template predicate.

``` D
enum NotInt(T) = !is(T == int);
auto values = varfilter!NotInt(byte(1), short(2), int(3), "hi");
static assert(values.length == 3);
assert(values[0] == 1);
assert(values[1] == 2);
assert(values[2] == "hi");
```

## mach.meta.varmap

Given a sequence of variadic arguments, return a tuple containing the result of each argument being transformed by a passed function.

``` D
auto mapped = varmap!(e => e * e)(0, 1, 2, 3);
static assert(mapped.length == 4);
assert(mapped[0] == 0);
assert(mapped[$-1] == 9);
auto fn(int, int, int, int){}
static assert(is(typeof({fn(mapped.expand);})));
```

## mach.meta.varreduce

Provides an implementation of the reduce HOF, operating upon a sequence of variadic arguments.

The reduction operation can be given a seed by prepending the seed as an additional argument.

``` D
alias sum = (a, b) => (a + b);
assert(varreduce!sum(1, 2, 3) == 6);
```

This module provides several common abstractions built on top of varreduce, including varmin, varmax, varany, varall, and varsum.

``` D
assert(varmin(1, 2, 3) == 1);
assert(varmax(1, 2, 3) == 3);
assert(varsum(1, 2, 3) == 6);
assert(varany(true, false));
assert(varall(true, true));
assert(varnone(false, false));
```
