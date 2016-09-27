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

Provides functions that can be used to generate an alias referring to some value or sequence of values.

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

Given at least one argument, determine whether the first argument is equivalent to any of the subsequent arguments.

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
// TODO
```

## mach.meta.logical

``` D
// TODO
```

## mach.meta.map

``` D
// TODO
```

## mach.meta.partial

``` D
// TODO
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

``` D
// TODO
```

## mach.meta.varmap

A map function returning a tuple containing the results of transformation of each passed argument.

``` D
auto mapped = varmap!(e => e * e)(0, 1, 2, 3);
static assert(mapped.length == 4);
assert(mapped[0] == 0);
assert(mapped[$-1] == 9);
auto fn(int, int, int, int){}
static assert(is(typeof({fn(mapped.expand);})));
```

## mach.meta.varreduce

``` D
// TODO
```
