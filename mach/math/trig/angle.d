module mach.math.trig.angle;

private:

import mach.traits : Unqual, isNumeric, isFloatingPoint, isIntegral, isUnsignedIntegral;
import mach.math.constants : tau, quarterpi, threequarterspi;
import mach.math.floats.extract : fextractsgn;
import mach.math.floats.properties : fisnan, fisinf;
import mach.math.trig.arctangent : atan, atan2;
import mach.math.trig.inverse : asin, acos;
import mach.math.trig.sincos : sin, cos;
import mach.math.trig.tangent : tan;

/++ Docs

The `Angle` type can be used to represent an angle in the range [0, 2π) radians.
Angles outside the range are wrapped to fit inside it.
Unlike using a floating point to represent an angle with radians, `Angle` is
able to exactly represent quarter, half, etc. rotations that have special
meanings in trigonometric functions and identities.

The case of `tan(2π)` is where this difference is most immediately apparent:

+/

unittest{ /// Example
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
}

/++ Docs

The `Angle` type has the `Radians`, `Degrees`, and `Revolutions` initializers.
It also has the `radians`, `degrees`, and `revolutions` properties.
These allow converting the internal representation to common angle
measurements, or converting those common measurements to values of the `Angle`
type.

+/

unittest{ /// Example
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
}

/++ Docs

The `Angle` template type accepts a single template argument, which must be
an unsigned integral type. It defaults to `ulong`. The larger the type used
as a basis for the angle's internal representation, the greater the number of
discrete equidistant angles that can be represented by that type.

When performing operations upon mixed `Angle` types, the result will always
be of the larger type.

+/

unittest{ /// Example
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
}

/++ Docs

`Angle` objects implement `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, and `atan2`
trigonometric functions as methods.
These behave the same as the identically-named functions defined elsewhere in
the `mach.math.trig` package, except that in many cases their outputs will be
more accurate relative to simply using radians.

+/

unittest{ /// Example
    import mach.math.floats.properties : fisinf;
    assert(Angle!ulong.Degrees(90).sin == 1); // Sine
    assert(Angle!ulong.Degrees(90).cos == 0); // Cosine
    assert(Angle!ulong.Degrees(90).tan.fisinf); // Tangent
    assert(Angle!ulong.asin(1).degrees == 90); // Arcsine
    assert(Angle!ulong.acos(0).degrees == 90); // Arccosine
    assert(Angle!ulong.atan(real.infinity).degrees == 90); // Arctangent
    assert(Angle!ulong.atan2(1, 1).degrees == 45); // atan2
}

/++ Docs

The `Angle` type supports the `-`, `++`, and `--` unary operators.
`-angle` returns an angle which is pointing in the direction opposite the
original angle.
`angle++` evaluates to the first representable angle that is clockwise
relative to the original angle.
`angle--` evaluates to the first representable angle that is counterclockwise
relative to the original angle.

+/

unittest{ /// Example
    auto angle = Angle!uint.Degrees(90);
    assert(-angle == Angle!uint.Degrees(270));
    assert(++angle > Angle!uint.Degrees(90));
    assert(--angle == Angle!uint.Degrees(90));
}

/++ Docs

The `distance` method can be used to find the distance between two angles,
and the result will always be less than or equal to π radians.
The returned type acts like an `Angle` but it also has a `direction`
attribute carrying information regarding whether the closer distance given is
in a clockwise or counterclockwise direction.

+/

unittest{ /// Example
    import mach.math.trig.rotdirection : RotationDirection;
    auto x = Angle!ulong.Degrees(45);
    auto y = Angle!ulong.Degrees(315);
    auto dist = x.distance(y);
    assert(dist.degrees == 90);
    assert(dist.direction is RotationDirection.Counterclockwise);
}

/++ Docs

The `lerp` method can be used to linearly interpolate between two angles.
When the second argument `t` is out of the range [0, 1], it is clamped.
When the argument `t` is NaN, an angle of 0 radians is returned.

+/

unittest{ /// Example
    auto x = Angle!ulong.Revolutions(0.0);
    auto y = Angle!ulong.Revolutions(0.5);
    assert(x.lerp(y, 0.0) == x);
    assert(x.lerp(y, 1.0) == y);
    assert(x.lerp(y, 0.5).revolutions == 0.25);
}

public:



public import mach.math.trig.rotdirection : RotationDirection;



/// Type returned by `getsametypeangle`.
private struct GetSameTypeAngleResult(T){
    alias Type = T;
    alias Angle = .Angle!Type;
    T a; T b;
}

/// Helper method to, given two values belonging to angles of potentially
/// different types, get those values as though they belonged to angles of the
/// same type.
private auto getsametypeangle(A, B)(in A a, in B b) if(isUnsignedIntegral!A && isUnsignedIntegral!B){
    alias Result = GetSameTypeAngleResult;
    static if(is(A == B)){
        return Result!A(a, b);
    }else static if(A.sizeof > B.sizeof){
        return Result!A(a, getangleas!A(b));
    }else{
        return Result!B(getangleas!B(a), b);
    }
}

/// Helper method for converting an angle of one type to another.
private T getangleas(T, A)(in A value) if(isUnsignedIntegral!T && isUnsignedIntegral!A){
    static if(is(A == T)){
        return value;
    }else static if(T.sizeof > A.sizeof){
        return cast(T)((cast(T) value) << ((T.sizeof - A.sizeof) * 8));
    }else{
        return cast(T)(value >> ((A.sizeof - T.sizeof) * 8));
    }
}



/// A type representing an angle in the range [0, 2π) radians.
/// The implementation is such that a greater number of discrete angles may
/// be represented with a smaller amount of information than when simply using
/// a floating point, and such that more exact results can be produced for
/// trigonometric functions where using radians could result in slightly
/// different answers from what may be expected because of rounding.
struct Angle(T = ulong) if(isUnsignedIntegral!T){
    /// The smallest representable angle, which is exactly 0 radians.
    static enum min = typeof(this)(0);
    /// The largest representable angle, which is just under 2π radians.
    static enum max = typeof(this)(T.max);
    
    private static enum real RealMax = cast(real) T.max + 1;
    
    /// Fractions of angles.
    private static enum T T1_8 = T.max / 8 + 1;
    private static enum T T1_4 = T.max / 4 + 1;
    private static enum T T3_8 = T1_4 + T1_8;
    private static enum T T1_2 = T.max / 2 + 1;
    private static enum T T5_8 = T1_2 + T1_8;
    private static enum T T3_4 = T1_2 + T1_4;
    private static enum T T7_8 = T3_4 + T1_8;
    
    /// An angle representing one-sixteenth of a rotation.
    static enum Sixteenth = typeof(this)(T.max / 16 + 1);
    /// An angle representing one-eighth of a rotation.
    static enum Eighth = typeof(this)(T1_8);
    /// An angle representing one-quarter of a rotation.
    static enum Quarter = typeof(this)(T1_4);
    /// An angle representing three-eighths of a rotation.
    static enum ThreeEighths = typeof(this)(T3_8);
    /// An angle representing one-half of a rotation.
    static enum Half = typeof(this)(T1_2);
    /// An angle representing five-eighths of a rotation.
    static enum FiveEighths = typeof(this)(T5_8);
    /// An angle representing three-quarters of a rotation.
    static enum ThreeQuarters = typeof(this)(T3_4);
    /// An angle representing seven-eighths of a rotation.
    static enum SevenEighths = typeof(this)(T7_8);
    
    alias Value = T;
    Value value = 0;
    
    this(N)(in N value) if(isIntegral!N){
        this.value = cast(T) value;
    }
    
    /// Get the angle measured in radians.
    @property real radians() const{
        return this.phaseconvertto!tau();
    }
    /// Set the angle to a value measured in radians.
    @property void radians(R)(in R radians) if(isNumeric!R){
        this.value = this.phaseconvertfrom!tau(radians);
    }
    /// Return an angle with the given value measured in radians.
    static typeof(this) Radians(R)(in R radians) if(isNumeric!R){
        return typeof(this)(typeof(this).phaseconvertfrom!tau(radians));
    }
    
    /// Get the angle measured in degrees.
    @property real degrees() const{
        return this.phaseconvertto!360();
    }
    /// Set the angle to a value measured in degrees.
    @property void degrees(R)(in R degrees) if(isNumeric!R){
        this.value = this.phaseconvertfrom!360(degrees);
    }
    /// Return an angle with the given value measured in degrees.
    static typeof(this) Degrees(R)(in R degrees) if(isNumeric!R){
        return typeof(this)(typeof(this).phaseconvertfrom!360(degrees));
    }
    
    /// Get the angle measured in revolutions.
    @property real revolutions() const{
        return this.phaseconvertto!1();
    }
    /// Set the angle to a value measured in revolutions.
    @property void revolutions(R)(in R revolutions) if(isNumeric!R){
        this.value = this.phaseconvertfrom!1(revolutions);
    }
    /// Return an angle with the given value measured in revolutions.
    static typeof(this) Revolutions(R)(in R revolutions) if(isNumeric!R){
        return typeof(this)(typeof(this).phaseconvertfrom!1(revolutions));
    }
    
    /// Utility method used to convert to e.g. radians or degrees.
    private real phaseconvertto(real revolution)() const{
        enum halfrev = revolution / 2;
        enum quarterrev = revolution / 4;
        enum threequartersrev = halfrev + quarterrev;
        if(this.value == 0) return 0;
        else if(this.value == T1_4) return quarterrev;
        else if(this.value == T1_2) return halfrev;
        else if(this.value == T3_4) return threequartersrev;
        else if(this.value < T1_2) return this.value * halfrev / cast(real) T1_2;
        else return ((this.value - T1_2) * halfrev / cast(real) T1_2) + halfrev;
    }
    /// Utility method used to convert from e.g. radians or degrees.
    private static T phaseconvertfrom(real revolution, R)(in R x) if(isNumeric!R){
        static if(isFloatingPoint!R){
            if(x.fisnan || x.fisinf) return 0;
        }
        if(x > 0){
            return cast(T)(((x / revolution) % 1) * RealMax);
        }else{
            return cast(T)((((x / revolution) % 1) + 1) * RealMax);
        }
    }
    
    /// Get the sine of this angle.
    @property real sin() const{
        if(this.value == T1_4){
            return 1;
        }else if(this.value == T3_4){
            return -1;
        }else if(this.value == 0 || this.value == T1_2){
            return 0;
        }else{
            immutable x = .sin((this.value % T1_2) * pi / real(T1_2));
            if(this.value < T1_2) return x;
            else return -x;
        }
    }
    /// Get the cosine of this angle.
    @property real cos() const{
        if(this.value == 0){
            return 1;
        }else if(this.value == T1_2){
            return -1;
        }else if(this.value == T1_4 || this.value == T3_4){
            return 0;
        }else{
            immutable x = .cos((this.value % T1_2) * pi / real(T1_2));
            if(this.value < T1_2) return x;
            else return -x;
        }
    }
    /// Get the tangent of this angle.
    @property real tan() const{
        immutable value = this.value % T1_2;
        if(value == 0){
            return 0;
        }else if(value == T1_4){
            return real.infinity;
        }else if(value == T1_8){
            return 1;
        }else if(value == T3_8){
            return -1;
        }else{
            immutable adj = (value < T1_8 || (value > T1_4 && value < T3_8) ?
                value % T1_8 : T1_8 - (value % T1_8)
            );
            immutable x = .tan(adj * quarterpi / real(T1_8));
            if(value < T1_8) return x;
            else if(value < T1_4) return 1 / x;
            else if(value < T3_8) return -1 / x;
            else return -x;
        }
    }
    
    /// Get an angle representing the arcsine of an input.
    /// Returns an angle between -π/2 and +π/2 radians.
    static typeof(this) asin(in real x){
        if(x <= -1){
            return typeof(this)(T3_4);
        }else if(x == 0 || x.fisnan){
            return typeof(this)(0);
        }else if(x >= 1){
            return typeof(this)(T1_4);
        }else{
            return typeof(this).Radians(.asin(x));
        }
    }
    /// Get an angle representing the arccosine of an input.
    /// Returns an angle between 0 and π radians.
    static typeof(this) acos(in real x){
        if(x <= -1){
            return typeof(this)(T1_2);
        }else if(x == 0){
            return typeof(this)(T1_4);
        }else if(x >= 1 || x.fisnan){
            return typeof(this)(0);
        }else{
            return typeof(this).Radians(.acos(x));
        }
    }
    /// Get an angle representing the arctangent of an input.
    /// Returns an angle between -π/2 and +π/2 radians.
    static typeof(this) atan(in real x){
        if(x == 0 || x.fisnan){
            return typeof(this)(0);
        }else if(x.fisinf){
            return typeof(this)(x > 0 ? T1_4 : T3_4);
        }else{
            return typeof(this).Radians(.atan(x));
        }
    }
    /// Get an angle respresenting the arctangent of `y / x`.
    static typeof(this) atan2(in real y, in real x){
        if(x.fisnan || y.fisnan){
            return typeof(this)(0);
        }else if(y == 0){
            return typeof(this)(x.fextractsgn ? T1_2 : 0);
        }else if(x == 0){
            return typeof(this)(y > 0 ? T1_4 : T3_4);
        }else if(y.fisinf){
            if(x.fisinf){
                if(y > 0) return typeof(this)(x > 0 ? T1_8 : T3_8);
                else return typeof(this)(x > 0 ? T7_8 : T5_8);
            }else{
                return typeof(this)(y > 0 ? T1_4 : T3_4);
            }
        }else if(x.fisinf){
            return typeof(this)(x > 0 ? 0 : T1_2);
        }else if(x == y){
            return typeof(this)(x > 0 ? T1_8 : T5_8);
        }else if(x == -y){
            return typeof(this)(x > 0 ? T7_8 : T3_8);
        }else{
            return typeof(this).Radians(.atan2(y, x));
        }
    }
    
    /// Type returned by a call to the `distance` method.
    static struct Distance{
        /// Quantify the distance between two angles.
        Angle!T angle;
        /// Indicate the direction in which this is the distance.
        RotationDirection direction;
        
        this(in T value, in RotationDirection direction){
            this(Angle!T(value), direction);
        }
        this(in Angle!T angle, in RotationDirection direction){
            assert(angle <= angle.Half);
            this.angle = angle;
            this.direction = direction;
        }
        
        alias angle this;
    }
    
    /// Get an angle representing the distance between this angle and another.
    /// The result will always be less than or equal to π radians.
    auto distance(X)(in Angle!X angle) const{
        immutable same = getsametypeangle(this.value, angle.value);
        alias Dist = Angle!(same.Type).Distance;
        if(same.a == same.b){
            return Dist(0, RotationDirection.None);
        }else{
            immutable agtb = same.a > same.b;
            immutable delta = agtb ? same.a - same.b : same.b - same.a;
            enum S1_2 = same.Angle.T1_2;
            if(delta <= S1_2){
                return Dist(cast(same.Type) delta,
                    agtb ? RotationDirection.Counterclockwise : RotationDirection.Clockwise
                );
            }else{
                return Dist(cast(same.Type)(S1_2 - (delta - S1_2)),
                    agtb ? RotationDirection.Clockwise : RotationDirection.Counterclockwise
                );
            }
        }
    }
    
    /// Linearly interpolate between this and another angle.
    auto lerp(X)(in Angle!X angle, in real t) const{
        immutable same = getsametypeangle(this.value, angle.value);
        if(t.fisnan){
            return same.Angle(0);
        }else if(t <= 0){
            return same.Angle(same.a);
        }else if(t >= 1){
            return same.Angle(same.b);
        }else{
            immutable dist = same.Angle(same.a).distance(same.Angle(same.b));
            immutable x = cast(same.Type)(dist.value * t);
            return same.Angle(cast(same.Type)(
                dist.direction is RotationDirection.Clockwise ? same.a + x : same.a - x
            ));
        }
    }
    
    /// Cast this angle type to another angle type.
    auto opCast(To: Angle!X, X)() const{
        return To(getangleas!X(this.value));
    }
    
    /// Get an angle pointing in the opposite direction.
    auto opUnary(string op: "-")() const{
        return typeof(this)(this.value >= T1_2 ? this.value - T1_2 : this.value + T1_2);
    }
    /// Get the first representable angle clockwise relative to this one.
    auto opUnary(string op: "++")(){
        this.value++;
        return this;
    }
    /// Get the first representable angle counterclockwise relative to this one.
    auto opUnary(string op: "--")(){
        this.value--;
        return this;
    }
    
    /// Rotate this angle clockwise by another angle.
    auto opOpAssign(string op: "+", X)(in Angle!X rhs){
        return this.value += getangleas!T(rhs.value);
    }
    /// Rotate this angle counterclockwise by another angle.
    auto opOpAssign(string op: "-", X)(in Angle!X rhs){
        return this.value -= getangleas!T(rhs.value);
    }
    
    /// Get the first angle rotated clockwise by the second angle.
    auto opBinary(string op: "+", X)(in Angle!X rhs) const{
        immutable same = getsametypeangle(this.value, rhs.value);
        return same.Angle(same.a + same.b);
    }
    /// Get the first angle rotated counterclockwise by the second angle.
    auto opBinary(string op: "-", X)(in Angle!X rhs) const{
        immutable same = getsametypeangle(this.value, rhs.value);
        return same.Angle(same.a - same.b);
    }
    
    /// Get the number of times that another angle fits into this one, i.e.
    /// divide them. Returns a double.
    auto opBinary(string op: "/", X)(in Angle!X rhs) const{
        immutable same = getsametypeangle(this.value, rhs.value);
        return same.a / cast(double) same.b;
    }
    
    /// Divide this angle by some amount.
    auto opBinary(string op: "/", N)(in N rhs) const if(isNumeric!N){
        return typeof(this)(cast(T)(this.value / rhs));
    }
    /// Multiply this angle by some amount.
    auto opBinary(string op: "*", N)(in N rhs) const if(isNumeric!N){
        return typeof(this)(cast(T)(this.value * rhs));
    }
    
    /// Compare two angles.
    auto opEquals(X)(in Angle!X rhs) const{
        immutable same = getsametypeangle(this.value, rhs.value);
        return same.a == same.b;
    }
    /// Ditto
    int opCmp(X)(in Angle!X rhs) const{
        immutable same = getsametypeangle(this.value, rhs.value);
        if(same.a > same.b) return 1;
        else if(same.a < same.b) return -1;
        else return 0;
    }
}



private version(unittest){
    import mach.traits : UnsignedIntegralTypes, LargestTypeOf;
    import mach.math.constants : pi, halfpi;
    import mach.math.floats.compare : fnearequal;
    import mach.math.floats.properties : fisinf;
    auto radsnearequal(in real x, in real y, in real epsilon){
        return fnearequal(x, y > 0 ? y : y + tau, epsilon);
    }
}

unittest{ /// Conversion to degrees/radians at quarter-rotation increments
    foreach(T; UnsignedIntegralTypes){
        enum Half = T.max / 2 + 1;
        enum Quarter = T.max / 4 + 1;
        assert(Angle!T(0).degrees == 0);
        assert(Angle!T(0).radians == 0);
        assert(Angle!T(Quarter).degrees == 90);
        assert(Angle!T(Quarter).radians == halfpi);
        assert(Angle!T(Half).degrees == 180);
        assert(Angle!T(Half).radians == pi);
        assert(Angle!T(Half + Quarter).degrees == 270);
        assert(Angle!T(Half + Quarter).radians == pi + halfpi);
    }
}

unittest{ /// Operator overloads
    foreach(T0; UnsignedIntegralTypes){
        foreach(T1; UnsignedIntegralTypes){
            auto a0 = Angle!T0.Degrees(90);
            auto a1 = Angle!T1.Degrees(180);
            // Non-modifying
            assert(a0 < a1);
            assert(a0 <= a1);
            assert(a1 > a0);
            assert(a1 >= a0);
            assert(a0 != a1);
            assert(a0 == Angle!T1.Degrees(90));
            assert(a1 == Angle!T0.Degrees(180));
            assert(a0 + a1 == Angle!ubyte.Degrees(270));
            assert(a1 - a0 == a0);
            assert(a1 / a0 == 2);
            assert(a0 / a1 == 0.5);
            assert(-a1 == Angle!T0(0));
            assert(-a0 == Angle!T0.Degrees(270));
            // Modifying
            a0 += a1;
            assert(a0 == Angle!T0.Degrees(270));
            a0 -= a1;
            assert(a0 == Angle!T0.Degrees(90));
            a0++;
            assert(a0 > Angle!T0.Degrees(90));
            assert(a0 < Angle!T0.Degrees(93));
            a0--;
            assert(a0 == Angle!T0.Degrees(90));
        }
    }
}

unittest{ /// Distance and interpolation - same angle
    immutable angle = Angle!().Degrees(180);
    assert(angle.distance(angle) == Angle!()(0));
    assert(angle.lerp(angle, 0.5) == angle);
}

unittest{ /// Distance and interpolation - different angles
    // Distance
    immutable a0 = Angle!().Degrees(16);
    immutable a1 = Angle!().Degrees(344);
    immutable dist0 = a0.distance(a1);
    assert(dist0 == Angle!().Degrees(32));
    assert(dist0.direction is RotationDirection.Counterclockwise);
    immutable dist1 = a1.distance(a0);
    assert(dist1 == Angle!().Degrees(32));
    assert(dist1.direction is RotationDirection.Clockwise);
    // Interpolation
    assert(a0.lerp(a1, 0) == a0);
    assert(a0.lerp(a1, 1) == a1);
    assert(a0.lerp(a1, 0.50) == Angle!()(0));
    assert(fnearequal(a0.lerp(a1, 0.25).degrees, 8, 1e-12));
    assert(fnearequal(a0.lerp(a1, 0.75).degrees, 352, 1e-12));
    assert(fnearequal(a1.lerp(a0, 0.25).degrees, 352, 1e-12));
    assert(fnearequal(a1.lerp(a0, 0.75).degrees, 8, 1e-12));
}

unittest{ /// Linear interpolation with special-case inputs
    immutable x = Angle!().Revolutions(0.0);
    immutable y = Angle!().Revolutions(0.5);
    assert(x.lerp(y, -1.0) == x);
    assert(x.lerp(y, +2.0) == y);
    assert(x.lerp(y, -real.infinity) == x);
    assert(x.lerp(y, +real.infinity) == y);
    assert(x.lerp(y, real.nan) == Angle!()(0));
}

unittest{ /// Casting
    Angle!uint a0 = Angle!uint.Degrees(90);
    Angle!ulong a1 = cast(Angle!ulong) a0;
    assert(a0 == a1);
}

unittest{ /// Assign degrees/radians/revolutions
    foreach(T; UnsignedIntegralTypes){
        auto angle = Angle!T(0);
        angle.radians = pi;
        assert(angle.radians == pi);
        assert(angle.degrees == 180);
        assert(angle.revolutions == 0.5);
        angle.degrees = 90;
        assert(angle.radians == halfpi);
        assert(angle.degrees == 90);
        assert(angle.revolutions == 0.25);
        angle.revolutions = 0.75;
        assert(angle.radians == pi + halfpi);
        assert(angle.degrees == 270);
        assert(angle.revolutions == 0.75);
        angle.radians = -halfpi;
        assert(angle.radians == pi + halfpi);
        assert(angle.degrees == 270);
        assert(angle.revolutions == 0.75);
        angle.degrees = -180;
        assert(angle.radians == pi);
        assert(angle.degrees == 180);
        assert(angle.revolutions == 0.5);
        angle.revolutions = -0.75;
        assert(angle.radians == halfpi);
        assert(angle.degrees == 90);
        assert(angle.revolutions == 0.25);
    }
}

unittest{ /// Type promotion
    foreach(T0; UnsignedIntegralTypes){
        foreach(T1; UnsignedIntegralTypes){
            alias Larger = Angle!(LargestTypeOf!(T0, T1));
            static assert(is(typeof(Angle!T0(0) + Angle!T1(0)) == Larger));
            static assert(is(typeof(Angle!T0(0) - Angle!T1(0)) == Larger));
            static assert(is(typeof(Angle!T0(0).distance(Angle!T1(0)).angle) == Larger));
            static assert(is(typeof(Angle!T0(0).lerp(Angle!T1(0), 0)) == Larger));
        }
    }
}

unittest{ /// Min and max
    foreach(T; UnsignedIntegralTypes){
        auto angle = Angle!T.min;
        assert(angle < Angle!T.max);
        angle--;
        assert(angle == Angle!T.max);
    }
}

unittest{ /// Sine, cosine, and tangent at multiples of π/4 radians
    // Multiples of π/2 radians
    immutable a0 = Angle!().Revolutions(0.00);
    assert(a0.sin == 0);
    assert(a0.cos == 1);
    assert(a0.tan == 0);
    immutable a1 = Angle!().Revolutions(0.25);
    assert(a1.sin == 1);
    assert(a1.cos == 0);
    assert(a1.tan.fisinf);
    immutable a2 = Angle!().Revolutions(0.50);
    assert(a2.sin == 0);
    assert(a2.cos == -1);
    assert(a2.tan == 0);
    immutable a3 = Angle!().Revolutions(0.75);
    assert(a3.sin == -1);
    assert(a3.cos == 0);
    assert(a3.tan.fisinf);
    // Tangent at multiples of π/4 radians
    assert(Angle!().Degrees(45).tan == 1);
    assert(Angle!().Degrees(135).tan == -1);
    assert(Angle!().Degrees(225).tan == 1);
    assert(Angle!().Degrees(315).tan == -1);
}

unittest{ /// Sine, cosine, and tangent for arbitrary inputs
    foreach(rads; [0.125L, 0.25L, 0.3L, 0.4L, 0.5L, 0.75L, 0.8L, 1.0L, 2.0L, 3.0L, 4.0L, 20.0L]){
        assert(fnearequal(Angle!().Radians(+rads).sin, sin(+rads), 1e-12));
        assert(fnearequal(Angle!().Radians(-rads).sin, sin(-rads), 1e-12));
        assert(fnearequal(Angle!().Radians(+rads).cos, cos(+rads), 1e-12));
        assert(fnearequal(Angle!().Radians(-rads).cos, cos(-rads), 1e-12));
        assert(fnearequal(Angle!().Radians(+rads).tan, tan(+rads), 1e-12));
        assert(fnearequal(Angle!().Radians(-rads).tan, tan(-rads), 1e-12));
    }
}

unittest{ /// Arcsine, arccosine, and arctangent for remarkable values
    // Arcsine
    assert(Angle!().asin(-1).degrees == 270);
    assert(Angle!().asin(+0).degrees == 0);
    assert(Angle!().asin(+1).degrees == 90);
    assert(Angle!().asin(real.nan).degrees == 0); // NaN inputs produce 0
    assert(Angle!().asin(+2).degrees == 90); // Out-of-range inputs are clamped
    assert(Angle!().asin(-2).degrees == 270); // Ditto
    // Arccosine
    assert(Angle!().acos(-1).degrees == 180);
    assert(Angle!().acos(+0).degrees == 90);
    assert(Angle!().acos(+1).degrees == 0);
    assert(Angle!().acos(real.nan).degrees == 0); // NaN inputs produce 0
    assert(Angle!().acos(+2).degrees == 0); // Out-of-range inputs are clamped
    assert(Angle!().acos(-2).degrees == 180); // Ditto
    // Arctangent
    assert(Angle!().atan(0).degrees == 0);
    assert(Angle!().atan(+1).degrees == 45);
    assert(Angle!().atan(-1).degrees == 315);
    assert(Angle!().atan(+real.infinity).degrees == 90);
    assert(Angle!().atan(-real.infinity).degrees == 270);
    assert(Angle!().atan(real.nan).degrees == 0); // NaN inputs produce 0
}

unittest{ /// Special cases for atan2
    enum inf = real.infinity;
    assert(Angle!().atan2(+0.0, +0.0).degrees == 0);
    assert(Angle!().atan2(+0.0, -0.0).degrees == 180);
    assert(Angle!().atan2(+0.0, +1.0).degrees == 0);
    assert(Angle!().atan2(+0.0, -1.0).degrees == 180);
    assert(Angle!().atan2(+0.0, +inf).degrees == 0);
    assert(Angle!().atan2(+0.0, -inf).degrees == 180);
    assert(Angle!().atan2(-0.0, +0.0).degrees == 0);
    assert(Angle!().atan2(-0.0, -0.0).degrees == 180);
    assert(Angle!().atan2(-0.0, +1.0).degrees == 0);
    assert(Angle!().atan2(-0.0, -1.0).degrees == 180);
    assert(Angle!().atan2(-0.0, +inf).degrees == 0);
    assert(Angle!().atan2(-0.0, -inf).degrees == 180);
    assert(Angle!().atan2(+1.0, +0.0).degrees == 90);
    assert(Angle!().atan2(+1.0, -0.0).degrees == 90);
    assert(Angle!().atan2(+1.0, +1.0).degrees == 45);
    assert(Angle!().atan2(+1.0, -1.0).degrees == 135);
    assert(Angle!().atan2(+1.0, +inf).degrees == 0);
    assert(Angle!().atan2(+1.0, -inf).degrees == 180);
    assert(Angle!().atan2(-1.0, +0.0).degrees == 270);
    assert(Angle!().atan2(-1.0, -0.0).degrees == 270);
    assert(Angle!().atan2(-1.0, +1.0).degrees == 315);
    assert(Angle!().atan2(-1.0, -1.0).degrees == 225);
    assert(Angle!().atan2(-1.0, +inf).degrees == 0);
    assert(Angle!().atan2(-1.0, -inf).degrees == 180);
    assert(Angle!().atan2(+inf, +0.0).degrees == 90);
    assert(Angle!().atan2(+inf, -0.0).degrees == 90);
    assert(Angle!().atan2(+inf, +1.0).degrees == 90);
    assert(Angle!().atan2(+inf, -1.0).degrees == 90);
    assert(Angle!().atan2(+inf, +inf).degrees == 45);
    assert(Angle!().atan2(+inf, -inf).degrees == 135);
    assert(Angle!().atan2(-inf, +0.0).degrees == 270);
    assert(Angle!().atan2(-inf, -0.0).degrees == 270);
    assert(Angle!().atan2(-inf, +1.0).degrees == 270);
    assert(Angle!().atan2(-inf, -1.0).degrees == 270);
    assert(Angle!().atan2(-inf, +inf).degrees == 315);
    assert(Angle!().atan2(-inf, -inf).degrees == 225);
}

unittest{ /// Arbitrary arcsine and arccosine inputs
    foreach(value; [0.1L, 0.125L, 0.25L, 0.3L, 0.4L, 0.5L, 0.6L, 0.75L, 0.8L, 0.9L]){
        assert(fnearequal(Angle!().asin(+value).radians, asin(+value), 1e-12));
        assert(fnearequal(Angle!().acos(+value).radians, acos(+value), 1e-12));
        assert(fnearequal(Angle!().asin(-value).radians, asin(-value) + tau, 1e-12));
        assert(fnearequal(Angle!().acos(-value).radians, acos(-value), 1e-12));
    }
}

unittest{ /// Arbitrary arctangent inputs
    enum values = [0.1L, 0.125L, 0.2L, 0.5L, 0.8L, 1.5L, 2.0L, 3.0L, 5.0L, 10.0L];
    foreach(x; values){
        assert(fnearequal(Angle!().atan(+x).radians, atan(+x), 1e-12));
        assert(fnearequal(Angle!().atan(-x).radians, atan(-x) + tau, 1e-12));
        foreach(y; values){
            assert(radsnearequal(Angle!().atan2(+x, +y).radians, atan2(+x, +y), 1e-12));
            assert(radsnearequal(Angle!().atan2(+x, -y).radians, atan2(+x, -y), 1e-12));
            assert(radsnearequal(Angle!().atan2(-x, +y).radians, atan2(-x, +y), 1e-12));
            assert(radsnearequal(Angle!().atan2(-x, -y).radians, atan2(-x, -y), 1e-12));
        }
    }
}
