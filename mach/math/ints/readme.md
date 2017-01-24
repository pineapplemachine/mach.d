# mach.math.ints


This package provides functions for performing operations upon integral types.


## mach.math.ints.intcmp


This module provides functions for comparing integer primitives where one
type may be signed and another unsigned.
(When this is the case, comparison may fail because of unsigned coercion.)

The function `intgt` returns true when `a > b`, `intgte` when `a >= b`,
`intlt` when `a < b`, `intlte` when `a <= b`, and `inteq` when `a == b`.

``` D
// This happens because the `int` is coerced to a `uint` before comparing.
assert(int(-1) > uint(0));
```

``` D
// These functions do not suffer from the same limitation.
assert(intgt(uint(0), int(-1)));
assert(intgte(uint(0), int(-1)));
assert(intlt(int(-1), uint(0)));
assert(intlte(int(-1), uint(0)));
```


## mach.math.ints.intproduct


The `intproduct` function can be used to multiply two unsigned integer values
without loss due to overflow, and without the use of a larger integer type
for storing the final or any intermediate value.

``` D
auto product = intproduct(2, uint.max);
assert(product.low == (2 * uint.max));
assert(product.high == 1);
```


For convenience, when there is a larger integer type that can accommodate both
the high and low bits recorded in the type returned by `intproduct`,
the value of that returned type may be directly compared to that value.

``` D
assert(intproduct(uint.max, uint.max) == (cast(ulong) uint.max * cast(ulong) uint.max));
```


The `intproductoverflow` function can be used to get the product of two integers
and whether the operation caused overflow, without computing the carried value.
It returns a type with an integer `value` attribute storing the result of
multiplication and a boolean `overflow` attribute indicating whether the
operation resulted in integer overflow.

``` D
auto result = intproductoverflow(2, int.max);
assert(result.value == 2 * int.max);
assert(result.overflow);
```


