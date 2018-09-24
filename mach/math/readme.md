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


## mach.math.collatz


The `collatzseq` function returns a range which enumerates the values in the
[Collatz sequence](https://en.wikipedia.org/wiki/Collatz_conjecture) of an input.

``` D
import mach.range.compare : equals;
assert(collatzseq(3).equals([3, 10, 5, 16, 8, 4, 2, 1]));
```


## mach.math.constants


This module defines some mathematical constants, including `e`, `pi`, `tau`,
`sqrt2`, and `GoldenRatio`.


## mach.math.floats


This package provides functions for the manipulation of floating point
primitives.


## mach.math.ints


This package provides functions for performing operations upon integral types.


## mach.math.lcm


This module makes available the `gcd` and `lcm` functions for determining the
greatest common divisor and least common multiple of two numbers, respectively.
When both inputs to `gcd` are 0, 0 is returned. When any input to `lcm` is 0,
0 is returned. In all other cases (except, potentially, for overflow in the case
of least common multiple) the outputs of `gcd` and `lcm` are positive integers.

``` D
// The greatest common divisor of 100 and 24 is 4.
assert(gcd(100, 24) == 4);
// The least common multiple of 100 and 24 is 600.
assert(lcm(100, 24) == 600);
```


## mach.math.matrix


The `Matrix` template type represents a [matrix]
(https://en.wikipedia.org/wiki/Matrix_(mathematics)) with arbitrary
dimensionality and any signed numeric primitive type for its components.
It is represented as a tuple of column Vectors.

Several convenience symbols are defined including `Matrix2i` and `Matrix2f`,
`Matrix3i` and `Matrix3f`, and `Matrix4i` and `Matrix4f`, referring to square
matrixes of different dimensionalities with either integral or floating point
component types.
It is recommended to use their `Rows` and `Cols` static methods to initialize
matrixes because they are maximally explicit in the structure of its arguments.
Note that Matrix constructors behave similarly to calling `Cols` with various
argument types.

The `matrix`, `matrixrows`, and `matrixcols` functions are also defined for
concisely initializing matrixes. Any time that it is not otherwise specified,
values are interpreted as columns first, rows second, e.g. the inputs
`1, 2, 3, 4` would produce a matrix where `2` is at X coordinate 0 and Y
coordinate 1, and `3` at X coordinate 1 and Y coordinate 0.
This differs from rows first, columns second where the same inputs `1, 2, 3, 4`
would product a matrix where `2` is at X coordinate 1 and Y coordinate 0,
and `3` at X coordinate 0 and Y coordinate 1.
Functions which accept a flat series of values can alternatively accept a series
of row or column vectors.

``` D
auto mat = Matrix3i.Rows(
    1, 2, 3,
    4, 5, 6,
    7, 8, 9,
);
assert(mat[0][0] == 1); // Column 0, row 0
assert(mat[2][0] == 3); // Column 2, row 0
assert(mat[0][2] == 7); // Column 0, row 2
assert(mat[2][2] == 9); // Column 2, row 2
```

``` D
auto mat = Matrix3i.Cols(
    1, 2, 3,
    4, 5, 6,
    7, 8, 9,
);
assert(mat[0][0] == 1);
assert(mat[2][0] == 7);
assert(mat[0][2] == 3);
assert(mat[2][2] == 9);
```


The individual components of a matrix may be accessed using indexes known at
compile time via the `matrix[x][y]` syntax or, alternatively, `matrix.index!(x, y)`.
If indexes are known only at runtime, `matrix.index(x, y)` may be used.

Attempting to access an out-of-bounds index with compile time values will
result in a compile error. Attempting to do so with runtime values will cause
an `IndexOutOfBoundsError` to be thrown.

``` D
import mach.math.vector : vector;
import mach.test.assertthrows : assertthrows;
auto mat = Matrix2i.Rows(
    vector(1, 2),
    vector(3, 4),
);
// Accessing legal indexes
assert(mat[0][0] == 1);
assert(mat.index!(1, 1) == 4);
assert(mat.index(1, 0) == 2);
// Accessing out-of-bounds indexes
static assert(!is(typeof({
    mat[100][100];
})));
assertthrows({
    auto x = mat.index(200, 200);
});
```


Matrixes may be compared for equality using the `==` operator, or with the
`equals` method which accepts an optional per-component epsilon.

``` D
assert(Matrix2i(1, 2, 3, 4) == Matrix2f(1, 2, 3, 4));
assert(Matrix2f(5, 6, 7, 8).equals(Matrix2f(5, 6, 7, 8)));
assert(Matrix2f(5, 6, 7, 8).equals(Matrix2f(5, 6, 7, 8 + 1e-16), 1e-8));
```


The rows and columns of a matrix may be accessed and modified using the
`row`, `col`, `rows`, and `cols` methods.
`row` and `col` return vectors and `rows` and `cols` return tuples of vectors.
The vectors returned by `row` and `rows` have a number of components equal to
the width of the matrix, and those returned by `col` and `cols` have a number
of components equal to its height.

``` D
auto mat = Matrix3i.Rows(
    vector(1, 2, 3),
    vector(4, 5, 6),
    vector(7, 8, 9),
);
// Get the row at an index
assert(mat.row!0 == vector(1, 2, 3));
// Get the column at an index
assert(mat.col!0 == vector(1, 4, 7));
// Get a tuple of row vectors
auto rows = mat.rows;
static assert(rows.length == mat.height);
assert(rows[1] == vector(4, 5, 6));
// Get a tuple of column vectors
auto cols = mat.cols;
static assert(cols.length == mat.width);
assert(cols[1] == vector(2, 5, 8));
```


A matrix can be multiplied by another matrix or by a column vector using the `*`
operator.
Other matrix binary operators are component-wise, meaning that the operation is
applied to each pair of corresponding components. For component-wise
multiplication as opposed to normal matrix multiplication, the `matrix.scale`
method may be used.

Matrixes also support component-wise binary operations with numbers.

``` D
auto a = Matrix2i.Rows(
    1, 2,
    3, 4,
);
auto b = Matrix2i.Rows(
    5, 6,
    7, 8,
);
// Matrix multiplication
assert(a * b == Matrix2i.Rows(
    19, 22,
    43, 50
));
// Component-wise addition
assert(a + b == Matrix2i.Rows(
    6, 8,
    10, 12,
));
// Component-wise multiplication
assert(a.scale(b) == Matrix2i.Rows(
    5, 12,
    21, 32,
));
```

``` D
import mach.math.vector : Vector2i;
auto a = Matrix2i.Rows(
    1, 2,
    3, 4,
);
auto b = Vector2i(5, 6);
assert(a * b == Vector2i(17, 39));
```

``` D
auto mat = Matrix2i.Rows(
    1, 2,
    3, 4,
);
assert(mat * 3 == Matrix2i.Rows(
    3, 6,
    9, 12,
));
assert(mat + 1 == Matrix2i.Rows(
    2, 3,
    4, 5,
));
```


Matrixes also provide utilities where applicable for finding their [determinant]
(https://en.wikipedia.org/wiki/Determinant), a [minor matrix]
(https://en.wikipedia.org/wiki/Minor_(linear_algebra)), the [cofactor matrix]
(https://en.wikipedia.org/wiki/Minor_(linear_algebra)#Inverse_of_a_matrix),
the [adjugate or adjoint](https://en.wikipedia.org/wiki/Adjugate_matrix),
the [transpose](https://en.wikipedia.org/wiki/Transpose), and the [inverse]
(https://en.wikipedia.org/wiki/Invertible_matrix).

Additionally, methods such as `flip`, `scroll`, and `rotate` can be used to
perform simple transformations on the positions of elements in a matrix.

``` D
auto mat = Matrix2f.Rows(
    vector(1, 2),
    vector(3, 4),
);
// Get the determinant
assert(mat.determinant == -2);
// Get a minor matrix, i.e. a matrix with a column and row omitted.
assert(mat.minor!(0, 0) == matrixrows(vector(4)));
// Transpose the matrix
assert(mat.transpose == matrixrows(
    vector(1, 3),
    vector(2, 4),
));
// Get the cofactor matrix
assert(mat.cofactor == matrixrows(
    vector(4, -3),
    vector(-2, 1),
));
// Get the adjugate
assert(mat.adjugate == matrixrows(
    vector(4, -2),
    vector(-3, 1),
));
// Get the inverse: Multiplying by a matrix's inverse produces the identity matrix.
assert(mat * mat.inverse == Matrix2f.identity);
```

``` D
auto mat = matrixrows!(3, 2)(
    1, 2, 3,
    4, 5, 6,
);
assert(mat.flipv == matrixrows!(3, 2)(
    4, 5, 6,
    1, 2, 3,
));
assert(mat.fliph == matrixrows!(3, 2)(
    3, 2, 1,
    6, 5, 4,
));
assert(mat.rotate!1 == matrixrows!(2, 3)(
    4, 1,
    5, 2,
    6, 3,
));
assert(mat.scroll!(2, 0) == matrixrows!(3, 2)(
    2, 3, 1,
    5, 6, 4,
));
```


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
import mach.test.assertthrows : assertthrows;
assertthrows!MeanEmptyInputError({
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
import mach.test.assertthrows : assertthrows;
assertthrows!MedianEmptyInputError({
    new int[0].median; // Can't calculate median with an empty input!
});
```


## mach.math.muldiv


This module provides functions for performing the computation `x * y / w` for
inputs meeting various constraints.
When the inputs are integers, these computations are performed using only
integer math and will never overflow when the result of the computation is
representable of the input type.
Therefore, none of the provided functions will overflow if `abs(x) <= abs(y)`.

The module additionally provides a function for computing `x * y / (T.max + 1)`.
In this case, the input must satisfy the condition `abs(x) < abs(y)`.

The output of `muldiv` called with integers is not guaranteed to be accurately
rounded. However, these things are guaranteed:
If the result can fit in the given integer type, then it will not be incorrect
as a result of overflowing intermediate operations.
Additionally, when that condition holds, `muldiv(x*y, y, w) == x` and
`muldiv(x, y, w) <= muldiv(x + 1, y, w)`.

``` D
assert(muldiv(0, 16, 32) == 0); // 0 / 16 * 32 == 0
assert(muldiv(4, 16, 32) == 8); // 4 / 16 * 32 == 8
assert(muldiv(8, 16, 32) == 16); // 8 / 16 * 32 == 16
assert(muldiv(12, 16, 32) == 24); // 12 / 16 * 32 == 24
assert(muldiv(16, 16, 32) == 32); // 16 / 16 * 32 == 32
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


## mach.math.sum


The `sum` function accepts an finite input iterable and returns the sum of its
elements. The only condition imposed upon element types is that they must allow
addition via the binary `+` operator; i.e. user-defined types may be used as
input in addition to primitive numeric types.

When the input is an iterable of floating point primitives, the
[Kahan summation algorithm](https://en.wikipedia.org/wiki/Kahan_summation_algorithm)
is used to reduce error.
In all other cases, a linear summation algorithm is used.
These separate summation algorithms may be called individually via the
`kahansum` and `linearsum` methods that are also implemented in this module.

``` D
assert(sum([1, 2, 3, 4]) == 10);
assert(sum([0.25, 0.5, 0.75]) == 1.5);
```


The `fsum` (or `shewsum`) function can additionally be used to sum floats using
[https://people.eecs.berkeley.edu/~jrs/papers/robustr.pdf](Shewchuck's algorithm).
It is less efficient than the Kahan summation algorithm, but its output is more
correct.

``` D
assert(fsum([0.25, 0.5, 0.75]) == 1.5);
```


Note that the floating-point summation implementations — both `kahansum` and
`shewsum` and their aliases — have consistent behavior for NaN and infinite
inputs, and for intermediate overflow during summation.

``` D
import mach.math.floats.properties : fisnan, fisposinf, fisneginf;
// When there is any NaN, returns the first NaN.
assert(sum([1.0, +real.nan]).fisnan);
// When there is any +inf but no NaN or -inf, returns +inf.
assert(sum([1.0, +real.infinity]).fisposinf);
// When there is any -inf but no NaN or +inf, returns -inf.
assert(sum([1.0, -real.infinity]).fisneginf);
// When there's both +inf and -inf but no NaN, returns NaN.
assert(sum([+real.infinity, -real.infinity]).fisnan);
// When there's intermediate positive overflow but no +inf, -inf, or NaN, returns +inf.
assert(sum([+real.max, +real.max]).fisposinf);
// When there's intermediate negative overflow but no +inf, -inf, or NaN, returns -inf.
assert(sum([-real.max, -real.max]).fisneginf);
```


## mach.math.trig


This package implements or otherwise exposes various trigonometric functions.


## mach.math.vector


This module implements a `Vector` template type with signed numeric components
and arbitrary dimensionality.
For convenience, several symbols are defined as shortcuts for common uses,
including `Vector2i` and `Vector2f`, `Vector3i` and `Vector3f`, and
`Vector4i` and `Vector4f`. Each refers to a template of the specified
dimensionality, and with a signed integral or floating point component type.

Additionally, the `vector` function may be used to produce a vector having
the components specified as arguments.

The components of vectors may be accessed with indexes known at compile time.
(The `vector.index(i)` method may be used for indexes known only at runtime.)
The first four components of vectors may be referred to as `x`, `y`, `z`, and `w`,
and [swizzling](https://www.khronos.org/opengl/wiki/Data_Type_(GLSL)#Swizzling)
may be used to get vectors made up of some specified components.

``` D
auto vec = Vector3i(0, 1, 2);
// Components support random access with compile-time indexes,
assert(vec[0] == 0);
assert(vec[1] == 1);
assert(vec[2] == 2);
// And with runtime indexes,
assert(vec.index(0) == 0);
assert(vec.index(1) == 1);
assert(vec.index(2) == 2);
// And with the x, y, z, w properties.
assert(vec.x == 0);
assert(vec.y == 1);
assert(vec.z == 2);
// Also: Swizzling!
assert(vec.xy == vector(0, 1));
assert(vec.zyx == vector(2, 1, 0));
assert(vec.xxyy == vector(0, 0, 1, 1));
vec.xy = vector(-2, 0);
assert(vec == vector(-2, 0, 2));
```


Vectors support component-wise binary operations with other vectors of the
same dimensionality, as well as a dot product.
They can also be multiplied or divided by scalars.
Three-dimensional vectors additionally support a cross product operation.

``` D
assert(vector(1, 2, 3) * 2 == vector(2, 4, 6));
assert(vector(2, 4, 16) / 2 == vector(1, 2, 8));
assert(vector(1, 2, 3) + vector(3, 4, 5) == vector(4, 6, 8));
assert(vector(3, 2, 1) - vector(1, 1, 1) == vector(2, 1, 0));
assert(vector(1, 2, 3) * vector(-1, -2, -3) == vector(-1, -4, -9));
assert(vector(8, 9, 10) / vector(2, 3, 5) == vector(4, 3, 2));
assert(vector(1, 2, 3).dot(vector(4, 5, 6)) == 32);
assert(vector(1, 2, 3).cross(vector(3, 2, 1)) == vector(-4, 8, -4));
assert(-vector(1, 2) == vector(-1, -2)); // Vectors also allow component-wise negation
```


The `length` method may be used to get the magnitude of the vector.
(By contrast, the `size` attribute represents the dimensionality of the vector.)
A `lengthsq` method is provided to obtain the squared magnitude, which is
faster than `length`.
The `distance` and `distancesq` methods may similarly be used to get the
Euclidean distance between two vectors.

The `normalize` method returns a unit vector pointing in the same direction
as the input vector.

``` D
assert(vector(3, 4).length == 5);
assert(vector(3, 4).lengthsq == 25);
assert(vector(1, 2, 3).distance(vector(5, 2, 6)) == 5);
assert(vector(1, 2, 3).distancesq(vector(5, 2, 6)) == 25);
```

``` D
import mach.math.floats.compare : fnearequal;
assert(fnearequal(vector(4, 5).normalize.length, 1, 1e-16));
```


In addition to comparison using the equality operator, Vector types also
provide an `equals` method which accepts an optional per-component epsilon,
defining the maximum deviation of any component in one vector from the
corresponding component in the other vector required before the vectors are
considered unequal.

``` D
assert(Vector2!double(1, 2) == Vector2!int(1, 2));
assert(Vector3!int(1, 2, 3).equals(Vector3!float(1, 2, 3)));
assert(Vector4!double(1, 2, 3, 4).equals(Vector4!double(1, 2, 3, 4 + 1e-10), 1e-8));
```


The `angle` method may be used to get the angle described by two vectors.
The result is an Angle object, as defined and documented in
`mach.math.trig.angle`. It will always be less than or equal to π radians.

The `direction` method may be used to get the direction from the origin to
a given vector, or from one vector to another, represented as the angular parts
of spherical coordinates. For two-dimensional vectors it returns a single
Angle object, and for other vector types it returns a tuple of Angle
objects. (The `directiontup` method may be used to unconditionally acquire a
tuple of Angles.)
The code `auto angles = vector.direction; auto radius = vector.length;` is
equivalent to converting to n-dimensional spherical coordinates.

To convert spherical coordinates to a Cartesian-coordinate vector, the
`Vector.unit` static method may be used. It accepts either a tuple of Angles
or the correct number of Angles as separate arguments, and returns a unit
vector pointing in the specified direction.
The condition `vec == vec.unit(vec.direction) * vec.length` will consistently
hold true, accounting for slight inaccuracies due to floating point errors.

``` D
import mach.math.trig.angle : Angle;
assert(vector(0, 1).angle(vector(1, 0)).degrees == 90);
assert(vector(1, 1).direction.degrees == 45);
assert(Vector2f.unit(Angle!().Degrees(90)) == vector(0, 1));
```

``` D
import mach.math.floats.compare : fnearequal;
auto dir = vector(0, +2, -2).direction;
assert(fnearequal(dir[0].degrees, 90, 1e-12));
assert(fnearequal(dir[1].degrees, 315, 1e-12));
```

``` D
auto vec = Vector4f(-2, -1, +1, +2);
auto dir = vec.direction;
assert(vec.equals(Vector4f.unit(dir) * vec.length, 1e-8));
```


The `reflect` method may be used to get the reflection of a vector against the
plane perpendicular to a normal.
The `project` method gets a projection of the input upon a normal vector;
it returns a vector the same length as the input, pointing in the direction
of a given normal.

``` D
assert(vector(3, 4).reflect(vector(1, -1).normalize).equals(vector(-4, -3), 1e-8));
```

``` D
assert(vector(4, 3).project(vector(-1, 0)) == vector(-5, 0));
```


