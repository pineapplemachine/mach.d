# mach.math


This package provides functions for performing operations upon numeric types.


## mach.math.abs


This module implements the `abs` function, as well as a `uabs` function.

`abs` can be applied to any numeric or imaginary primitive. When its input
is positive, it returns its input. When its input is negative, it returns the
negation of its input.
The output will always be the same numeric type as the input.

``` D
assert(abs(10) == 10);
assert(abs(-20) == 20);
```

``` D
// `abs` accepts imaginary inputs.
assert(abs(10i) == 10i);
assert(abs(-20i) == 20i);
```

``` D
// This module guarantees that `abs(-float.nan)` is always `+float.nan`.
import mach.math.floats : fextractsgn, fisnan;
assert(abs(-float.nan).fisnan); // Is nan?
assert(abs(-float.nan).fextractsgn == false); // Is positive nan?
```


The functionally similar `uabs` applies only to integral types,
and always returns an unsigned integer.
The `uabs` function exists because signed numeric primitives are not able
to correctly store the absolute value of their smallest representable value.
Their unsigned counterparts, however, are subject to no such limitation.

``` D
assert(abs(int.min) < 0); // This is a limitation of the `int` type!
assert(uabs(int.min) > 0); // Which `uabs` is not affected by.
```


## mach.math.bits


This package provides functionality for bit manipulation.
Perhaps most notably, `extractbit` and `extractbits`, and `injectbit` and
`injectbits`, which can be used to read and write specific bits in a value.


## mach.math.constants


This module defines some mathematical constants, including `e`, `pi`, `tau`,
`sqrt2`, and `GoldenRatio`.


## mach.math.floats


This package provides functions for the manipulation of floating point
primitives.


## mach.math.ints


This package provides functions for performing operations upon integral types.


## mach.math.mean


This module implements the `mean` function, which accepts an iterable of
numeric primitives and calculates the arithmetic mean of those values.

``` D
assert([5, 10, 15].mean == 10);
assert([0.25, 0.5, 0.75, 1.0].mean == 0.625);
```


When not compiled in release mode, `mean` throws a `MeanEmptyInputError` when
the input iterable was empty. In release mode, this error reporting is omitted.

``` D
import mach.error.mustthrow : mustthrow;
mustthrow!MeanEmptyInputError({
    new int[0].mean; // Can't calculate mean with an empty input!
});
```


`mean` can also be called with two numeric inputs, and will determine their
average without errors related to overflow or truncation of integers.

``` D
assert(mean(int.max, int.max - 10) == int.max - 5);
```


## mach.math.median


The `median` function calculates the [median](https://en.wikipedia.org/wiki/Median)
of the values in an input iterable. The input must be finite and not empty.
If the input is empty, then in release mode `median` will throw a
`MedianEmptyInputError`.
(When not compiling in release mode, the check necessary to report the error
is omitted.)

``` D
assert([1, 2, 3, 4, 5].median == 3);
assert([5, 2, 4, 1].median == 3);
```

``` D
mustthrow!MedianEmptyInputError({
    new int[0].median; // Can't calculate median with an empty input!
});
```


## mach.math.round


The `round`, `floor`, and `ceil` functions can be used to round a value to
near integers.
The `round` function rounds to the nearest integer, and rounds up when the
fractional part exactly equals 0.5.
The `floor` function rounds down to the nearest integer,
and the `ceil` function rounds up to the nearest integer.

Though these functions are implemented for all numeric primitives, note that
when their inputs are integers they will always return the input itself.
Actual computation really only happens when the input is a floating point value.

``` D
assert(floor(100) == 100);
assert(floor(200.5) == 200);
assert(floor(-200.5) == -201);
```

``` D
assert(ceil(100) == 100);
assert(ceil(200.5) == 201);
assert(ceil(-200.5) == -200);
```

``` D
assert(round(100) == 100);
assert(round(200.25) == 200);
assert(round(200.75) == 201);
assert(round(-200.25) == -200);
assert(round(-200.75) == -201);
```


