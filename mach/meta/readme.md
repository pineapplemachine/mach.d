# mach.meta


This package primarily contains templates useful for doing operations at
compile time.


## mach.meta.adjoin


The `Adjoin` template generates a function from several input functions,
where the return value of the generated function is a tuple containing each
value returned by the adjoined functions.

``` D
alias fn = Adjoin!(e => e - 1, e => e + 1);
auto result = fn(0);
assert(result[0] == -1);
assert(result[1] == 1);
```


A function generated using Adjoin will return a tuple unconditionally, even
when adjoining only one function.

The module also defines an `AdjoinFlat` template, which produces the same
behavior as `Adjoin` except for the case where its input is a single function.
In that case, the template is aliased to that function and does not wrap the
output in a tuple, as `Adjoin` would.

``` D
alias fn = AdjoinFlat!(e => e - 1);
assert(fn(0) == -1); // Output is the same as the passed function
```

``` D
alias fn = AdjoinFlat!(e => e - 1, e => e + 1);
assert(fn(0).length == 2); // Output is a tuple
```


## mach.meta.aliases


The `Alias` template can be used to generate an alias to a specific value,
even ones that could not be aliased using `alias x = y;` because `y` is a value
but not a symbol.

``` D
alias intalias = Alias!int;
static assert(is(intalias == int));
```

``` D
alias zero = Alias!0;
static assert(zero == 0);
```


The `Aliases` template can be used to produce an alias for a sequence of values.

``` D
alias seq = Aliases!(0, 1, void);
static assert(seq[0] == 0);
static assert(seq[1] == 1);
static assert(is(seq[2] == void));
```

``` D
alias emptyseq = Aliases!();
static assert(emptyseq.length == 0);
```

``` D
alias ints = Aliases!(int, int, int);
static assert(ints.length == 3);
auto fn0(int, int, int){}
static assert(is(typeof({fn0(ints.init);})));
auto fn1(ints){}
static assert(is(typeof({fn1(ints.init);})));
```


## mach.meta.filter


Given a sequence of values, `Filter` generates a new sequence containing
only those values which meet a predicate.

The first template argument must be a predicate,
and subsequent arguments constitute the sequence to be filtered.

``` D
enum bool NotVoid(T) = !is(T == void);
static assert(is(Filter!(NotVoid, void, int, void, long) == Aliases!(int, long)));
```

``` D
enum bool isInt(T) = is(T == int);
static assert(is(Filter!(isInt, double, float, long) == Aliases!()));
```


## mach.meta.logical


The `Any`, `All`, and `None` templates evaluate whether a predicate,
described by the first template argument, evaluates true for any of the
subsequent template arguments.

``` D
enum isInt(T) = is(T == int);
static assert(Any!(isInt, void, int));
static assert(!Any!(isInt, void, void));
```

``` D
enum isLong(T) = is(T == long);
static assert(All!(isLong, long, long));
static assert(!All!(isLong, long, void));
```

``` D
enum isDouble(T) = is(T == double);
static assert(None!(isDouble, void, void));
static assert(!None!(isDouble, void, double));
```


The `First` and `Last` templates can be used to find the first or the last
item in their template arguments matching a predicate, respectively.
The first argument represents the predicate, and subsequent arguments
represent the sequence to be searched in.

These templates produce compile errors when the sequence contains no value
meeting the predicate.

``` D
enum isNum(T) = is(T == int) || is(T == long);
static assert(is(First!(isNum, void, int, long) == int));
static assert(is(Last!(isNum, void, int, long) == long));
```

``` D
enum isNum(T) = is(T == int) || is(T == long);
static assert(!is(typeof({
    // Fails to compile because no arguments satisfy the predicate.
    alias T = First!(isNum, void, void, void);
})));
```


The `Count` template determines the number of elements meeting a predicate.
The first argument represents the predicate, and subsequent arguments
represent the sequence to be searched in.

``` D
enum isChar(T) = is(T == char);
static assert(Count!(isChar, char, void, char) == 2);
static assert(Count!(isChar, void) == 0);
```


## mach.meta.map


Implements the
[map higher-order function](https://en.wikipedia.org/wiki/Map_(higher-order_function))
for template arguments.
The first template argument to `Map` represents a transformation function, which
is applied to the sequence represented by the subsequent template arguments.

``` D
enum AddOne(alias n) = n + 1;
alias added = Map!(AddOne, 3, 2, 1);
static assert(added.length == 3);
static assert(added[0] == 4);
static assert(added[1] == 3);
static assert(added[2] == 2);
```


## mach.meta.numericseq


The `NumericSequence` template accepts a `low` argument, a `high` argument,
and an optional `increment` argument. `low` must be less than or equal to `high`,
and `increment` must be greater than zero. A sequence is produced by adding
`increment` to `low` in steps until `high` is met or exceeded.

``` D
// Increment by 1 from 0 until 3
alias seq = NumericSequence!(0, 3);
static assert(seq.length == 3);
static assert(seq[0] == 0);
static assert(seq[1] == 1);
static assert(seq[2] == 2);
```

``` D
// Increment by 2 from 0 until 6
alias seq = NumericSequence!(0, 6, 2);
static assert(seq.length == 3);
static assert(seq[0] == 0);
static assert(seq[1] == 2);
static assert(seq[2] == 4);
```


## mach.meta.predicates


Provides templates which apply logical operations to predicate functions.

`NegatePredicate` produces a predicate which is a logical negation of the input.
`AndPredicates` produces a predicate which is only satisfied when all of its
inputs are satisfied.
`OrPredicates` produces a predicate which is satisfied when anu of its
inputs are satisfied.

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


Provides an implementation of the
[reduce higher-order function](https://en.wikipedia.org/wiki/Fold_(higher-order_function)),
operating upon a sequence of template arguments.

The first argument of the `Reduce` template is an accumulation function,
and it is applied sequentially to the following template arguments.

``` D
enum sum(alias a, alias b) = a + b;
static assert(Reduce!(sum, 1, 2, 3, 4) == 10);
```

``` D
enum max(alias a, alias b) = a > b ? a : b;
static assert(Reduce!(max, 0, 1, 7, 3) == 7);
```

``` D
template larger(a, b){
    static if(a.sizeof > b.sizeof) alias larger = a;
    else alias larger = b;
}
static assert(is(Reduce!(larger, short, byte, long, int) == long));
```


## mach.meta.repeat


Given a value or sequence of values, the `Repeat` template will generate a
new sequence which is the original sequence repeated and concatenated a given
number of times.

The first argument indicates a number of times to repeat the sequence
represented by the subsequent arguments.

``` D
static assert(is(Repeat!(3, int) == Aliases!(int, int, int)));
static assert(is(Repeat!(2, int, void) == Aliases!(int, void, int, void)));
```


## mach.meta.retro


Given a sequence of template arguments, the `Retro` template will generate a
new sequence which is the original sequence in reverse order.

``` D
static assert(is(Retro!(byte, short, int) == Aliases!(int, short, byte)));
```

``` D
static assert(is(Retro!(int) == Aliases!(int)));
```


## mach.meta.select


This module provides a `Select` template, which aliases itself to the argument
at an index. The first argument represents the zero-based index to select from
in the sequence represented by the subsequent arguments.

``` D
static assert(is(Select!(0, short, int, long) == short));
static assert(is(Select!(1, short, int, long) == int));
static assert(is(Select!(2, short, int, long) == long));
```

``` D
static assert(!is(typeof(
    // Index out of bounds produces a compile error.
    Select!(3, short, int, long))
));
```


## mach.meta.varfilter


Provides an implementation of the
[filter higher-order function](https://en.wikipedia.org/wiki/Filter_(higher-order_function)),
operating upon a sequence of variadic arguments.

Given a sequence of variadic arguments, `varfilter` will return a tuple
containing only those arguments whose types meet a template predicate.

``` D
enum NotInt(T) = !is(T == int);
auto values = varfilter!NotInt(byte(1), short(2), int(3), "hi");
static assert(values.length == 3);
assert(values[0] == 1);
assert(values[1] == 2);
assert(values[2] == "hi");
```


## mach.meta.varlogical


This module implements the `varany`, `varall`, and `varnone` functions,
which perform logical operations upon their variadic arguments.

Each function accepts an optional predicate function; by default,
arguments are themselves evaluated for truthiness or falsiness.

``` D
assert(varany(false, true));
assert(!varany(false, false));
```

``` D
assert(varall(true, true));
assert(!varall(true, false));
```

``` D
assert(varnone(false, false));
assert(!varnone(false, true));
```

``` D
alias even = (n) => (n % 2 == 0);
assert(varany!even(1, 2, 3));
assert(!varall!even(1, 2, 3));
assert(!varnone!even(1, 2, 3));
```


## mach.meta.varmap


Performs the
[map higher-order function](https://en.wikipedia.org/wiki/Map_(higher-order_function))
for inputs passed as a sequence of variadic arguments.

Given a sequence of variadic arguments, `varmap` returns a tuple containing the
result of each argument being transformed by a passed function.

``` D
assert(varmap!(e => e + 1)(0, 1, 2) == tuple(1, 2, 3));
```


The module also provides a `varmapi` function, which passes the zero-based
index of the argument being mapped to the transformation function,
in addition to the element being transformed.

``` D
alias func = (index, element) => (index + element);
assert(varmapi!func(1, 1, 1) == tuple(1, 2, 3));
```


## mach.meta.varreduce


Provides an implementation of the
[reduce higher-order function](https://en.wikipedia.org/wiki/Fold_(higher-order_function)),
operating upon a sequence of variadic arguments.

The reduction operation can be given a seed by prepending the seed as an
additional argument.

``` D
alias summod2 = (a, b) => (a + (b % 2));
assert(varreduce!summod2(0, 1, 2, 3) == 2);
```


The module also provides some common abstractions of the reduce function.

``` D
assert(varmin(1, 2, 3) == 1); // Minimum
assert(varmax(1, 2, 3) == 3); // Maximum
```

``` D
assert(varsum(1, 2, 3, 4) == 10); // Sum
assert(varproduct(1, 2, 3, 4) == 24); // Product
```


## mach.meta.varselect


The `varselect` function accepts a number as a template argument and at least
one runtime argument.
It returns the argument at the zero-based index indicated by its template argument.
Because the arguments are lazily-evaluated, only the selected argument will
actually be evaluated.

The function will not compile if the index given is outside the bounds of the
argument list.

``` D
assert(varselect!0(0, 1, 2) == 0);
assert(varselect!2(0, 1, 2) == 2);
```

``` D
static assert(!is(typeof({
    varselect!10(0, 1, 2); // Index out of bounds
})));
```


