module mach.math.trig.rotation;

private:

import mach.traits : Signed, isNumeric, isIntegral, isSignedIntegral;
import mach.traits : isUnsignedIntegral, isFloatingPoint;
import mach.math.abs : abs, uabs;
import mach.math.constants : tau;
import mach.math.round : floor;
import mach.math.muldiv : muldiv_xlty_wmax;
import mach.math.sign : Sign, signof;
import mach.math.floats.extract : fextractsgn;
import mach.math.floats.properties : fisnan;
import mach.math.trig.angle : Angle, CommonAngleType;
import mach.math.trig.rotdirection : RotationDirection;

/++ Docs

This module implements a `Rotation` type which, similar to the `Angle` type in
`mach.math.trig.angle`, is able to represent amounts of rotation with greater
precision than some other methods.
Unlike `Angle`, which only stores a direction in the range [0, 2π) radians,
the `Rotation` type stores an amount of rotation which includes positive and
negative whole revolutions.
Note that there is an upper and lower limit to the amount of rotation that is
representable, and underflow and overflow will cause the value to wrap between
the lowest and highest representable values.

The `Rotation` struct accepts two template arguments. The first argument must
be an unsigned integer type; this type is used to represent the value's
fractional rotation, and a larger integral type allows for a greater number
of discrete fractional rotations to be represented.
When not provided, it defaults to `ulong`.

The second argument must be a signed integer type; this type is used to
represent the value's whole rotations. A larger integral type allows for
a lower low boundary and a higher high boundary of representable amounts of
rotation.
When not provided, it defaults to a signed complement to the first argument,
e.g. when the first argument is `ulong` the second argument defaults to `long`.

Like the `Angle` type, the `Rotation` type provides methods for converting
to and from radians, degrees, and revolutions.

+/

unittest{ /// Example
    import mach.math.constants : pi;
    import mach.math.floats : fnearequal;
    auto a = Rotation!(ulong, long).Radians(pi * 3);
    assert(fnearequal(a.radians, pi * 3));
    assert(a.degrees == 540);
    assert(a.revolutions == 1.5);
    auto b = Rotation!(ulong, long).Degrees(-90);
    assert(fnearequal(b.radians, -pi / 2));
    assert(b.degrees == -90);
    assert(b.revolutions == -0.25);
    auto c = Rotation!(ulong, long).Revolutions(-2.5);
    assert(fnearequal(c.radians, -pi * 5));
    assert(c.degrees == -900);
    assert(c.revolutions == -2.5);
}

unittest{ /// Example
    import mach.math.constants : pi;
    Rotation!(ulong, long) rot;
    rot.radians = pi;
    assert(rot.revolutions == 0.5);
    rot.degrees = -270;
    assert(rot.revolutions == -0.75);
    rot.revolutions = 2;
    assert(rot.revolutions == 2);
}

/++ Docs

The `Rotation` type supports the trigonometric functions `sin`, `cos`, `tan`,
`asin`, `acos`, `atan`, and `atan2`.

+/

unittest{ /// Example
    import mach.math.floats.properties : fisinf;
    assert(Rotation!().Degrees(90).sin == 1); // Sine
    assert(Rotation!().Degrees(90).cos == 0); // Cosine
    assert(Rotation!().Degrees(90).tan.fisinf); // Tangent
    assert(Rotation!().asin(1).degrees == 90); // Arcsine
    assert(Rotation!().acos(0).degrees == 90); // Arccosine
    assert(Rotation!().atan(real.infinity).degrees == 90); // Arctangent
    assert(Rotation!().atan2(1, 1).degrees == 45); // atan2
}

/++ Docs

`Rotation` objects support a range of addition, subtraction, multiplication,
division, and comparison operations with other rotations, with angles, or
with numbers.

+/

unittest{ /// Example
    alias Rot = Rotation!(uint, int);
    assert(Rot.Revolutions(1.5) + Rot.Revolutions(2.5) == Rot.Revolutions(4.0));
    assert(Rot.Revolutions(2.5) - Rot.Revolutions(3.5) == Rot.Revolutions(-1.0));
    assert(Rot.Revolutions(1.5) + Angle!().Revolutions(0.5) == Rot.Revolutions(2.0));
    assert(Rot.Revolutions(2.5) - Angle!().Revolutions(0.5) == Rot.Revolutions(2.0));
    assert(Rot.Revolutions(1.5) * 0.5 == Rot.Revolutions(0.75));
    assert(Rot.Revolutions(1.5) / 4.0 == Rot.Revolutions(0.375));
}

public:



template CommonRotationType(A: Rotation!(AA, AR), B: Rotation!(BA, BR), AA, AR, BA, BR){
    alias CommonRotationType = CommonRotationType!(AA, AR, BA, BR);
}

private template CommonRotationType(AAngle, ARev, BAngle, BRev){
    static if(AAngle.sizeof >= BAngle.sizeof) alias AngleCommon = AAngle;
    else alias AngleCommon = BAngle;
    static if(ARev.sizeof >= BRev.sizeof) alias RevCommon = ARev;
    else alias RevCommon = BRev;
    alias CommonRotationType = Rotation!(AngleCommon, RevCommon);
}

/// Type returned by `commonrotation`.
private struct CommonRotationResult(AT, RT) if(is(Rotation!(AT, RT))){
    alias Type = Rotation!(AT, RT);
    Type a, b;
}

private auto commonrotation(AA, AR, BA, BR)(
    in Rotation!(AA, AR) a, in Rotation!(BA, BR) b
){
    alias Common = CommonRotationType!(typeof(a), typeof(b));
    return CommonRotationResult!(Common.RotAngle.Value, Common.RotRevs)(
        cast(Common) a, cast(Common) b
    );
}



/// A type representing an amont of rotation.
struct Rotation(AT = ulong, RT = Signed!AT) if(
    is(Angle!AT) && isSignedIntegral!RT
){
    alias RotAngle = Angle!AT;
    alias RotRevs = RT;
    
    /// Get the lowest representable amount of rotation.
    enum min = typeof(this)(RotAngle.min, RotRevs.min);
    /// Get the highest representable amount of rotation.
    enum max = typeof(this)(RotAngle.max, RotRevs.max);
    
    RotAngle angle = RotAngle.min;
    RotRevs wholerevolutions = 0;
    
    /// Get an amount of rotation given an angle.
    this(X)(in Angle!X angle){
        this(angle, 0);
    }
    /// Get an amount of rotation given an integral number of revolutions.
    this(N)(in N revolutions) if(isIntegral!N){
        this(RotAngle(0), revolutions);
    }
    /// Get an amount of rotation given a floating point number of revolutions.
    this(N)(in N revolutions) if(isFloatingPoint!N){
        this(RotAngle.Revolutions(revolutions), cast(RotRevs) floor(revolutions));
    }
    /// Get an amount of rotation given an angle and an integral number of
    /// complete revolutions.
    this(X, N)(in Angle!X angle, in N revolutions) if(isIntegral!N){
        this.angle = cast(RotAngle) angle;
        this.wholerevolutions = cast(RotRevs) revolutions;
    }
    
    /// Get the rotation measured in radians.
    @property auto radians() const{
        return this.angle.radians + this.wholerevolutions * tau;
    }
    /// Set rotation to a value measured in radians.
    @property void radians(in real radians){
        this.angle.radians = radians;
        this.wholerevolutions = cast(RotRevs) floor(radians / tau);
    }
    /// Return a rotation with the given value measured in radians.
    static typeof(this) Radians(in real radians){
        return typeof(this)(
            RotAngle.Radians(radians), cast(RotRevs) floor(radians / tau)
        );
    }
    
    /// Get the rotation measured in degrees.
    @property auto degrees() const{
        return this.angle.degrees + this.wholerevolutions * 360;
    }
    /// Set rotation to a value measured in degrees.
    @property void degrees(in real degrees){
        this.angle.degrees = degrees;
        this.wholerevolutions = cast(RotRevs) floor(degrees / 360);
    }
    /// Return a rotation with the given value measured in degrees.
    static typeof(this) Degrees(in real degrees){
        return typeof(this)(
            RotAngle.Degrees(degrees), cast(RotRevs) floor(degrees / 360)
        );
    }
    
    /// Get the rotation measured in revolutions.
    @property auto revolutions() const{
        return this.angle.revolutions + this.wholerevolutions;
    }
    /// Set rotation to a value measured in revolutions.
    @property void revolutions(N)(in N revolutions) if(isNumeric!N){
        static if(isIntegral!N){
            this.angle.value = 0;
            this.wholerevolutions = cast(RotRevs) revolutions;
        }else{
            this.angle.revolutions = revolutions;
            this.wholerevolutions = cast(RotRevs) floor(revolutions);
        }
    }
    /// Return a rotation with the given value measured in revolutions.
    static typeof(this) Revolutions(N)(in N revolutions) if(isNumeric!N){
        static if(isIntegral!N){
            return typeof(this)(revolutions);
        }else{
            return typeof(this)(
                RotAngle.Revolutions(revolutions), cast(RotRevs) floor(revolutions)
            );
        }
    }
    
    /// Get the sine of this rotation.
    @property real sin() const{
        return this.angle.sin;
    }
    /// Get the cosine of this rotation.
    @property real cos() const{
        return this.angle.cos;
    }
    /// Get the tangent of this rotation.
    @property real tan() const{
        return this.angle.tan;
    }
    
    /// Get an amount of rotation representing the arcsine of an input.
    /// Returns an amount of rotation between -π/2 and +π/2 radians.
    static typeof(this) asin(in real x){
        return typeof(this)(RotAngle.asin(x), x < 0 ? -1 : 0);
    }
    /// Get an amount of rotation representing the arccosine of an input.
    /// Returns an amount of rotation between 0 and π radians.
    static typeof(this) acos(in real x){
        return typeof(this)(RotAngle.acos(x), 0);
    }
    /// Get an amount of rotation representing the arctangent of an input.
    /// Returns an amount of rotation between -π/2 and +π/2 radians.
    static typeof(this) atan(in real x){
        return typeof(this)(RotAngle.atan(x), x < 0 ? -1 : 0);
    }
    
    /// Get an amount of rotation representing the arctangent of `y / x`.
    /// Returns an angle between -π and +π radians.
    static typeof(this) atan2(in real y, in real x){
        if(x.fisnan || y.fisnan){
            return typeof(this)(0);
        }else if(y.fiszero){
            if(x.fextractsgn) return typeof(this)(RotAngle.Half, y.fextractsgn ? -1 : 0);
            else return typeof(this)(0);
        }else if(x.fiszero){
            if(y.fextractsgn) return typeof(this)(RotAngle.ThreeQuarters, -1);
            else return typeof(this)(RotAngle.Quarter, 0);
        }else if(y.fisinf){
            if(x.fisinf){
                if(x > 0){
                    if(y > 0) return typeof(this)(RotAngle.Eighth, 0);
                    else return typeof(this)(RotAngle.SevenEighths, -1);
                }else{
                    if(y > 0) return typeof(this)(RotAngle.ThreeEighths, 0);
                    else return typeof(this)(RotAngle.FiveEighths, -1);
                }
            }else{
                if(y > 0) return typeof(this)(RotAngle.Quarter, 0);
                else return typeof(this)(RotAngle.ThreeQuarters, -1);
            }
        }else if(x.fisinf){
            if(x > 0) return typeof(this)(0);
            else return typeof(this)(RotAngle.Half, y > 0 ? 0 : -1);
        }else if(x > 0){
            return typeof(this).atan(y / x);
        }else if(y > 0){
            return typeof(this).atan(y / x) + RotAngle.Half;
        }else{
            return typeof(this).atan(y / x) - RotAngle.Half;
        }
    }
    
    /// Linearly interpolate between two rotations.
    auto lerp(AX, RX)(in Rotation!(AX, RX) rotation, in real t) const{
        alias Common = CommonRotationType!(typeof(this), typeof(rotation));
        if(t.fisnan){
            return Common(0);
        }else if(t <= 0){
            return cast(Common) this;
        }else if(t >= 1){
            return cast(Common) rotation;
        }else{
            // TODO: There is probably a better way to implement this
            return Common.Revolutions(
                rotation.revolutions * t + this.revolutions * (1 - t)
            );
        }
    }
    
    /// Get the absolute value of this rotation.
    auto abs() const{
        return this.wholerevolutions >= 0 ? this : -this;
    }
    
    /// Get the sign of this rotation amount.
    auto signof() const{
        if(this.wholerevolutions == 0){
            return this.angle.value == 0 ? Sign.Zero : Sign.Positive;
        }else{
            return this.wholerevolutions.signof;
        }
    }
    
    /// Get the direction of rotation as a member of the `RotationDirection`
    /// enum. Determined by the sign of the rotation.
    auto direction() const{
        return cast(RotationDirection) this.signof;
    }
    /// Get the direction that another rotation is in relative to this one
    /// as a member of the `RotationDirection` enum.
    auto direction(AX, RX)(in Rotation!(AX, RX) rhs) const{
        if(rhs > this) return RotationDirection.Clockwise;
        else if(rhs < this) return RotationDirection.Counterclockwise;
        else return RotationDirection.None;
    }
    
    /// Get a negation of this rotation.
    auto opUnary(string op: "-")() const{
        return typeof(this)(~this.angle, -this.wholerevolutions - (this.angle.value != 0));
    }
    /// Returns the rotation itself.
    auto opUnary(string op: "+")() const{
        return this;
    }
    
    /// Get the next-greatest respresentable rotation.
    auto opUnary(string op: "++")(){
        this.angle++;
        if(this.angle.value == 0) this.wholerevolutions++;
        return this;
    }
    /// Get the next-least respresentable rotation.
    auto opUnary(string op: "--")(){
        if(this.angle.value == 0) this.wholerevolutions--;
        this.angle--;
        return this;
    }
    
    /// Get the sum of two rotations.
    auto opBinary(string op: "+", AX, RX)(in Rotation!(AX, RX) rhs) const{
        alias Common = CommonRotationType!(typeof(this), typeof(rhs));
        immutable angle = this.angle + rhs.angle;
        return Common(angle,
            this.wholerevolutions + rhs.wholerevolutions + (angle < this.angle)
        );
    }
    /// Add another rotation to this one.
    auto opOpAssign(string op: "+", AX, RX)(in Rotation!(AX, RX) rhs){
        immutable prevangle = this.angle;
        this.angle += rhs.angle;
        this.wholerevolutions += rhs.wholerevolutions + (this.angle < prevangle);
        return this;
    }
    
    /// Get the subtraction of two rotations.
    auto opBinary(string op: "-", AX, RX)(in Rotation!(AX, RX) rhs) const{
        alias Common = CommonRotationType!(typeof(this), typeof(rhs));
        immutable angle = this.angle - rhs.angle;
        return Common(angle,
            this.wholerevolutions - rhs.wholerevolutions - (this.angle < rhs.angle)
        );
    }
    /// Subtract another rotation from this one.
    auto opOpAssign(string op: "-", AX, RX)(in Rotation!(AX, RX) rhs){
        this.wholerevolutions -= rhs.wholerevolutions + (this.angle < rhs.angle);
        this.angle -= rhs.angle;
        return this;
    }
    
    /// Get the sum of a rotation and an angle.
    auto opBinary(string op: "+", X)(in Angle!X rhs) const{
        immutable angle = this.angle + rhs;
        return Rotation!(CommonAngleType!(RotAngle, Angle!X).Value, RotRevs)(
            angle, this.wholerevolutions + (angle < this.angle)
        );
    }
    /// Ditto
    auto opBinaryRight(string op: "+", X)(in Angle!X rhs) const{
        return this + rhs;
    }
    /// Add an angle to this rotation.
    auto opOpAssign(string op: "+", X)(in Angle!X rhs){
        immutable prevangle = this.angle;
        this.angle += rhs;
        this.wholerevolutions += this.angle < prevangle;
        return this;
    }
    
    /// Get the subtraction of a rotation and an angle.
    auto opBinary(string op: "-", X)(in Angle!X rhs) const{
        immutable angle = this.angle - rhs;
        return Rotation!(CommonAngleType!(RotAngle, Angle!X).Value, RotRevs)(
            angle, this.wholerevolutions - (rhs > this.angle)
        );
    }
    /// Ditto
    auto opBinaryRight(string op: "-", X)(in Angle!X rhs) const{
        return this - rhs;
    }
    /// Subtract an angle from this rotation.
    auto opOpAssign(string op: "-", X)(in Angle!X rhs){
        this.wholerevolutions -= this.angle < rhs;
        this.angle -= rhs;
        return this;
    }
    
    /// Multiply this rotation.
    auto opBinary(string op: "*", N)(in N rhs) const if(isNumeric!N){
        static if(isIntegral!N){
            return this.angle * rhs + typeof(this)(
                this.wholerevolutions * cast(RotRevs) rhs
            );
        }else{
            alias R = typeof(this + (this.angle * rhs) + RotAngle.init);
            if(rhs.fiszero || rhs.fisinf || rhs.fisnan){
                return R(0);
            }else{
                immutable revs = this.wholerevolutions * cast(real) rhs;
                immutable whole = cast(RotRevs) revs;
                immutable fract = RotAngle.Revolutions(.abs(revs - whole));
                immutable ang = this.angle * rhs;
                if((rhs >= 0) == (this.wholerevolutions >= 0)){
                    return typeof(this)(whole) + ang + fract;
                }else{
                    return typeof(this)(whole) + ang - fract;
                }
            }
        }
    }
    /// Ditto
    auto opBinaryRight(string op: "*", N)(in N rhs) const if(isNumeric!N){
        return this * rhs;
    }
    /// Ditto
    auto opOpAssign(string op: "*", N)(in N rhs) if(isNumeric!N){
        this = this * rhs;
        return this;
    }
    
    /// Divide this rotation.
    auto opBinary(string op: "/", N)(in N rhs) const if(isNumeric!N){
        static if(isIntegral!N){
            immutable revsrhs = cast(RotRevs) rhs;
            if(revsrhs == 0){
                return typeof(this)(0);
            }else{
                alias AV = typeof(RotAngle.value);
                immutable quotient = this.wholerevolutions / revsrhs;
                immutable remainder = this.wholerevolutions % uabs(revsrhs);
                immutable x = typeof(this)(quotient) + this.angle / rhs;
                immutable fract = RotAngle(muldiv_xlty_wmax(cast(AV) remainder, cast(AV) uabs(revsrhs)));
                immutable sgn = (rhs >= 0) == (this.wholerevolutions >= 0);
                return sgn ? x + fract : x - fract;
            }
        }else{
            return this * (1 / rhs);
        }
    }
    /// Ditto
    auto opOpAssign(string op: "/", N)(in N rhs) if(isNumeric!N){
        this = this / rhs;
        return this;
    }
    
    /// Cast to another rotation type.
    auto opCast(To: Rotation!(AX, RX), AX, RX)() const{
        return To(this.angle, this.wholerevolutions);
    }
    /// Cast to an angle type.
    auto opCast(To: Angle!X, X)() const{
        return cast(To) this.angle;
    }
    
    /// Determine whether two rotations are equal.
    bool opEquals(AX, RX)(in Rotation!(AX, RX) rhs) const{
        return (
            this.wholerevolutions == rhs.wholerevolutions &&
            this.angle == rhs.angle
        );
    }
    /// Determine whether an angle and a rotation are equal.
    /// True only when `0 <= this.revolutions < 1.0`.
    /// To compare only the fractional revolution part,
    /// use `this.angle == angle` instead.
    bool opEquals(X)(in Angle!X rhs) const{
        return this.wholerevolutions == 0 && this.angle == rhs;
    }
    
    /// Assign to the amount of rotation represented by an Angle object.
    auto opAssign(X)(in Angle!X rhs){
        this.wholerevolutions = 0;
        this.angle = rhs;
    }
    
    /// Compare two rotations.
    int opCmp(AX, RX)(in Rotation!(AX, RX) rhs) const{
        if(this.wholerevolutions > rhs.wholerevolutions){
            return 1;
        }else if(this.wholerevolutions < rhs.wholerevolutions){
            return -1;
        }else{
            return this.angle.opCmp(rhs.angle);
        }
    }
    /// Compare a rotation to an angle.
    int opCmp(X)(in Angle!X rhs) const{
        if(this.wholerevolutions > 0){
            return 1;
        }else if(this.wholerevolutions < 0){
            return -1;
        }else{
            return this.angle.opCmp(rhs);
        }
    }
}



private version(unittest){
    import mach.meta : Aliases;
    import mach.traits : SignedIntegralTypes, UnsignedIntegralTypes;
    import mach.math.trig.arctangent : atan, atan2;
    import mach.math.trig.inverse : asin, acos;
    import mach.math.trig.sincos : sin, cos;
    import mach.math.trig.tangent : tan;
    import mach.math.floats.compare : fnearequal;
    import mach.math.floats.properties;
    import mach.math.constants;
    alias Rot = Rotation!(ulong, long);
}

unittest{ /// Comparison to other rotations
    foreach(UT; UnsignedIntegralTypes){
        foreach(ST; SignedIntegralTypes){
            assert(Rotation!(UT, ST).min < Rotation!(UT, ST).max);
            assert(Rotation!(UT, ST).min == Rotation!(UT, ST).min);
            assert(Rotation!(UT, ST).max == Rotation!(UT, ST).max);
            immutable rot = Rotation!(UT, ST)(0);
            assert(rot > Rotation!(UT, ST).min);
            assert(rot < Rotation!(UT, ST).max);
            assert(rot == rot);
            assert(rot >= rot);
            assert(rot <= rot);
        }
    }
}

unittest{ /// Comparison to Angle objects
    assert(Rot.Degrees(0) == Angle!ulong.Degrees(0));
    assert(Rot.Degrees(90) == Angle!ulong.Degrees(90));
    assert(Rot.Degrees(180) == Angle!ulong.Degrees(180));
    assert(Rot.Degrees(270) == Angle!ulong.Degrees(270));
    assert(Rot.Degrees(270) >= Angle!ulong.Degrees(270));
    assert(Rot.Degrees(270) <= Angle!ulong.Degrees(270));
    assert(Rot.Degrees(0) != Angle!ulong.Degrees(1));
    assert(Rot.Degrees(360) != Angle!ulong.Degrees(0));
    assert(Rot.Degrees(-90) != Angle!ulong.Degrees(90));
    assert(Rot.Degrees(-90) != Angle!ulong.Degrees(270));
    assert(Rot(+1.5) > Angle!ulong.Degrees(359));
    assert(Rot(+1.5) >= Angle!ulong.Degrees(359));
    assert(Rot(+0.5) < Angle!ulong.Degrees(359));
    assert(Rot(+0.5) <= Angle!ulong.Degrees(359));
    assert(Rot(-0.5) < Angle!ulong.Degrees(0));
    assert(Rot(-0.5) <= Angle!ulong.Degrees(0));
}

unittest{ /// Casting to other rotation types
    immutable rot = Rotation!(uint, int)(1);
    assert(rot.revolutions == 1);
    foreach(UT; UnsignedIntegralTypes){
        foreach(ST; SignedIntegralTypes){
            assert((cast(Rotation!(UT, ST)) rot).revolutions == 1);
        }
    }
}

unittest{ /// Cast to angle
    immutable prot = Rot(+123.25);
    Angle!ushort pangle = cast(Angle!ushort) prot;
    assert(pangle == prot.angle);
    immutable nrot = Rot(-123.25);
    Angle!ushort nangle = cast(Angle!ushort) nrot;
    assert(nangle == nrot.angle);
}

unittest{ /// Assignment to angle
    auto x = Rot(+100.5);
    x = Angle!uint.Revolutions(0.25);
    assert(x.revolutions == 0.25);
    auto y = Rot(-100.5);
    y = Angle!uint.Revolutions(0.75);
    assert(y.revolutions == 0.75);
}

unittest{ /// Degrees, radians, and revolutions
    immutable a = Rot.Radians(tau + pi);
    assert(a.radians == tau + pi);
    assert(a.degrees == 540);
    assert(a.revolutions == 1.5);
    immutable b = Rot.Degrees(540);
    assert(b.radians == tau + pi);
    assert(b.degrees == 540);
    assert(b.revolutions == 1.5);
    immutable c = Rot.Revolutions(1.5);
    assert(c.radians == tau + pi);
    assert(c.degrees == 540);
    assert(c.revolutions == 1.5);
    immutable d = Rot.Radians(-halfpi);
    assert(fnearequal(d.radians, -halfpi, 1e-16));
    assert(d.degrees == -90);
    assert(d.revolutions == -0.25);
    immutable e = Rot.Degrees(-90);
    assert(fnearequal(e.radians, -halfpi, 1e-16));
    assert(e.degrees == -90);
    assert(e.revolutions == -0.25);
    immutable f = Rot.Revolutions(-0.25);
    assert(fnearequal(f.radians, -halfpi, 1e-16));
    assert(f.degrees == -90);
    assert(f.revolutions == -0.25);
}

unittest{ /// Addition and subtraction of angles
    assert(Rot(0.00) + Angle!().Half == Rot(+0.5));
    assert(Rot(0.25) + Angle!().Half == Rot(+0.75));
    assert(Rot(0.75) + Angle!().Half == Rot(+1.25));
    assert(Rot(0.00) - Angle!().Half == Rot(-0.5));
    assert(Rot(0.25) - Angle!().Half == Rot(-0.25));
    assert(Rot(0.75) - Angle!().Half == Rot(+0.25));
    assert(Rot(-1.50) - Angle!().Quarter == Rot(-1.75));
    assert(Rot(-1.50) + Angle!().Quarter == Rot(-1.25));
    assert(Rot(-1.75) - Angle!().Quarter == Rot(-2.00));
    assert(Rot(-1.75) + Angle!().Quarter == Rot(-1.50));
}

unittest{ /// Addition and subtraction of rotations and angles
    enum inputs = [
        0.0L, 0.125L, 0.25L, 0.3L, 0.5L, 0.6L, 0.75L, 0.8L, 0.9L, 1.0L, 1.25L,
        1.41L, 1.5L, 1.55L, 2.0L, 2.25L, 2.8L, 3.0L, 3.75L, 4.25L, 8.0L, 9.55L,
        10.25L, 20.24L, 200.56L, 300.1L, 425.6L, 500.45L
    ];
    foreach(x; inputs){
        foreach(y; inputs){
            // Rotation +/- Rotation
            assert(fnearequal((Rot(+x) + Rot(+y)).revolutions, +x +y, 1e-12));
            assert(fnearequal((Rot(+x) + Rot(-y)).revolutions, +x -y, 1e-12));
            assert(fnearequal((Rot(-x) + Rot(+y)).revolutions, -x +y, 1e-12));
            assert(fnearequal((Rot(-x) + Rot(-y)).revolutions, -x -y, 1e-12));
            assert(fnearequal((Rot(+x) += Rot(+y)).revolutions, +x +y, 1e-12));
            assert(fnearequal((Rot(+x) += Rot(-y)).revolutions, +x -y, 1e-12));
            assert(fnearequal((Rot(-x) += Rot(+y)).revolutions, -x +y, 1e-12));
            assert(fnearequal((Rot(-x) += Rot(-y)).revolutions, -x -y, 1e-12));
            assert(fnearequal((Rot(+x) - Rot(+y)).revolutions, +x -y, 1e-12));
            assert(fnearequal((Rot(+x) - Rot(-y)).revolutions, +x +y, 1e-12));
            assert(fnearequal((Rot(-x) - Rot(+y)).revolutions, -x -y, 1e-12));
            assert(fnearequal((Rot(-x) - Rot(-y)).revolutions, -x +y, 1e-12));
            assert(fnearequal((Rot(+x) -= Rot(+y)).revolutions, +x -y, 1e-12));
            assert(fnearequal((Rot(+x) -= Rot(-y)).revolutions, +x +y, 1e-12));
            assert(fnearequal((Rot(-x) -= Rot(+y)).revolutions, -x -y, 1e-12));
            assert(fnearequal((Rot(-x) -= Rot(-y)).revolutions, -x +y, 1e-12));
            // Rotation +/- Angle
            immutable angle = Angle!().Revolutions(y);
            assert(fnearequal((Rot(+x) + angle).revolutions, +x + y%1, 1e-12));
            assert(fnearequal((Rot(+x) - angle).revolutions, +x - y%1, 1e-12));
            assert(fnearequal((Rot(-x) + angle).revolutions, -x + y%1, 1e-12));
            assert(fnearequal((Rot(-x) - angle).revolutions, -x - y%1, 1e-12));
            assert(fnearequal((Rot(+x) += angle).revolutions, +x + y%1, 1e-12));
            assert(fnearequal((Rot(+x) -= angle).revolutions, +x - y%1, 1e-12));
            assert(fnearequal((Rot(-x) += angle).revolutions, -x + y%1, 1e-12));
            assert(fnearequal((Rot(-x) -= angle).revolutions, -x - y%1, 1e-12));
        }
    }
}

unittest{ /// Negation and absolute value
    foreach(x; [0.0L, 0.25L, 0.5L, 0.8L, 1.0L, 1.41L, 1.5L, 2.0L, 2.25L, 8.75L]){
        immutable rotp = Rot(+x);
        assert(+rotp == rotp);
        assert(-rotp == Rot(-x));
        assert(-(-rotp) == rotp);
        assert(rotp.abs == rotp);
        assert((-rotp).abs == rotp);
        immutable rotn = Rot(-x);
        assert(+rotn == rotn);
        assert(-rotn == Rot(+x));
        assert(-(-rotn) == rotn);
        assert(rotn.abs == rotp);
        assert((-rotn).abs == rotp);
    }
}

unittest{ /// Increment and decrement
    foreach(UT; UnsignedIntegralTypes){
        auto rot = Rotation!UT(0);
        rot++;
        assert(rot > Rotation!UT(0));
        assert(rot < Rotation!UT(1));
        rot--;
        assert(rot == Rotation!UT(0));
        rot--;
        assert(rot < Rotation!UT(0));
        assert(rot > Rotation!UT(-1));
        rot++;
        assert(rot == Rotation!UT(0));
    }
}

unittest{ /// Rotation signof
    assert(Rot(+0.0).signof is Sign.Zero);
    assert(Rot(+0.1).signof is Sign.Positive);
    assert(Rot(+1.1).signof is Sign.Positive);
    assert(Rot(-0.1).signof is Sign.Negative);
    assert(Rot(-1.1).signof is Sign.Negative);
}

unittest{ /// Rotation direction
    // Unary
    assert(Rot(+1).direction is RotationDirection.Clockwise);
    assert(Rot(-1).direction is RotationDirection.Counterclockwise);
    assert(Rot(+0).direction is RotationDirection.None);
    // Binary
    assert(Rot(+1).direction(Rot(+2)) is RotationDirection.Clockwise);
    assert(Rot(+1).direction(Rot(-1)) is RotationDirection.Counterclockwise);
    assert(Rot(+1).direction(Rot(+1)) is RotationDirection.None);
}

unittest{ /// Multiply and divide special cases
    assert((Rot(0.5) * int(0)).revolutions == 0);
    assert((Rot(0.5) * uint(0)).revolutions == 0);
    assert((Rot(0.5) * double(0)).revolutions == 0);
    assert((Rot(0.5) * +double.infinity).revolutions == 0);
    assert((Rot(0.5) * -double.infinity).revolutions == 0);
    assert((Rot(0.5) * +double.nan).revolutions == 0);
    assert((Rot(0.5) * -double.nan).revolutions == 0);
    assert((Rot(0.5) *= int(0)).revolutions == 0);
    assert((Rot(0.5) *= uint(0)).revolutions == 0);
    assert((Rot(0.5) *= double(0)).revolutions == 0);
    assert((Rot(0.5) *= +double.infinity).revolutions == 0);
    assert((Rot(0.5) *= -double.infinity).revolutions == 0);
    assert((Rot(0.5) *= +double.nan).revolutions == 0);
    assert((Rot(0.5) *= -double.nan).revolutions == 0);
    assert((Rot(0.5) / int(0)).revolutions == 0);
    assert((Rot(0.5) / uint(0)).revolutions == 0);
    assert((Rot(0.5) / double(0)).revolutions == 0);
    assert((Rot(0.5) / +double.infinity).revolutions == 0);
    assert((Rot(0.5) / -double.infinity).revolutions == 0);
    assert((Rot(0.5) / +double.nan).revolutions == 0);
    assert((Rot(0.5) / -double.nan).revolutions == 0);
    assert((Rot(0.5) /= int(0)).revolutions == 0);
    assert((Rot(0.5) /= uint(0)).revolutions == 0);
    assert((Rot(0.5) /= double(0)).revolutions == 0);
    assert((Rot(0.5) /= +double.infinity).revolutions == 0);
    assert((Rot(0.5) /= -double.infinity).revolutions == 0);
    assert((Rot(0.5) /= +double.nan).revolutions == 0);
    assert((Rot(0.5) /= -double.nan).revolutions == 0);
    assert((2 * Rot(0.5)).revolutions == 1);
}
unittest{ /// Multiply and divide by integers
    foreach(T; Aliases!(int, long)){
        assert(Rot(+2.25) * T(+2) == Rot(+4.5));
        assert(Rot(+1.5) * T(+2) == Rot(+3.0));
        assert(Rot(+1.5) * T(-2) == Rot(-3.0));
        assert(Rot(-1.5) * T(+2) == Rot(-3.0));
        assert(Rot(-1.5) * T(-2) == Rot(+3.0));
        assert(Rot(+2.25) / T(+2) == Rot(+1.125));
        assert(Rot(+3.0) / T(+2) == Rot(+1.5));
        assert(Rot(+3.0) / T(-2) == Rot(-1.5));
        assert(Rot(-3.0) / T(+2) == Rot(-1.5));
        assert(Rot(-3.0) / T(-2) == Rot(+1.5));
    }
}
unittest{ /// Multiply and divide arbitrary floating point inputs
    enum inputs = [
        0.125L, 0.25L, 0.3L, 0.5L, 0.6L, 0.75L, 0.8L, 0.9L, 1.0L, 1.25L,
        1.41L, 1.5L, 1.55L, 2.0L, 2.25L, 2.8L, 3.0L, 3.75L, 4.0L, 4.25L, 8.0L,
        9.55L, 10.25L, 20.24L, 200.56L, 300.1L, 425.6L, 500.45L
    ];
    foreach(x; inputs){
        foreach(y; inputs){
            assert(fnearequal((Rot.Revolutions(+x) * +y).revolutions, +x * +y, 1e-12));
            assert(fnearequal((Rot.Revolutions(+x) * -y).revolutions, +x * -y, 1e-12));
            assert(fnearequal((Rot.Revolutions(-x) * +y).revolutions, -x * +y, 1e-12));
            assert(fnearequal((Rot.Revolutions(-x) * -y).revolutions, -x * -y, 1e-12));
            assert(fnearequal((Rot.Revolutions(+x) *= +y).revolutions, +x * +y, 1e-12));
            assert(fnearequal((Rot.Revolutions(+x) *= -y).revolutions, +x * -y, 1e-12));
            assert(fnearequal((Rot.Revolutions(-x) *= +y).revolutions, -x * +y, 1e-12));
            assert(fnearequal((Rot.Revolutions(-x) *= -y).revolutions, -x * -y, 1e-12));
            assert(fnearequal((Rot.Revolutions(+x) / +y).revolutions, +x / +y, 1e-12));
            assert(fnearequal((Rot.Revolutions(+x) / -y).revolutions, +x / -y, 1e-12));
            assert(fnearequal((Rot.Revolutions(-x) / +y).revolutions, -x / +y, 1e-12));
            assert(fnearequal((Rot.Revolutions(-x) / -y).revolutions, -x / -y, 1e-12));
            assert(fnearequal((Rot.Revolutions(+x) /= +y).revolutions, +x / +y, 1e-12));
            assert(fnearequal((Rot.Revolutions(+x) /= -y).revolutions, +x / -y, 1e-12));
            assert(fnearequal((Rot.Revolutions(-x) /= +y).revolutions, -x / +y, 1e-12));
            assert(fnearequal((Rot.Revolutions(-x) /= -y).revolutions, -x / -y, 1e-12));
        }
    }
}

unittest{ /// Linear interpolation between rotations
    immutable a = Rot(-1.5);
    immutable b = Rot(+1.5);
    assert(a.lerp(b, -1) == a);
    assert(a.lerp(b, 0) == a);
    assert(a.lerp(b, 1) == b);
    assert(a.lerp(b, 2) == b);
    assert(a.lerp(b, 0.5) == Rot(0));
    assert(a.lerp(b, 0.25) == Rot(-0.75));
    assert(a.lerp(b, 0.75) == Rot(+0.75));
    assert(b.lerp(a, -1) == b);
    assert(b.lerp(a, 0) == b);
    assert(b.lerp(a, 1) == a);
    assert(b.lerp(a, 2) == a);
    assert(b.lerp(a, 0.5) == Rot(0));
    assert(b.lerp(a, 0.25) == Rot(+0.75));
    assert(b.lerp(a, 0.75) == Rot(-0.75));
}

unittest{ /// Sine, cosine, arcsine, and arccosine
    foreach(rads; [
        0.0L, 0.1L, 0.25L, 0.5L, 0.8L, 1.0L, 2.0L, 3.0L, 10.0L,
        quarterpi, halfpi, pi, tau, tau + pi
    ]){
        immutable protsin = Rot.Radians(+rads).sin;
        immutable protcos = Rot.Radians(+rads).cos;
        immutable nrotsin = Rot.Radians(-rads).sin;
        immutable nrotcos = Rot.Radians(-rads).cos;
        assert(fnearequal(sin(+rads), protsin, 1e-12));
        assert(fnearequal(cos(+rads), protcos, 1e-12));
        assert(fnearequal(sin(-rads), nrotsin, 1e-12));
        assert(fnearequal(cos(-rads), nrotcos, 1e-12));
        assert(fnearequal(Rot.asin(protsin).radians, asin(protsin), 1e-12));
        assert(fnearequal(Rot.acos(protcos).radians, acos(protcos), 1e-12));
        assert(fnearequal(Rot.asin(nrotsin).radians, asin(nrotsin), 1e-12));
        assert(fnearequal(Rot.acos(nrotcos).radians, acos(nrotcos), 1e-12));
    }
    foreach(x; [0.0L, 0.1L, 0.15L, 0.2L, 0.25L, 0.5L, 0.8L, 0.9L, 1.0L]){
        assert(fnearequal(Rot.asin(+x).radians, asin(+x), 1e-12));
        assert(fnearequal(Rot.acos(+x).radians, acos(+x), 1e-12));
        assert(fnearequal(Rot.asin(-x).radians, asin(-x), 1e-12));
        assert(fnearequal(Rot.acos(-x).radians, acos(-x), 1e-12));
    }
}

unittest{ /// Tangent
    assert(Rot(+0.0).tan == 0);
    assert(Rot(+0.5).tan == 0);
    assert(Rot(+1.0).tan == 0);
    assert(Rot(-0.0).tan == 0);
    assert(Rot(-0.5).tan == 0);
    assert(Rot(-1.0).tan == 0);
    assert(Rot.Degrees(+90).tan.fisinf);
    assert(Rot.Degrees(+450).tan.fisinf);
    assert(Rot.Degrees(-90).tan.fisinf);
    assert(Rot.Degrees(-450).tan.fisinf);
    foreach(x; [0.0L, 0.25L, 0.5L, 0.8L, 0.9L, 1.0L, 2.0L, 3.0L, 5.0L, 10.0L]){
        assert(fnearequal(Rot.Radians(+x).tan, tan(+x), 1e-12));
        assert(fnearequal(Rot.Radians(-x).tan, tan(-x), 1e-12));
    }
}

unittest{ /// Arctangent
    assert(Rot.atan(+real.infinity).revolutions == +0.25);
    assert(Rot.atan(-real.infinity).revolutions == -0.25);
    enum inputs = [0.0L, 0.1L, 0.25L, 1.0L, 1.4L, 2.5L, 8.0L, 20.0L, 256.0L, real.infinity];
    foreach(x; inputs){
        assert(fnearequal(Rot.atan(+x).radians, atan(+x), 1e-12));
        assert(fnearequal(Rot.atan(-x).radians, atan(-x), 1e-12));
        foreach(y; inputs){
            assert(fnearequal(Rot.atan2(+x, +y).radians, atan2(+x, +y), 1e-12));
            assert(fnearequal(Rot.atan2(+x, -y).radians, atan2(+x, -y), 1e-12));
            assert(fnearequal(Rot.atan2(-x, +y).radians, atan2(-x, +y), 1e-12));
            assert(fnearequal(Rot.atan2(-x, -y).radians, atan2(-x, -y), 1e-12));
        }
    }
}

unittest{ /// NaN inputs for inverse trigonometric functions
    assert(Rot.asin(real.nan) == Rot(0));
    assert(Rot.acos(real.nan) == Rot(0));
    assert(Rot.atan(real.nan) == Rot(0));
    assert(Rot.atan2(0, real.nan) == Rot(0));
    assert(Rot.atan2(real.nan, 0) == Rot(0));
    assert(Rot.atan2(real.nan, real.nan) == Rot(0));
}
