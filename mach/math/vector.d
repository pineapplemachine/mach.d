module mach.math.vector;

private:

import mach.meta : All, Repeat, Retro, varzip, varmap, varmapi, varall, varsum, ctint;
import mach.types : tuple, isTuple;
import mach.traits : isTemplateOf, CommonType, hasCommonType, Unqual;
import mach.traits : isNumeric, isFloatingPoint, isIntegral, isSignedIntegral;
import mach.error : IndexOutOfBoundsError;
import mach.text.str : str;
import mach.math.abs : abs;
import mach.math.sqrt : sqrt;
import mach.math.trig : Angle;
import mach.math.matrix : Matrix;

/// Get whether a type is some Angle type.
template isAngle(T){
    enum bool isAngle = isTemplateOf!(T, Angle);
}

/++ Docs

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

+/

unittest{ /// Example
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
}

/++ Docs

Vectors support component-wise binary operations with other vectors of the
same dimensionality, as well as a dot product.
They can also be multiplied or divided by scalars.
Three-dimensional vectors additionally support a cross product operation.

+/

unittest{ /// Example
    assert(vector(1, 2, 3) * 2 == vector(2, 4, 6));
    assert(vector(2, 4, 16) / 2 == vector(1, 2, 8));
    assert(vector(1, 2, 3) + vector(3, 4, 5) == vector(4, 6, 8));
    assert(vector(3, 2, 1) - vector(1, 1, 1) == vector(2, 1, 0));
    assert(vector(1, 2, 3) * vector(-1, -2, -3) == vector(-1, -4, -9));
    assert(vector(8, 9, 10) / vector(2, 3, 5) == vector(4, 3, 2));
    assert(vector(1, 2, 3).dot(vector(4, 5, 6)) == 32);
    assert(vector(1, 2, 3).cross(vector(3, 2, 1)) == vector(-4, 8, -4));
    assert(-vector(1, 2) == vector(-1, -2)); // Vectors also allow component-wise negation
}

/++ Docs

The `length` method may be used to get the magnitude of the vector.
(By contrast, the `size` attribute represents the dimensionality of the vector.)
A `lengthsq` method is provided to obtain the squared magnitude, which is
faster than `length`.
The `distance` and `distancesq` methods may similarly be used to get the
Euclidean distance between two vectors.

The `normalize` method returns a unit vector pointing in the same direction
as the input vector.

+/

unittest{ /// Example
    assert(vector(3, 4).length == 5);
    assert(vector(3, 4).lengthsq == 25);
    assert(vector(1, 2, 3).distance(vector(5, 2, 6)) == 5);
    assert(vector(1, 2, 3).distancesq(vector(5, 2, 6)) == 25);
}

unittest{ /// Example
    import mach.math.floats.compare : fnearequal;
    assert(fnearequal(vector(4, 5).normalize.length, 1, 1e-16));
}

/++ Docs

In addition to comparison using the equality operator, Vector types also
provide an `equals` method which accepts an optional per-component epsilon,
defining the maximum deviation of any component in one vector from the
corresponding component in the other vector required before the vectors are
considered unequal.

+/

unittest{ /// Example
    assert(Vector2!double(1, 2) == Vector2!int(1, 2));
    assert(Vector3!int(1, 2, 3).equals(Vector3!float(1, 2, 3)));
    assert(Vector4!double(1, 2, 3, 4).equals(Vector4!double(1, 2, 3, 4 + 1e-10), 1e-8));
}

/++ Docs

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

+/

unittest{ /// Example
    import mach.math.trig.angle : Angle;
    assert(vector(0, 1).angle(vector(1, 0)).degrees == 90);
    assert(vector(1, 1).direction.degrees == 45);
    assert(Vector2f.unit(Angle!().Degrees(90)) == vector(0, 1));
}

unittest{ /// Example
    import mach.math.floats.compare : fnearequal;
    auto dir = vector(0, +2, -2).direction;
    assert(fnearequal(dir[0].degrees, 90, 1e-12));
    assert(fnearequal(dir[1].degrees, 315, 1e-12));
}

unittest{ /// Example
    auto vec = Vector4f(-2, -1, +1, +2);
    auto dir = vec.direction;
    assert(vec.equals(Vector4f.unit(dir) * vec.length, 1e-8));
}

/++ Docs

The `reflect` method may be used to get the reflection of a vector against the
plane perpendicular to a normal.
The `project` method gets a projection of the input upon a normal vector;
it returns a vector the same length as the input, pointing in the direction
of a given normal.

+/

unittest{ /// Example
    assert(vector(3, 4).reflect(vector(1, -1).normalize).equals(vector(-4, -3), 1e-8));
}

unittest{ /// Example
    assert(vector(4, 3).project(vector(-1, 0)) == vector(-5, 0));
}

public:



/// Determine whether some type is a Vector of any dimensionality and
/// component type.
template isVector(T){
    enum bool isVector = isTemplateOf!(T, Vector);
}
/// Determine whether some type is a Vector of the given dimensionality and
/// of any component type.
template isVector(size_t size, T){
    static if(isVector!T){
        enum bool isVector = T.size == size;
    }else{
        enum bool isVector = false;
    }
}



/// Indicates whether a Vector may have this type as its component type.
template isVectorComponent(T){
    enum bool isVectorComponent = isFloatingPoint!T || isSignedIntegral!T;
}

/// Determine whether a Vector could be created from arguments of the given
/// types; essentially checks whether they have a common signed numeric type.
template canVector(T...){
    static if(T.length && hasCommonType!T){
        enum bool canVector = isVectorComponent!(CommonType!T);
    }else{
        enum bool canVector = false;
    }
}



/// Get a vector with the given components.
auto vector(Args...)(in Args args) if(canVector!Args){
    return Vector!(Args.length, CommonType!Args)(args);
}

/// Get a vector with components represented by the values in some tuple.
auto vector(T)(in T tup) if(!canVector!T && !isVector!T && isTuple!T){
    static assert(T.length, "Cannot instantiate with empty tuple.");
    return vector(tup.expand);
}

/// Get a vector with no components.
auto vector(T)() if(isVectorComponent!T){
    return Vector!(0, T).zero;
}



/// Perform a map operation upon the components of a vector
auto map(alias transform, T)(T mapVector) if(isVector!T) {
    static if(mapVector.size == 0) {
        return mapVector;
    }else {
        return vector(mapVector.expand.varmap!transform);
    }
}

/// Perform a map operation upon the components of a vector
/// The transform callback will also receive a component index argument
auto mapi(alias transform, T)(T mapVector) if(isVector!T) {
    static if(mapVector.size == 0) {
        return mapVector;
    }else {
        return vector(mapVector.expand.varmapi!transform);
    }
}

/// Perform a map operation upon the components of multiple input vectors
auto map(alias transform, T...)(T mapVectors) if(T.length != 1 && All!(isVector, T)) {
    return vector(mapVectors.varmap!((v) => (v.astuple)).expand.varzip.expand.varmap!(
        (tup) => (transform(tup.expand))
    ));
}

/// Perform a map operation upon the components of multiple input vectors
/// The transform callback will also receive a component index argument
auto mapi(alias transform, T...)(T mapVectors) if(T.length != 1 && All!(isVector, T)) {
    return vector(mapVectors.varmap!((v) => (v.astuple)).expand.varzip.expand.varmapi!(
        (index, tup) => (transform(index, tup.expand))
    ));
}



/// Convenience template for getting whether a type is a vector with two components.
template isVector2(T){
    enum bool isVector2 = isVector!(2, T);
}
/// Convenience template referring to a Vector type with two components.
template Vector2(T){
    alias Vector2 = Vector!(2, T);
}
/// Convenience alias referring to a Vector type with two floating point components.
alias Vector2f = Vector2!double;
/// Convenience alias referring to a Vector type with two integral components.
alias Vector2i = Vector2!long;

/// Convenience template for getting whether a type is a vector with three components.
template isVector3(T){
    enum bool isVector3 = isVector!(3, T);
}
/// Convenience template referring to a Vector type with three components.
template Vector3(T){
    alias Vector3 = Vector!(3, T);
}
/// Convenience alias referring to a Vector type with three floating point components.
alias Vector3f = Vector3!double;
/// Convenience alias referring to a Vector type with three integral components.
alias Vector3i = Vector3!long;

/// Convenience template for getting whether a type is a vector with four components.
template isVector4(T){
    enum bool isVector4 = isVector!(4, T);
}
/// Convenience template referring to a Vector type with four components.
template Vector4(T){
    alias Vector4 = Vector!(4, T);
}
/// Convenience alias referring to a Vector type with four floating point components.
alias Vector4f = Vector4!double;
/// Convenience alias referring to a Vector type with four integral components.
alias Vector4i = Vector4!long;



/// Given two Vector types, determine which should win out in a type promotion.
private template CommonVectorType(VA: Vector!(size, A), VB: Vector!(size, B), size_t size, A, B){
    static if(isFloatingPoint!(A) == isFloatingPoint!(B)){
        static if(A.sizeof >= B.sizeof){
            alias CommonVectorType = VA;
        }else{
            alias CommonVectorType = VB;
        }
    }else static if(isFloatingPoint!(A)){
        alias CommonVectorType = VA;
    }else{
        alias CommonVectorType = VB;
    }
}



/// Mixin used to implement the `Vector.directiontup` method.
private string VectorDirectionTupMixin(in size_t size){
    string squares = `immutable sq` ~ ctint(size - 2) ~ ` = (` ~
        `this.values[$-1] * this.values[$-1] + this.values[$-2] * this.values[$-2]` ~
    `); `;
    foreach(i; 1 .. size - 1){
        immutable j = (size - 2) - i;
        immutable jstr = ctint(j);
        squares ~= `immutable sq` ~ ctint(j) ~ ` = sq` ~ ctint(j + 1) ~ ` + (` ~
            `this.values[` ~ jstr ~ `] * this.values[` ~ jstr ~ `]` ~
        `); `;
    }
    string ret = ``;
    foreach(i; 0 .. size - 2){
        if(ret.length) ret ~= `, `;
        immutable istr = ctint(i);
        ret ~= `Angle!().acos(this.values[` ~ istr ~ `] / sqrt(sq` ~ istr ~ `))`;
    }
    if(ret.length) ret ~= `, `;
    immutable lastterm = `Angle!().acos(this.values[$-2] / sqrt(sq` ~ ctint(size - 2) ~ `))`;
    ret ~= `this.values[$-1] >= 0 ? ` ~ lastterm ~ ` : ~` ~ lastterm;
    return squares ~ ` return tuple(` ~ ret ~ `);`;
}

/// Mixin used to implement the `Vector.unit` method.
private string VectorUnitMixin(in size_t size){
    string sines = `immutable sin0 = angles[0].sin; `;
    foreach(i; 1 .. size - 1){
        immutable istr = ctint(i);
        sines ~= (
            `immutable sin` ~ istr~ ` = ` ~
            `angles[` ~ istr ~ `].sin * sin` ~ ctint(i - 1) ~ `;`
        );
    }
    string ret = "angles[0].cos, ";
    foreach(i; 1 .. size - 1){
        ret ~= `angles[` ~ ctint(i) ~ `].cos * sin` ~ ctint(i - 1) ~ `, `;
    }
    ret ~= `sin` ~ ctint(size - 2);
    return sines ~ ` return typeof(this)(` ~ ret ~ `);`;
}



/// Arbitrary-dimensionality vector type with signed numeric components.
/// TODO: It might be a good idea to also support unsigned integers at some
/// point, but that will complicate promotions and could be generally weird.
struct Vector(size_t valuessize, T) if(isVectorComponent!T){
    alias size = valuessize;
    alias opDollar = size;
    
    /// Magnitude type. `double` when the component type is an integer,
    /// otherwise the component type itself.
    static if(isFloatingPoint!T) alias Magnitude = T;
    else alias Magnitude = double;
    
    /// Helper template to get whether another type is a Vector with the same
    /// dimensionality as this one.
    static enum isSameSizeVector(X) = isVector!(size, X);
    
    /// A vector with all-zero components.
    static enum zero = typeof(this).fill(0);
    
    alias Value = T;
    alias Values = Repeat!(size, T);
    
    Values values;
    alias expand = values;
    alias values this;
    
    /// Initialize with the given components.
    /// Excessive components are truncated.
    /// Missing components are set to zero.
    this(N...)(in N values) if(values.length && All!(isNumeric, N)){
        foreach(i, _; this.values) {
            static if(i < values.length) this.values[i] = cast(T) values[i];
            else this.values[i] = T(0);
        }
    }
    
    /// Initialize with the components of another vector.
    /// If the input vector is smaller than this one, trailing components
    /// are made zero.
    /// If the input vector is larger than this one, trailing components are
    /// truncated.
    this(size_t Z, X)(in Vector!(Z, X) vec){
        foreach(i, _; this.values){
            static if(i < vec.size) this.values[i] = cast(T) vec.values[i];
            else this.values[i] = T(0);
        }
    }
    
    /// Initialize with components given by a dynamic array
    this(N)(in N[] array) if(isNumeric!N) {
        foreach(i, _; this.values){
            if(i < array.length) this.values[i] = cast(T) array[i];
            else this.values[i] = T(0);
        }
    }
    
    /// Initialize with components given by a static array
    this(size_t Z, N)(in N[Z] array) if(isNumeric!N) {
        foreach(i, _; this.values){
            static if(i < array.length) this.values[i] = cast(T) array[i];
            else this.values[i] = T(0);
        }
    }
    
    /// Initialize with components given by a tuple.
    this(X)(in X tup) if(isTuple!X){ // TODO: Better template constraint
        static if(tup.length) this(tup.expand);
    }
    
    /// Initialize with all components equal to the given value.
    static fill(N)(in N value) if(isNumeric!N){
        return typeof(this)(Repeat!(size, value));
    }
    
    /// Get this vector as a tuple.
    @property auto astuple() const{
        return tuple(this.expand);
    }
    
    /// Refers to the first component, if present.
    static if(size >= 1) alias x = typeof(this).values[0];
    /// Refers to the second component, if present.
    static if(size >= 2) alias y = typeof(this).values[1];
    /// Refers to the third component, if present.
    static if(size >= 3) alias z = typeof(this).values[2];
    /// Refers to the fourth component, if present.
    static if(size >= 4) alias w = typeof(this).values[3];
    
    /// Get a vector whose components are equal to the negations of this
    /// vector's components.
    auto opUnary(string op: "-")() const{
        static if(size == 0){
            return this;
        }else{
            return vector(this.expand.varmap!(x => -x));
        }
    }
    /// Returns the vector itself.
    auto opUnary(string op: "+")() const{
        return this;
    }
    
    /// Component-wise binary operation with a vector having the same number
    /// of components.
    auto opBinary(string op, X)(in Vector!(size, X) vec) const if(
        op == "+" || op == "-" || op == "*" || op == "/" || op == "%" || op == "^^"
    ){
        static if(size == 0){
            mixin(`return vector!(typeof(T.init ` ~ op ~ ` X.init))();`);
        }else{
            return vector(varzip(this.astuple, vec.astuple).expand.varmap!((x){
                mixin(`return x[0] ` ~ op ~ ` x[1];`);
            }));
        }
    }
    /// Ditto
    auto opOpAssign(string op, X)(in Vector!(size, X) vec) if(
        op == "+" || op == "-" || op == "*" || op == "/" || op == "%" || op == "^^"
    ){
        foreach(i, _; Values){
            mixin(`this[i] = this[i] ` ~ op ~ ` vec[i];`);
        }
        return this;
    }
    
    /// Increment, decrement, multiply, divide, or exponentiate all components
    /// in the vector by some scalar value.
    auto opBinary(string op, N)(in N value) const if(isNumeric!N && (
        op == "+" || op == "-" || op == "*" || op == "/" || op == "%" || op == "^^"
    )){
        static if(size == 0){
            mixin(`return vector!(typeof(T.init ` ~ op ~ ` value))();`);
        }else{
            return vector(this.expand.varmap!((x){
                mixin(`return x ` ~ op ~ ` value;`);
            }));
        }
    }
    /// Ditto
    auto opBinaryRight(string op: "*", N)(in N value) const if(isNumeric!N){
        return this.opBinary!(op)(value);
    }
    /// Ditto
    auto opOpAssign(string op, N)(in N value) if(isNumeric!N && (
        op == "+" || op == "-" || op == "*" || op == "/" || op == "%" || op == "^^"
    )){
        foreach(i, _; Values) mixin(`this[i] ` ~ op ~ `= value;`);
        return this;
    }
    
    /// Perform a component-wise multiplication of two vectors.
    /// Currently, this is equivalent to the expression `vec0 * vec1`.
    auto scale(X)(in Vector!(size, X) vec) const{
        return this * vec;
    }
    
    /// Perform a component-wise comparison of two vectors.
    bool opEquals(X)(in Vector!(size, X) vec) const{
        return this.equals(vec);
    }
    
    /// Component-wise equality comparison with optional epsilon.
    /// Epsilon is evaluated per-component.
    bool equals(X, E)(in Vector!(size, X) vec, in E epsilon) const if(isNumeric!E){
        assert(epsilon >= 0, "Epsilon must be non-negative.");
        foreach(i, _; Values){
            immutable delta = this[i] - vec[i];
            if(delta < -epsilon || delta > epsilon) return false;
        }
        return true;
    }
    /// Ditto
    bool equals(X)(in Vector!(size, X) vec) const{
        foreach(i, _; Values){
            if(this.values[i] != vec.values[i]) return false;
        }
        return true;
    }
    
    /// Get the dot product of this and another vector.
    auto dot(X)(in Vector!(size, X) vec) const{
        static if(size == 0){
            return typeof(T.init * X.init)(0);
        }else{
            return (this * vec).values.varsum;
        }
    }
    
    /// Get the cross product of this and another three-dimensional vector.
    static if(size == 3) auto cross(X)(in Vector!(size, X) vec) const{
        return vector(
            this.y * vec.z - this.z * vec.y,
            this.z * vec.x - this.x * vec.z,
            this.x * vec.y - this.y * vec.x,
        );
    }
    
    /// Get the magnitude of this vector.
    @property Magnitude length() const{
        static if(size == 0){
            return 0;
        }else{
            return sqrt(this.lengthsq);
        }
    }
    /// Get the squared magnitude of this vector.
    @property Magnitude lengthsq() const{
        static if(size == 0){
            return 0;
        }else{
            immutable squares = this.expand.varmap!(x => cast(Magnitude) x * x);
            return varsum(squares.expand);
        }
    }
    /// Get the squared magnitude of a vector with integral components.
    /// Faster than `lengthsq`, but may overflow for large components.
    static if(isIntegral!T) @property Magnitude ilengthsq() const{
        static if(size == 0){
            return 0;
        }else{
            return (this * this).values.varsum;
        }
    }
    
    /// Get a vector pointing in the same direction as this one, but with its
    /// magnitude clamped.
    auto clamplength(N)(in N length) const if(isNumeric!N){
        static if(size == 0){
            return vector!(typeof(T.init * (length / Magnitude.init)))();
        }else static if(size == 1){
            if(this.x >= 0){
                return vector(length < this.x ? length : this.x);
            }else{
                return vector(-length > this.x ? -length : this.x);
            }
        }else{
            immutable currentlen = this.length;
            if(currentlen > length){
                return this * (length / currentlen);
            }else{
                return Vector!(size, typeof(T.init * (length / currentlen)))(this);
            }
        }
    }
    
    /// Get the Manhattan distance of this vector from the origin.
    auto manhattan() const{
        static if(size == 0){
            return 0;
        }else{
            return this.values.varmap!(x => abs(x)).expand.varsum;
        }
    }
    /// Get the Manhattan distance of this vector from another.
    auto manhattan(X)(in Vector!(size, X) vec) const{
        return (this - vec).manhattan();
    }
    
    /// Get the distance between two vectors.
    auto distance(X)(in Vector!(size, X) vec) const{
        return (this - vec).length;
    }
    /// Get the squared distance between two vectors.
    auto distancesq(X)(in Vector!(size, X) vec) const{
        return (this - vec).lengthsq;
    }
    /// Get the squared distance between two vectors with integral components.
    /// Faster than `distancesq`, but may overflow for large component deltas.
    static if(isIntegral!T) @property Magnitude idistancesq(X)(
        in Vector!(size, X) vec
    ) const if(isIntegral!X){
        return (this - vec).ilengthsq;
    }
    
    /// Linearly interpolate between two vectors.
    /// The input is clamped to be in the range [0, 1].
    auto lerp(X)(in Vector!(size, X) vec, in Magnitude t) const{
        alias Result = typeof(this.lerpuc(vec, t));
        if(t <= 0) return cast(Result) this;
        else if(t >= 1) return cast(Result) vec;
        else return this.lerpuc(vec, t);
    }
    /// Linearly interpolate between two vectors.
    /// The input is not clamped.
    auto lerpuc(X)(in Vector!(size, X) vec, in Magnitude t) const{
        return this + ((vec - this) * t);
    }
    
    /// Spherically interpolate between two vectors.
    /// The input is clamped to be in the range [0, 1].
    auto slerp(X)(in Vector!(size, X) vec, in Magnitude t) const{
        alias Result = typeof(this.slerpuc(vec, t));
        if(t <= 0) return cast(Result) this;
        else if(t >= 1) return cast(Result) vec;
        else return this.slerpuc(vec, t);
    }
    /// Spherically interpolate between two vectors.
    /// The input is not clamped.
    /// https://en.wikipedia.org/wiki/Slerp
    auto slerpuc(X)(in Vector!(size, X) vec, in Magnitude t) const{
        immutable thisnormal = this.normalize();
        immutable vecnormal = vec.normalize();
        immutable dot = thisnormal.dot(vecnormal);
        static auto impl(
            in Magnitude t,
            in typeof(dot) dot,
            in typeof(thisnormal) thisnormal,
            in typeof(vecnormal) vecnormal
        ){
            immutable x = Angle!().acos(dot);
            immutable sinx = x.sin;
            immutable a = ((1 - t) * x).sin / sinx * thisnormal;
            immutable b = (t * x).sin / sinx * vecnormal;
            return a + b;
        }
        immutable ilen = this.length * (1 - t) + vec.length  * t;
        if(dot >= 0){
            return ilen * impl(t, dot, thisnormal, vecnormal);
        }else{
            return ilen * impl(t, -dot, thisnormal, -vecnormal);
        }
    }
    
    /// Get a normalization of this vector, i.e. `vector / vector.length`.
    /// The normalization of a vector with all-zero components is a vector with
    /// all-NaN components.
    auto normalize() const{
        static if(size == 0){
            return this;
        }else static if(size == 1){
            if(this.x > 0) return vector(Magnitude(+1));
            else if(this.x < 0) return vector(Magnitude(-1));
            else return vector(Magnitude.nan);
        }else{
            return this / this.length();
        }
    }
    
    /// Get a reflection of this vector on the plane perpendicular to a unit vector.
    /// http://mathworld.wolfram.com/Reflection.html
    /// hhttp://math.stackexchange.com/questions/13261/how-to-get-a-reflection-vector
    auto reflect(X)(in Vector!(size, X) normal) const{
        return 2 * this.dot(normal) * normal - this;
    }
    
    /// Get a projection of this vector onto a unit vector.
    auto project(X)(in Vector!(size, X) normal) const{
        return normal * this.length;
    }
    
    /// Get the angle between this vector and another as an Angle object.
    /// http://onlinemschool.com/math/library/vector/angl/
    auto angle(X)(in Vector!(size, X) vec) const{
        return Angle!().acos(this.dot(vec) / (this.length * vec.length));
    }
    
    /// Get an angle or angle respresenting the direction from the origin to
    /// this vector, represented a tuple of Angle objects.
    /// When size is less than two, an empty tuple is returned.
    auto directiontup() const{
        static if(size <= 1){
            return tuple();
        }else static if(size == 2){
            return tuple(Angle!().atan2(this.y, this.x));
        }else{
            mixin(VectorDirectionTupMixin(size));
        }
    }
    /// Get an angle or angles representing the direction from this vector to
    /// another, represented a tuple of Angle objects.
    /// When size is less than two, an empty tuple is returned.
    auto directiontup(X)(in Vector!(size, X) vec) const{
        return (vec - this).directiontup;
    }
    /// Get an angle or angle respresenting the direction from the origin to
    /// this vector, represented a tuple of Angle objects except for the case where
    /// the vectors have two dimensions, in which case a single unencapsulated
    /// Angle object is returned.
    auto direction() const{
        static if(size == 2){
            return this.directiontup()[0];
        }else{
            return this.directiontup();
        }
    }
    /// Get an angle or angles representing the direction from this vector to
    /// another, represented a tuple of Angle objects except for the case where
    /// the vectors have two dimensions, in which case a single unencapsulated
    /// Angle object is returned.
    auto direction(X)(in Vector!(size, X) vec) const{
        return (vec - this).direction;
    }
    
    /// Get the unit vector pointing in a given direction.
    /// This function is defined only for vectors with at least two components.
    /// `unit(vector.direction) * vector.length` should be closely equal
    /// to `vector`. (Rounding errors may introduce inaccuracies.)
    /// The function may be called with Angle objects or with floating point
    /// values representing values in radians.
    /// https://en.wikipedia.org/wiki/N-sphere#Spherical_coordinates
    static if(size > 1){
        static auto unit(A...)(in A angles) if(A.length == size - 1 && All!(isAngle, A)){
            mixin(VectorUnitMixin(size));
        }
        static auto unit(A...)(in A angles) if(A.length == size - 1 && All!(isNumeric, A)){
            return typeof(this).unit(angles.varmap!(a => Angle!().Radians(a)).expand);
        }
        static auto unit(X)(in X tup) if(isTuple!X){
            static assert(tup.length == size - 1,
                "Tuple contains an incorrect number of elements."
            );
            return unit(tup.expand);
        }
    }
    
    /// Get the cross product matrix of a three-dimensional vector.
    /// The cross-product of two vectors may b defined as
    /// `a.cross(b) == a.crossmat * b` or as
    /// `a.cross(b) == b.crossmat.transpose * a`.
    static if(size == 3 && isSignedIntegral!T) @property auto crossmat() const{
        return Matrix!(3, 3, T)(
            0, this.z, -this.y,
            -this.z, 0, this.x,
            this.y, -this.x, 0,
        );
    }
    
    /// Get a concatenation of vectors.
    auto concat(V...)(in V vectors) const if(All!(isVector, V)){
        auto tup = this.astuple.concat(vectors.varmap!(v => v.astuple).expand);
        static if(tup.length){
            return vector(tup);
        }else{
            return this;
        }
    }
    /// Ditto
    auto opBinary(string op: "~", Z, V)(in Vector!(Z, V) vec) const{
        return this.concat(vec);
    }
    
    /// Get a slice of this vector as another vector.
    auto slice(size_t low, size_t high)() const{
        static assert(low >= 0 && high >= low && size >= high, "Invalid slice.");
        static if(high == low){
            return vector!T();
        }else{
            return vector(this.values[low .. high]);
        }
    }
    
    /// Get the component at an index known at compile time.
    /// Same as `vector[i]`.
    auto ref index(size_t i)(){
        return this.values[i];
    }
    /// Ditto
    auto ref index(size_t i)() const{
        return this.values[i];
    }
    /// Get the component at an index known only at runtime.
    /// Throws an `IndexOutOfBoundsError` if the index was out of bounds.
    auto ref index()(in size_t i){
        static const error = new IndexOutOfBoundsError();
        foreach(j, _; this.values){
            if(i == j) return this.values[j];
        }
        throw error;
    }
    /// Ditto
    auto ref index()(in size_t i) const{
        static const error = new IndexOutOfBoundsError();
        foreach(j, _; this.values){
            if(i == j) return this.values[j];
        }
        throw error;
    }
    
    /// Get a vector the same as this one, but with its components in
    /// reverse-order.
    auto flip() const{
        static if(size <= 1){
            return this;
        }else{
            return typeof(this)(Retro!(this.values));
        }
    }
    
    /// Cast to another vector type.
    /// If the target type is smaller, trailing components are truncated.
    /// If the target type is larger, trailing components will be zero.
    auto opCast(To: Vector!(Z, X), size_t Z, X)() const{
        return To(this);
    }
    
    /// Get a readable string representation.
    auto toString() const{
        return str(this.astuple);
    }
    
    // The following ugly block of code is to support swizzling.
    // https://www.khronos.org/opengl/wiki/Data_Type_(GLSL)#Swizzling
    static if(size == 1) static enum SwizzleCharacters = "x";
    else static if(size == 2) static enum SwizzleCharacters = "xy";
    else static if(size == 3) static enum SwizzleCharacters = "xyz";
    else static if(size == 4) static enum SwizzleCharacters = "xyzw";
    else static enum SwizzleCharacters = "";
    private static string SwizzlesMixin(){
        string codegen = "";
        foreach(i; SwizzleCharacters){
            foreach(j; SwizzleCharacters){
                auto ij = [i] ~ j;
                auto tij = `this.` ~ i ~ `, this.` ~ j;
                codegen ~= `
                    @property auto ` ~ ij ~ `() const{
                        return vector(` ~ tij ~ `);
                    }
                `;
                if(i != j) codegen ~= `
                    @property void ` ~ ij ~ `(X)(in Vector!(2, X) vec){
                        this.` ~ i ~ ` = vec.x;
                        this.` ~ j ~ ` = vec.y;
                    }
                `;
                foreach(k; SwizzleCharacters){
                    auto ijk = ij ~ k;
                    auto tijk = tij ~ `, this.` ~ k;
                    codegen ~= `
                        @property auto ` ~ ijk ~ `() const{
                            return vector(` ~ tijk ~ `);
                        }
                    `;
                    if(i != j && i != k && j != k) codegen ~= `
                        @property void ` ~ ijk ~ `(X)(in Vector!(3, X) vec){
                            this.` ~ i ~ ` = vec.x;
                            this.` ~ j ~ ` = vec.y;
                            this.` ~ k ~ ` = vec.z;
                        }
                    `;
                    foreach(l; SwizzleCharacters){
                        auto ijkl = ijk ~ l;
                        auto tijkl = tijk ~ `, this.` ~ l;
                        codegen ~= `
                            @property auto ` ~ ijkl ~ `() const{
                                return vector(` ~ tijkl ~ `);
                            }
                        `;
                        if(i != j && i != k && i != l && j != k && j != l && k != l) codegen ~= `
                            @property void ` ~ ijkl ~ `(X)(in Vector!(4, X) vec){
                                this.` ~ i ~ ` = vec.x;
                                this.` ~ j ~ ` = vec.y;
                                this.` ~ k ~ ` = vec.z;
                                this.` ~ l ~ ` = vec.w;
                            }
                        `;
                    }
                }
            }
        }
        return codegen;
    }
    static if(size > 0 && size <= 4){
        mixin(SwizzlesMixin());
    }
}



private version(unittest){
    import mach.meta : Aliases, varall;
    import mach.math.floats : fisinf, fisnan, fnearequal;
    import mach.test.assertthrows : assertthrows;
    // Sequence of types that a Vector can legally be made from.
    alias Types = Aliases!(byte, short, int, long, float, double, real);
}

unittest{ /// Instantiation of vectors of various types and dimensionality
    foreach(dim; Aliases!(1, 2, 3, 4, 5, 6)){
        foreach(T; Types){
            immutable vec = vector(Repeat!(dim, T(1)));
            static assert(vec.size == dim);
            assert(vec.x == 1);
            assert(vec[0] == 1);
            assert(vec[$-1] == 1);
        }
    }
}

unittest{ /// isVector templates
    static assert(isVector!(Vector2i));
    static assert(isVector!(Vector3i));
    static assert(isVector!(Vector4i));
    static assert(isVector!(Vector!(0, int)));
    static assert(!isVector!(int));
    static assert(!isVector!(int[]));
    static assert(!isVector!(int[4]));
    static assert(!isVector!(void));
    static assert(isVector2!(Vector2i));
    static assert(isVector2!(Vector2f));
    static assert(!isVector2!(int));
    static assert(!isVector2!(Vector3i));
    static assert(!isVector2!(void));
    static assert(isVector3!(Vector3i));
    static assert(isVector3!(Vector3f));
    static assert(!isVector3!(int));
    static assert(!isVector3!(Vector4i));
    static assert(!isVector3!(void));
    static assert(isVector4!(Vector4i));
    static assert(isVector4!(Vector4f));
    static assert(!isVector4!(int));
    static assert(!isVector4!(Vector2i));
    static assert(!isVector4!(void));
}

unittest{ /// Zero-length vector (Why would you even do this??)
    Vector!(0, int) vec;
    assert(vec.zero == vec);
    assert(vec.length == 0);
    assert(vec.lengthsq == 0);
    assert(vec.ilengthsq == 0);
    assert(vec.distance(vec) == 0);
    assert(vec.distancesq(vec) == 0);
    assert(vec.idistancesq(vec) == 0);
    assert(vec.manhattan == 0);
    assert(vec.manhattan(vec) == 0);
    assert(vec == vec);
    assert(vec == +vec);
    assert(vec == -vec);
    assert(vec + vec == vec);
    assert(vec * 2 == vec);
    assert(vec.dot(vec) == 0);
    assert(vec.normalize == vec);
    assert(vec.clamplength(2) == vec);
    assert(vec.lerp(vec, 0.5) == vec);
    assert(vec.slerp(vec, 0.5) == vec);
    assert(vec.reflect(vec) == vec);
    assert(vec.project(vec) == vec);
    assert(vec.flip == vec);
    assert(vec.astuple is tuple());
    vec = vec;
    vec += vec;
    vec *= vec;
    assert(vec == vec);
    assert(vec.toString() == `()`);
}

unittest{ /// Zero vector
    assert(Vector!(1, int).zero == vector(0));
    assert(Vector!(2, int).zero == vector(0, 0));
    assert(Vector!(3, int).zero == vector(0, 0, 0));
    assert(Vector!(4, int).zero == vector(0, 0, 0, 0));
    assert(Vector!(6, int).zero == vector(0, 0, 0, 0, 0, 0));
}

unittest{ // Invoke constructor with component list
    assert(Vector!(4, int)(1) == vector(1, 0, 0, 0));
    assert(Vector!(4, int)(1, 2, 3, 4) == vector(1, 2, 3, 4));
    assert(Vector!(4, int)(1, 2, 3, 4, 5, 6) == vector(1, 2, 3, 4));
}

unittest{ // Invoke constructor with another vector as input
    assert(Vector!(4, int)(vector(1)) == vector(1, 0, 0, 0));
    assert(Vector!(4, int)(vector(1, 2, 3, 4)) == vector(1, 2, 3, 4));
}

unittest{ // Invoke constructor with a tuple as input
    assert(Vector!(4, int)(tuple(1)) == vector(1, 0, 0, 0));
    assert(Vector!(4, int)(tuple(1, 2, 3, 4)) == vector(1, 2, 3, 4));
}

unittest{ // Invoke constructor with arrays as input
    int[] dynamicArray = [1, 2, 3];
    int[3] staticArray = [4, 5, 6];
    assert(Vector!(2, int)(dynamicArray) == vector(1, 2));
    assert(Vector!(3, int)(dynamicArray) == vector(1, 2, 3));
    assert(Vector!(4, int)(dynamicArray) == vector(1, 2, 3, 0));
    assert(Vector!(2, int)(staticArray) == vector(4, 5));
    assert(Vector!(3, int)(staticArray) == vector(4, 5, 6));
    assert(Vector!(4, int)(staticArray) == vector(4, 5, 6, 0));
}

unittest{ // Initialization using static fill method
    assert(Vector!(2, int).fill(3) == vector(3, 3));
    assert(Vector!(4, int).fill(1) == vector(1, 1, 1, 1));
}

unittest{ /// Equality comparison
    assert(vector(1) == vector(1));
    assert(vector(1) == vector(1.0));
    assert(vector(0) != vector(1));
    assert(vector(1, 2) == vector(1, 2));
    assert(vector(1, 2) != vector(0, 0));
    assert(vector(1, 2, 3) == vector(1, 2, 3));
    assert(vector(1, 2, 3) != vector(0, 0, 0));
    assert(vector(1, 2, 3, 4) == vector(1, 2, 3, 4));
    assert(vector(1, 2, 3, 4) != vector(0, 0, 0, 0));
    assert(vector(1, 2, 3, 4, 5) == vector(1, 2, 3, 4, 5));
    assert(vector(1, 2, 3, 4, 5) != vector(0, 0, 0, 0, 0));
}

unittest{ /// Indexing
    auto vec = vector(0, 1, 2, 3, 4);
    assert(vec[0] == 0);
    assert(vec[1] == 1);
    assert(vec[2] == 2);
    assert(vec[3] == 3);
    assert(vec[4] == 4);
    static assert(!is(typeof({vec[5];})));
    assert(vec.index!0 == 0);
    assert(vec.index!4 == 4);
    static assert(!is(typeof({vec.index!5;})));
    foreach(i; 0 .. vec.size) assert(vec.index(i) == i);
    assertthrows!IndexOutOfBoundsError({vec.index(5);});
    vec[1] = 10;
    assert(vec == vector(0, 10, 2, 3, 4));
    vec.index!2 = 20;
    assert(vec == vector(0, 10, 20, 3, 4));
    vec.index(3) = 30;
    assert(vec == vector(0, 10, 20, 30, 4));
}

unittest{ /// Casting
    Vector2f x = cast(Vector2f) vector!int();
    assert(x == vector(0, 0));
    Vector!(0, int) y = cast(Vector!(0, int)) vector(1, 2, 3);
    assert(y is vector!int());
    Vector2i z = cast(Vector2i) vector(3.2, 2, 1);
    assert(z == vector(3, 2));
    Vector4i w = cast(Vector4i) vector(5, 6);
    assert(w == vector(5, 6, 0, 0));
}

unittest{ /// Negation
    assert(-vector(+1) == vector(-1));
    assert(-vector(-1) == vector(+1));
    assert(-vector(1, 2, 3) == vector(-1, -2, -3));
    assert(+vector(1, 2, 3, -4) == vector(1, 2, 3, -4));
}

unittest{ /// Swizzling
    // Getting
    assert(vector(1).xx == vector(1, 1));
    assert(vector(1).xxx == vector(1, 1, 1));
    assert(vector(1).xxxx == vector(1, 1, 1, 1));
    assert(vector(1, 2).xy == vector(1, 2));
    assert(vector(1, 2).yx == vector(2, 1));
    assert(vector(1, 2).xyxy == vector(1, 2, 1, 2));
    assert(vector(1, 2, 3).xy == vector(1, 2));
    assert(vector(1, 2, 3).xyxz == vector(1, 2, 1, 3));
    assert(vector(1, 2, 3, 4).xy == vector(1, 2));
    assert(vector(1, 2, 3, 4).zw == vector(3, 4));
    assert(vector(1, 2, 3, 4).wzyx == vector(4, 3, 2, 1));
    // Setting Vector2
    auto v2 = vector(0, 0);
    v2.yx = vector(1, 2);
    assert(v2 == vector(2, 1));
    static assert(!is(typeof({v2.xx = v2;})));
    // Setting Vector3
    auto v3 = vector(0, 0, 0);
    v3.yz = vector(1, 2);
    assert(v3 == vector(0, 1, 2));
    v3.xz = vector(1, 3);
    assert(v3 == vector(1, 1, 3));
    v3.xzy = vector(3, 4, 5);
    assert(v3 == vector(3, 5, 4));
    // Setting Vector4
    auto v4 = vector(0, 0, 0, 0);
    v4.xy = vector(1, 2);
    v4.wz = vector(4, 3);
    assert(v4 == vector(1, 2, 3, 4));
    v4.zwxy = v4;
    assert(v4 == vector(3, 4, 1, 2));
}

unittest{ /// Length
    assert(vector(1).length == 1);
    assert(vector(0, 1).length == 1);
    assert(vector(-1, 0).length == 1);
    assert(vector(0, 0, 2).length == 2);
    assert(vector(0, 0, 0, 0, 2, 0, 0).length == 2);
    assert(fnearequal(vector(1, 1).length, 2 ^^ 0.5, 1e-12));
    assert(vector(1).lengthsq == 1);
    assert(vector(1, 2).lengthsq == 5);
    assert(vector(1, 2, 3).lengthsq == 14);
    assert(vector(1, 2, 3, 4).lengthsq == 30);
}

unittest{ /// Manhattan distance
    assert(vector(+3).manhattan == 3);
    assert(vector(-3).manhattan == 3);
    assert(vector(+3, +4).manhattan == 7);
    assert(vector(+3, -4).manhattan == 7);
    assert(vector(-3, +4).manhattan == 7);
    assert(vector(-3, -4).manhattan == 7);
    assert(vector(3, 4, 5).manhattan == 12);
    assert(vector(3, 4).manhattan(vector(1, 2)) == 4);
}

unittest{ /// Clamp length
    assert(vector(1).clamplength(10) == vector(1));
    assert(vector(1, 2).clamplength(10) == vector(1, 2));
    assert(vector(1, 2, 3).clamplength(10) == vector(1, 2, 3));
    assert(vector(+2).clamplength(1) == vector(+1));
    assert(vector(-2).clamplength(1) == vector(-1));
    assert(vector(1, 2).clamplength(1).equals(vector(1, 2).normalize, 1e-12));
    assert(vector(1, 2, 3).clamplength(1).equals(vector(1, 2, 3).normalize, 1e-12));
}

unittest{ /// String representation
    assert(vector(1).toString() == `(1)`);
    assert(vector(1, 2).toString() == `(1, 2)`);
    assert(vector(1, 2, 3).toString() == `(1, 2, 3)`);
    assert(vector(1, 2, 3, 4).toString() == `(1, 2, 3, 4)`);
    assert(vector(1, 2, 3, 4, 5, 6).toString() == `(1, 2, 3, 4, 5, 6)`);
}

unittest{ /// Concatenation
    assert(vector!int().concat(vector!int()) is vector!int());
    assert(vector!int().concat(vector(1)) is vector(1));
    assert(vector(1).concat(vector!int()) is vector(1));
    assert(vector!int().concat(vector(1), vector(2, 3)) is vector(1, 2, 3));
    assert(vector(0).concat(vector(1), vector(2, 3)) is vector(0, 1, 2, 3));
}

unittest{ /// Slicing
    assert(vector(1, 2, 3, 4).slice!(0, 0) is vector!int());
    assert(vector(1, 2, 3, 4).slice!(0, 1) is vector(1));
    assert(vector(1, 2, 3, 4).slice!(0, 2) is vector(1, 2));
    assert(vector(1, 2, 3, 4).slice!(0, 3) is vector(1, 2, 3));
    assert(vector(1, 2, 3, 4).slice!(0, 4) is vector(1, 2, 3, 4));
    assert(vector(1, 2, 3, 4).slice!(1, 4) is vector(2, 3, 4));
    assert(vector(1, 2, 3, 4).slice!(2, 4) is vector(3, 4));
    assert(vector(1, 2, 3, 4).slice!(3, 4) is vector(4));
    assert(vector(1, 2, 3, 4).slice!(4, 4) is vector!int());
    assert(vector(1, 2, 3, 4).slice!(1, 3) is vector(2, 3));
}

unittest{ /// Normalization
    enum double[] inputs = [
        +0.0, +0.2, +0.5, +0.8, +0.9, +1.0, +1.5, +2.0, +3.5, +20.0, +100.0,
        -0.0, -0.2, -0.5, -0.8, -0.9, -1.0, -1.5, -2.0, -3.5, -20.0, -100.0,
    ];
    foreach(x; inputs){
        immutable norm1 = vector(+x).normalize;
        if(x == 0) assert(norm1.x.fisnan);
        else if(x > 0) assert(norm1.x == +1);
        else if(x < 0) assert(norm1.x == -1);
        foreach(y; inputs){
            immutable norm2 = vector(x, y).normalize;
            if(x == 0 && y == 0) assert(norm2.values.varall!fisnan);
            else assert(fnearequal(norm2.length, 1, 1e-12));
            foreach(z; inputs){
                immutable norm3 = vector(x, y, z).normalize;
                if(x == 0 && y == 0 && z == 0) assert(norm3.values.varall!fisnan);
                else assert(fnearequal(norm3.length, 1, 1e-12));
            }
        }
    }
}

unittest{ /// Component-wise binary operations
    // With numbers
    assert((vector(1) * 2) == vector(2));
    assert((vector(1, 2) * 2) == vector(2, 4));
    assert((vector(1, 2, 3) * 2) == vector(2, 4, 6));
    assert((vector(1) *= 2) == vector(2));
    assert((vector(1, 2) *= 2) == vector(2, 4));
    assert((vector(1, 2, 3) *= 2) == vector(2, 4, 6));
    assert((vector(2) / 2) == vector(1));
    assert((vector(8, 16) / 2) == vector(4, 8));
    assert((vector(8, 16, 32) / 2) == vector(4, 8, 16));
    assert((vector(2) /= 2) == vector(1));
    assert((vector(8, 16) /= 2) == vector(4, 8));
    assert((vector(8, 16, 32) /= 2) == vector(4, 8, 16));
    assert((vector(2) % 3) == vector(2));
    assert((vector(2, 4) % 3) == vector(2, 1));
    assert((vector(2, 4, 6) % 3) == vector(2, 1, 0));
    assert((vector(2) %= 3) == vector(2));
    assert((vector(2, 4) %= 3) == vector(2, 1));
    assert((vector(2, 4, 6) %= 3) == vector(2, 1, 0));
    assert((vector(2) ^^ 2) == vector(4));
    assert((vector(2, 3) ^^ 2) == vector(4, 9));
    assert((vector(2, 3, 4) ^^ 2) == vector(4, 9, 16));
    assert((vector(2) ^^= 2) == vector(4));
    assert((vector(2, 3) ^^= 2) == vector(4, 9));
    assert((vector(2, 3, 4) ^^= 2) == vector(4, 9, 16));
    assert(2 * vector(1) == vector(2));
    assert(2 * vector(1, 2) == vector(2, 4));
    assert(2 * vector(1, 2, 3) == vector(2, 4, 6));
    // With other vectors
    assert((vector(1) + vector(2)) == vector(3));
    assert((vector(1, 2) + vector(2, 3)) == vector(3, 5));
    assert((vector(1) += vector(2)) == vector(3));
    assert((vector(1, 2) += vector(2, 3)) == vector(3, 5));
    assert((vector(2) - vector(1)) == vector(1));
    assert((vector(4, 5) -= vector(2, 1)) == vector(2, 4));
    assert((vector(2) - vector(1)) == vector(1));
    assert((vector(4, 5) -= vector(2, 1)) == vector(2, 4));
    assert((vector(2) * vector(3)) == vector(6));
    assert((vector(1, 2) * vector(2, 3)) == vector(2, 6));
    assert((vector(2) *= vector(3)) == vector(6));
    assert((vector(1, 2) *= vector(2, 3)) == vector(2, 6));
    assert((vector(6) / vector(3)) == vector(2));
    assert((vector(8, 6) / vector(2, 3)) == vector(4, 2));
    assert((vector(6) /= vector(3)) == vector(2));
    assert((vector(8, 6) /= vector(2, 3)) == vector(4, 2));
}

unittest{ /// Integer-math squared length and distance
    assert(vector(2).ilengthsq == 4);
    assert(vector(1, 2).ilengthsq == 5);
    assert(vector(1, 2, 3).ilengthsq == 14);
    assert(vector(1).idistancesq(vector(3)) == 4);
    assert(vector(1, 2).idistancesq(vector(-1, -2)) == 20);
}

unittest{ /// Cross product of three-dimensional vectors
    assert(vector(1, 2, 3).cross(vector(3, 2, 1)) == vector(-4, 8, -4));
    assert(vector(1, 2, 3).cross(vector(4, 5, 6)) == vector(-3, 6, -3));
    assert(vector(-1, 0, 1).cross(vector(3, 2, 1)) == vector(-2, 4, -2));
    assert(vector(-1, 0, 1).cross(vector(8, -9, -10)) == vector(9, -2, 9));
    assert(vector(4, -5, 6).cross(vector(7, -9, 8)) == vector(14, 10, -1));
    assert(vector(10, 9, 8).cross(vector(7, 6, -5)) == vector(-93, 106, -3));
}

unittest{ /// Cross product matrix of three-dimensional vector
    auto a = vector(+1, +2, +3);
    auto b = vector(-5, -6, -7);
    assert(a.crossmat * b == a.cross(b));
    assert(b.crossmat.transpose * a == a.cross(b));
}

unittest{ /// Reflection
    assert(vector(1, 2).reflect(vector(1, 0)) == vector(1, -2));
    assert(vector(3, 4).reflect(vector(0, -1)) == vector(-3, 4));
}

unittest{ /// Projection
    assert(vector(-2).project(vector(1)) == vector(2));
    assert(vector(3, 4).project(vector(-1, 0)) == vector(-5, 0));
    assert(vector(3, 0, 4).project(vector(0, 1, 0)) == vector(0, 5, 0));
}

unittest{ /// Flip vector
    assert(vector(1).flip == vector(1));
    assert(vector(1, 2).flip == vector(2, 1));
    assert(vector(1, 2, 3).flip == vector(3, 2, 1));
    assert(vector(1, 2, 3, 4).flip == vector(4, 3, 2, 1));
}

unittest{ /// Conversion to and from spherical coordinates
    // Two-dimensional vector
    assert(vector(+2, +2).direction.degrees == 45);
    assert(vector(-2, -2).direction.degrees == 225);
    // Three-dimensional vector
    immutable vec3dir = vector(+2, +2, +0).direction;
    assert(fnearequal(vec3dir[0].degrees, 45, 1e-12));
    assert(fnearequal(vec3dir[1].degrees, 0, 1e-12));
    // Arbitrary vectors, and conversion back to Cartesian coordinates
    foreach(vec; Aliases!(
        vector(+2, +3), vector(-2, +3), vector(+2, -3), vector(-2, -3),
        vector(+1, +2, +3), vector(-1, +2, +3), vector(+1, +2, -3),
        vector(+4, +5, +6, +7), vector(+4, +5, +6, -7),
    )){
        assert(vec.equals(
            Vector!(vec.size, double).unit(vec.direction) * vec.length, 1e-8
        ));
    }
}

unittest{ /// Linear interpolation
    // One-dimensional vectors
    immutable x = vector(-2);
    immutable y = vector(+2);
    assert(x.lerp(y, 0) == x);
    assert(x.lerp(y, 1) == y);
    assert(x.lerp(y, -1) == x);
    assert(x.lerp(y, +2) == y);
    assert(y.lerp(x, 0) == y);
    assert(y.lerp(x, 1) == x);
    assert(y.lerp(x, -1) == y);
    assert(y.lerp(x, +2) == x);
    assert(x.lerp(y, 0.5) == vector(0));
    assert(y.lerp(x, 0.5) == vector(0));
    // Two-dimensional vectors
    immutable z = vector(1, 1);
    immutable w = vector(2, 2);
    assert(z.lerp(w, 0) == z);
    assert(z.lerp(w, 1) == w);
    assert(z.lerp(w, -1) == z);
    assert(z.lerp(w, +2) == w);
    assert(w.lerp(z, 0) == w);
    assert(w.lerp(z, 1) == z);
    assert(w.lerp(z, -1) == w);
    assert(w.lerp(z, +2) == z);
    assert(z.lerp(w, 0.5) == vector(1.5, 1.5));
    assert(w.lerp(z, 0.5) == vector(1.5, 1.5));
}

unittest{ /// Spherical linear interpolation, two-dimensional inputs
    immutable x = vector(1, 2).normalize;
    immutable y = vector(-3, 4).normalize;
    // Special cases
    assert(x.slerp(y, 0) == x);
    assert(x.slerp(y, 1) == y);
    assert(x.slerp(y, -1) == x);
    assert(x.slerp(y, +2) == y);
    assert(y.slerp(x, 0) == y);
    assert(y.slerp(x, 1) == x);
    assert(y.slerp(x, -1) == y);
    assert(y.slerp(x, +2) == x);
    // The direction of the midpoint should be a midpoint between the
    // directions of the two inputs.
    immutable mid = x.slerp(y, 0.5);
    assert(fnearequal(
        x.direction.distance(mid.direction).revolutions,
        y.direction.distance(mid.direction).revolutions,
        1e-8
    ));
    // And the length should be a linear interpolation of input lengths.
    assert(fnearequal(mid.length, (x.length + y.length) / 2, 1e-12));
}
unittest{ /// Spherical linear interpolation, three-dimensional inputs
    // Three-dimensional vectors
    immutable x = vector(1, 2, 3);
    immutable y = vector(-4, 5, -6);
    // Special cases
    assert(x.slerp(y, 0) == x);
    assert(x.slerp(y, 1) == y);
    assert(x.slerp(y, -1) == x);
    assert(x.slerp(y, +2) == y);
    assert(y.slerp(x, 0) == y);
    assert(y.slerp(x, 1) == x);
    assert(y.slerp(x, -1) == y);
    assert(y.slerp(x, +2) == x);
    // Get the midpoint.
    immutable mid = x.slerp(y, 0.5);
    // Output length should be a linear interpolation of input lengths.
    assert(fnearequal(mid.length, (x.length + y.length) / 2, 1e-12));
}

unittest { /// Vector singular map and mapi
    immutable x = vector(1, 2, 3);
    immutable y = Vector!(0, int)();
    assert(x.map!((c) => (c + 1)) == vector(2, 3, 4));
    assert(x.mapi!((index, c) => (c + 2 * index)) == vector(1, 4, 7));
    assert(y.map!((c) => (c + 1)) == y);
    assert(y.mapi!((index, c) => (c + 1)) == y);
}

unittest { /// Vector plural map and mapi
    immutable x = vector(+1, +2, +3);
    immutable y = vector(-1, -2, -3);
    assert(map!((i, j) => (i + j))(x, y) == vector(0, 0, 0));
    assert(map!((i, j) => (i * j))(x, y) == vector(-1, -4, -9));
    assert(mapi!((index, i, j) => (i - j + index))(x, y) == vector(2, 5, 8));
}
