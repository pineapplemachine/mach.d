# mach.math.trig


This package implements or otherwise exposes various trigonometric functions.


## mach.math.trig.angle


The `Angle` type can be used to represent an angle in the range [0, 2π) radians.
Angles outside the range are wrapped to fit inside it.
Unlike using a floating point to represent an angle with radians, `Angle` is
able to exactly represent quarter, half, etc. rotations that have special
meanings in trigonometric functions and identities.

The case of `tan(2π)` is where this difference is most immediately apparent:

``` D
import mach.math.constants : pi;
import mach.math.trig.tangent : tan;
import mach.math.floats.properties : fisinf;
// π/2 radians is not exactly representable as a floating-point value.
// The tangent of the closest representable value isn't infinite.
assert(!fisinf(tan(pi / 2)));
// The `Angle` type is not subject to the same limitation.
auto angle = Angle!ulong.Revolutions(0.25);
assert(angle.radians == pi / 2);
assert(fisinf(angle.tan));
```


The `Angle` type has the `Radians`, `Degrees`, and `Revolutions` initializers.
It also has the `radians`, `degrees`, and `revolutions` properties.
These allow converting the internal representation to common angle
measurements, or converting those common measurements to values of the `Angle`
type.

``` D
import mach.math.constants : pi;
assert(Angle!ulong.Degrees(270) == Angle!ulong.Revolutions(0.75));
assert(Angle!ulong.Radians(pi) == Angle!ulong.Degrees(180));
auto angle = Angle!ulong.Revolutions(0.5);
assert(angle.revolutions == 0.5);
assert(angle.radians == pi);
assert(angle.degrees == 180);
angle.degrees = 45;
assert(angle.revolutions == 0.125);
angle.radians = pi / 2;
assert(angle.revolutions == 0.25);
angle.revolutions = 0.75;
assert(angle.revolutions == 0.75);
```


The `Angle` template type accepts a single template argument, which must be
an unsigned integral type. It defaults to `ulong`. The larger the type used
as a basis for the angle's internal representation, the greater the number of
discrete equidistant angles that can be represented by that type.

When performing operations upon mixed `Angle` types, the result will always
be of the larger type.

``` D
auto a = Angle!ubyte.Degrees(90); // Can represent 256 different angles.
auto b = Angle!ulong.Degrees(90); // Can represent 2^64 different angles.
// But they are still equal,
assert(a == b);
// And can still be added to one another,
Angle!ulong sum = a + b;
assert(sum == Angle!ushort.Degrees(180));
// Or subtracted,
assert(sum - a == b);
// Or compared for distance.
Angle!ulong dist = a.distance(b);
assert(dist == Angle!ubyte.Degrees(0));
```


`Angle` objects implement `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, and `atan2`
trigonometric functions as methods.
These behave the same as the identically-named functions defined elsewhere in
the `mach.math.trig` package, except that in many cases their outputs will be
more accurate relative to simply using radians.

``` D
import mach.math.floats.properties : fisinf;
assert(Angle!ulong.Degrees(90).sin == 1); // Sine
assert(Angle!ulong.Degrees(90).cos == 0); // Cosine
assert(Angle!ulong.Degrees(90).tan.fisinf); // Tangent
assert(Angle!ulong.asin(1).degrees == 90); // Arcsine
assert(Angle!ulong.acos(0).degrees == 90); // Arccosine
assert(Angle!ulong.atan(real.infinity).degrees == 90); // Arctangent
assert(Angle!ulong.atan2(1, 1).degrees == 45); // atan2
```


The `Angle` type supports the `-`, `++`, and `--` unary operators.
`-angle` returns an angle which is pointing in the direction opposite the
original angle.
`angle++` evaluates to the first representable angle that is clockwise
relative to the original angle.
`angle--` evaluates to the first representable angle that is counterclockwise
relative to the original angle.

``` D
auto angle = Angle!uint.Degrees(90);
assert(-angle == Angle!uint.Degrees(270));
assert(++angle > Angle!uint.Degrees(90));
assert(--angle == Angle!uint.Degrees(90));
```


The `distance` method can be used to find the distance between two angles,
and the result will always be less than or equal to π radians.
The returned type acts like an `Angle` but it also has a `direction`
attribute carrying information regarding whether the closer distance given is
in a clockwise or counterclockwise direction.

``` D
import mach.math.trig.rotdirection : RotationDirection;
auto x = Angle!ulong.Degrees(45);
auto y = Angle!ulong.Degrees(315);
auto dist = x.distance(y);
assert(dist.degrees == 90);
assert(dist.direction is RotationDirection.Counterclockwise);
```


The `lerp` method can be used to linearly interpolate between two angles.
When the second argument `t` is out of the range [0, 1], it is clamped.
When the argument `t` is NaN, an angle of 0 radians is returned.

``` D
auto x = Angle!ulong.Revolutions(0.0);
auto y = Angle!ulong.Revolutions(0.5);
assert(x.lerp(y, 0.0) == x);
assert(x.lerp(y, 1.0) == y);
assert(x.lerp(y, 0.5).revolutions == 0.25);
```


## mach.math.trig.arctangent


This module implements the [`atan`](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions)
and [`atan2`](https://en.wikipedia.org/wiki/Atan2) trigonometric functions.

`atan` is the arctangent function for a single floating point input, and it
returns an angle between -π/2 and +π/2 radians.
Its companion, `atan2`, accepts two inputs and finds the arctangent of the
first input divided by the second. This makes it possible to retain quadrant
information, such that `atan2` may return an angle from -π to +π radians.

When any input to either of these functions is NaN, the output is also NaN.


## mach.math.trig.inverse


This module defines the `asin` and `acos` [trigonometric functions]
(https://en.wikipedia.org/wiki/Inverse_trigonometric_functions).
Their inputs are expected to be at least -1 and at most +1, otherwise they
return NaN.

``` D
import mach.math.floats.compare : fnearequal;
import mach.math.trig.sincos : sin, cos;
assert(fnearequal(sin(asin(0.5)), 0.5, 1e-18));
assert(fnearequal(cos(acos(0.5)), 0.5, 1e-18));
```


## mach.math.trig.rotdirection


This module defines a `RotationDirection` enum with `Clockwise`,
`Counterclockwise`, and `None` members.


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


