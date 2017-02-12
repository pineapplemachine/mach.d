# mach.math.trig


This package implements or otherwise exposes various trigonometric functions.


## mach.math.trig.sincos


This module provides the [`sin`, `cos`, and `sincos` trigonometric functions]
(https://en.wikipedia.org/wiki/Trigonometric_functions#Sine.2C_cosine_and_tangent).

`sin` can be used to compute the sine of an angle given in radians, and `cos`
the cosine.
`sincos` computes both at once, which will often be more performant than making
separate calls to `sin` and `cos` when both values are required.

When the input to `sin` or `cos` is infinite or NaN, the output will be NaN.
When the input to `sincos` is infinite or NaN, the output will have NaN
representing both its sine and cosine results.

``` D
import mach.math.floats.compare : fnearequal;
assert(fnearequal(sin(1), 0.84147098480789650665L, 1e-18));
assert(fnearequal(cos(1), 0.54030230586813971740L, 1e-18));
```

``` D
import mach.math.floats.compare : fnearequal;
immutable both = sincos(1); // May be faster than separate calls
assert(fnearequal(both.sin, 0.84147098480789650665L, 1e-18));
assert(fnearequal(both.cos, 0.54030230586813971740L, 1e-18));
```


## mach.math.trig.tangent


This module implements the `tan`
[trigonometric function](https://en.wikipedia.org/wiki/Trigonometric_functions#Sine.2C_cosine_and_tangent).
The input angle must be measured in radians.
Returned values are always of type `real`.

Depending on the platform, `tan(pi / 2)` may or may not produce infinity.
Strictly speaking, a return value of infinity indicates that a rounding error
has occurred, since `real(pi / 2)` is not exactly equal to `pi / 2`.
`tan(float.infinity)` and `tan(float.nan)` produce NaN.
Very large positive or negative values will potentially produce inaccurate
results due to rounding errors.

``` D
import mach.math.floats : fnearequal;
import mach.math.constants : pi;
assert(fnearequal(tan(pi), 0));
assert(fnearequal(tan(1.0), 1.5574077246549022, 1e-12));
```


This module also defines a `fasttan` function, which may use a faster algorithm
at the expense of accuracy.

``` D
import mach.math.floats : fnearequal;
assert(fnearequal(fasttan(1.0), 1.5574077246549022, 1e-6));
```


