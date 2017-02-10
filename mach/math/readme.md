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


## mach.math.clamp


The `clamp` function can be used to ensure a value is within some bounds.

The function accepts three arguments.
When the first argument is less than the second, the second argument is returned.
When the first argument is greater than the third, the third is returned.
Otherwise, the first argument is returned.

``` D
assert(200.clamp(150, 250) == 200);
assert(100.clamp(150, 250) == 150);
assert(300.clamp(150, 250) == 250);
```


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
import mach.error.mustthrow : mustthrow;
mustthrow!MedianEmptyInputError({
    new int[0].median; // Can't calculate median with an empty input!
});
```


## mach.math.normalizescalar


The `normalizescalar` function can be used to convert an integer to a float
in the range [-1, 1] (when signed) or [0, 1] (when unsigned).
The `denormalizescalar` goes in the opposite direction and converts a float
in the range [-1, 1] (for signed types) or [0, 1] (for unsigned) to an integral.
For signed integers, -1.0 corresponds to `T.min`, 0.0 to `T(0)`, and +1.0 to `T.max`.
For unsigned integers, 0.0 corresponds to `T(0)` and +1.0 to `T.max`.

``` D
assert(normalizescalar(int.max) == 1.0);
assert(normalizescalar(int.min) == -1.0);
assert(denormalizescalar!int(1.0) == int.max);
assert(denormalizescalar!int(-1.0) == int.min);
```


## mach.math.numrange


The `NumberRange` type represents some range of numbers spanning an inclusive
lower bound and an exclusive higher bound.
The `numrange` function can be used for convenience to acquire a `NumberRange`
from arguments without having to explicitly specify their type.

``` D
auto range = numrange(0, 10);
assert(range.low == 0);
assert(range.high == 10);
```


Ranges are not required to be normalized, and may have their low bound be
greater than their high bound.
In cases like this, the `lower` and `higher` methods can be used to reliably
acquire the actually lower and higher bounds.

``` D
auto range = numrange(10, 0);
assert(range.low == 10);
assert(range.high == 0);
assert(range.lower == 0);
assert(range.higher == 10);
assert(range.alignment is range.Alignment.Inverted);
```


The `NumberRange` type implements a `length` method to get the positive
difference between its low and high bounds and a `delta` method to get a signed
difference of `high - low`.
Its `overlaps` method can be used to determine whether one range overlaps
another and `contains` used to determine whether one range entirely contains
another.
`contains` also accepts a number, and determines whether that number is within
the range's bounds.

The `contains` method is alternatively accessible via the `in` operator.

``` D
auto range = numrange(10, 15);
assert(range.delta == 5);
assert(range.length == 5);
assert(range.overlaps(numrange(0, 20)));
assert(numrange(11, 12) in range);
assert(13 in range);
assert(200 !in range);
```


A range (as in, an iterable type) can be acquired from a `NumberRange` via
its `asrange` method.
Ranges constructed from integral types allow `asrange` to be called without
arguments, and the produced range enumerates the integers in the `NumberRange`.
In all cases a step may be provided, and for non-integral types is not optional,
determining what the difference between enumerated values should be.
The first value of a range produced via `asrange` will always be the lower bound
of the `NumberRange` and the last value will always be less than the higher
bound.

Note that a range produced from a `NumberRange` will always progress from
lesser to greater numbers, regardless of whether the `NumberRange` was normal
or inverted.

``` D
import mach.range.compare : equals;
assert(numrange(0, 8).asrange.equals([0, 1, 2, 3, 4, 5, 6, 7])); // Implicit step
assert(numrange(0, 8).asrange(3).equals([0, 3, 6])); // Explicit step
```


## mach.math.polynomial


The `polynomial` function accepts a value and an array of coefficients as
input, and calculates `c[0] * x^0 + c[1] * x^1 + c[2] * x^2 + ...` where
coefficients following the last element of the passed coefficients array
are zero.

In this computation `x` must be passed as a runtime argument, but the array
of coefficients may be passed as either a runtime or a template argument.

``` D
// Coefficients passed as a runtime argument
assert(polynomial(2, [1, 2, 3]) == 17); // (1 * 2^0) + (2 * 2^1) + (3 * 2^2)
// Coefficients passed as a template argument
assert(polynomial!([3, 2, 1])(3) == 18); // (3 * 3^0) + (2 * 3^1) + (1 * 3^2)
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


## mach.math.sign


The `signof` function can be used to acquire the sign of a numeric input as
a member of the `Sign` enum, whose members are `Sign.Positive`, `Sign.Negative`,
and `Sign.Zero`.

``` D
assert(signof(1) is Sign.Positive);
assert(signof(-1) is Sign.Negative);
assert(signof(0) is Sign.Zero);
```


## mach.math.sqrt


This module defines the `sqrt` and `isqrt` functions.

`sqrt` may be used to determine the square root of any numeric, imaginary, or
complex input.
When pasing an integer or float to `sqrt`, the return type is a float.
Negative inputs produce a NaN output. Infinity produces an infinite output.
When passing an imaginary or complex number to `sqrt`, the return type is a
complex number.

``` D
assert(sqrt(4) == 2);
assert(sqrt(256) == 16);
```


The `isqrt` function is an optimized equivalent to calling `floor(sqrt(abs(i)))`
for some integer input.
Its return type is the same as its input type.

``` D
assert(isqrt(4) == 2);
assert(isqrt(15) == 3);
```


## mach.math.trig


This package implements or otherwise exposes various trigonometric functions.


