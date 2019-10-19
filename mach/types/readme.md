# mach.types


This package implements several highly-generalized types intended for use
primarily with generalized algorithms and code.


## mach.types.keyvaluepair


This module defines the `KeyValuePair` type, which behaves similarly to a tuple
containing two elements, a key and a value.

``` D
auto pair = KeyValuePair!(string, int)("hello", 1);
assert(pair.key == "hello");
assert(pair.value == 1);
```


## mach.types.option


This module implements an Option type, sometimes called an Optional or Maybe type.
The implemented `Option` type contains either no value or one value.

``` D
auto option = Option!int(123);
assert(option.ok);
assert(!option.empty);
assert(option.value == 123);
```

``` D
// Accessing `option.value` would produce an assertion error
auto option = Option!int.None;
assert(!option.ok);
assert(option.empty);
// Get value with fallback
assert(option.get(900) == 900);
```


The module additionally provides the `None` and `Some` helpers, which
allow for more concise expressions related to creating `Option` objects.

``` D
auto option = Some("Hello world!");
assert(option.value == "Hello world!");
```

``` D
auto option = None!string;
assert(option.empty);
```


`Option` objects are valid as ranges, which means that you can use them
easily in combination with mach's range-related functions such as `filter`
or `map`.

``` D
auto range = Some(500).asrange;
foreach(i; range) {
    assert(i == 500);
}
```

``` D
auto range = None!int.asrange;
foreach(i; range) {
    assert(false); // Range is empty
}
```


## mach.types.rebindable


The `rebindable` function and `Rebindable` template can be used to acquire
a value stored in a type whose value can be rebound using assignments.
If the type is already rebindable, the value is itself returned when calling
`rebindable` and the template aliases to that input type in the case of
`Rebindable`.
If the type would be rebindable if a `const` or `immutable` qualifier were
removed,


## mach.types.refcounted


The `RefCounted` type can be used to acquire a reference-counted wrapper
type of another type, which calls a given function when the number of
living references becomes zero.

By default, the basis value's `free` method is called when the number of
references reaches zero.
However, this behavior can be changed by using a template argument when
defining the `RefCounted` type.

``` D
int freed = 0;
{
    // Create a reference-counted int type, which increments `freed` when refs hit zero.
    auto value = RefCounted!(int, i => freed++)(1);
    assert(value == 1); // Acts like an int!
    assert(value.references == 1);
    {
        auto anothervalue = value; // Another reference!
        assert(value.references == 2);
    }
    assert(value.references == 1); // No more second reference.
}
assert(freed == 1); // No more references, so the callback was evaluated.
```


## mach.types.ternary


This module provides an enumeration of
[ternary logic values](https://en.wikipedia.org/wiki/Three-valued_logic)
as well as a wrapper struct type with operator overloads implementing
common ternary logic operations.

The values for this module's ternary logic system are named
"true", "false", and "unknown".
They can be thought of as representing a certainly true state,
a certainly false state, and an uncertain or indeterminate state,
respectively.

``` D
// Using the TernaryValue enum directly
assert(TernaryValue.True is +1);
assert(TernaryValue.False is -1);
assert(TernaryValue.Unknown is 0);
```

``` D
// Using the Ternary type
assert((Ternary.True & Ternary.True).isTrue);
assert((Ternary.True & Ternary.False).isFalse);
assert((Ternary.True & Ternary.Unknown).isUnknown);
```


Here is a complete list of the operations implemented for the
Ternary struct and their truth tables.

Note that casting a Ternary value to a boolean is the same as
calling its `isTrue` method.

Unary operators `[T, U, F]`:

- Is true **x.isTrue** (returns a bool): `[T, F, F]`
- Is false **x.isFalse** (returns a bool): `[F, F, T]`
- Is unknown **x.isUnknown** (returns a bool): `[F, T, F]`
- Assume true **x.assumeTrue**: `[T, T, F]`
- Assume false **x.assumeFalse**: `[T, F, F]`
- Negation **x.negate**, **-x**: `[F, U, T]`

Binary operators `[T-T, T-U, T-F,  U-T, U-U, U-F,  F-T, F-U, F-F]`:

- Identity **x.identity(y)** `[T, F, F,  F, T, F,  F, F, T]`
- Equality **x.equals(y)**, **x == y** `[T, U, F,  U, U, U,  F, U, T]`
- Implication **x.implies(y)**, **x >> y** `[T, U, F,  T, U, U,  T, T, T]`
- Conjunction **x.and(y)**, **x & y** `[T, U, F,  U, U, F,  F, F, F]`
- Disjunction **x.or(y)**, **x | y** `[T, T, T,  T, U, U,  T, U, F]`
- Exclusive disjunction **x.xor(y)**, **x ^ y** `[F, U, T,  U, U, U,  T, U, F]`

``` D
// Identity (returning a boolean)
assert(Ternary.True.isTrue is true);
assert(Ternary.True.isFalse is false);
assert(Ternary.True.isUnknown is false);
// Assumption
assert(Ternary.Unknown.assumeTrue.isTrue);
assert(Ternary.Unknown.assumeFalse.isFalse);
// Negation
assert((-Ternary.False).isTrue);
assert(Ternary.False.negate.isTrue);
```

``` D
// Identity
assert(Ternary.True.identity(Ternary.False).isFalse);
// Equality
assert(Ternary.True.equals(Ternary.Unknown).isUnknown);
assert((Ternary.True == Ternary.Unknown).isUnknown);
// Implication
assert(Ternary.False.implies(Ternary.Unknown).isTrue);
assert((Ternary.False >> Ternary.Unknown).isTrue);
// Conjunction
assert(Ternary.False.and(Ternary.True).isFalse);
assert((Ternary.False & Ternary.True).isFalse);
// Disjunction
assert(Ternary.False.or(Ternary.True).isTrue);
assert((Ternary.False | Ternary.True).isTrue);
// Exclusive disjunction
assert(Ternary.Unknown.xor(Ternary.True).isUnknown);
assert((Ternary.Unknown ^ Ternary.True).isUnknown);
```


## mach.types.tuple


This module implements a tuple type which serves a fairly simple purpose of
holding any number of values of aribtrary types, but does so in such a way that
is accommodating to the language syntax.
Tuples overload various operators, can be indexed with compile-time bounds
checking, and can be passed to functions expecting as arguments the tuple's
constituent types by using `tuple.expand`.

`Tuple` is a template which can be used to acquire a struct representing a
tuple holding some given types, and `tuple` is a function which can be used
to acquire a tuple holding some given values.

``` D
// Reference a tuple type with `Tuple` or instantiate one with `tuple`.
Tuple!(string, char) tup = tuple("hello", '!');
static assert(tup.length == 2); /// Length is known at compile time.
assert(tup[0] == "hello");
assert(tup[1] == '!');
// Out-of-bounds indexes produce a compile error!
static assert(!is(typeof({tup[2];})));
```

``` D
// Unary operators are simply applied to every member of the tuple.
// They are only allowed when every member of the tuple supports the operator.
Tuple!(int, int) itup = tuple(1, 2);
Tuple!(float, float) ftup = cast(Tuple!(float, float)) itup;
assert(-itup == tuple(-1, -2));
assert(-itup == -ftup);
```

``` D
// Binary operators are applied to every pair of elements in tuples.
// They're only allowed when every pair of elements supports the operator.
auto tup = tuple(1, 2, 3);
assert(tup + tuple(4, 5, 6) == tuple(5, 7, 9));
assert(tup - tuple(1, 1, 1) == tuple(0, 1, 2));
```

``` D
// Tuples can be ordered if their corresponding pairs of elements can be ordered.
// The second elements are compared only if the first are equal, the third
// only if the second are equal, etc., in a manner similar to string sorting.
assert(tuple(0, 1) < tuple(1, 1));
assert(tuple(1, 1) > tuple(1, 0));
```


## mach.types.value


The `Value` struct simply wraps a single attribute of a specified type.
The `asValue` function may be used to obtain a `Value` from a given input.

``` D
Value!string x = asValue("hello");
assert(x.value == "hello");
```


