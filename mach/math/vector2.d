module mach.math.vector2;

private:

import std.math : sin, cos, atan2, sqrt;
import std.traits : isNumeric;
import std.string : replace;

import mach.error.assertf : assertf;

public:

struct Vector2(T) if(isNumeric!T){
    
    T x, y;
    
    this(N)(in N x) if(isNumeric!N){
        this(x, x);
    }
    this(N)(in N x, in N y) if(isNumeric!N){
        this.x = cast(T) x;
        this.y = cast(T) y;
    }
    this(N)(in Vector2!N vector){
        this(vector.x, vector.y);
    }
    
    /// Get the null vector.
    static Vector2!T zero(){
        return Vector2!T(0, 0);
    }
    
    /// Returns true if this is not the null vector.
    @property bool nonzero() const{
        return (this.x != 0) | (this.y != 0);
    }
    
    /// Get the dot product.
    T dot(N)(in Vector2!N vector) const{
        return this.x * vector.x + this.y * vector.y;
    }
    alias scalar = dot;
    
    /// Get the cross product.
    T cross(N)(in Vector2!N vector) const{
        return this.x * vector.y - this.y * vector.x;
    }
    
    /// Interpolate linearly between this and another vector.
    Vector2!T lerp(N)(in Vector2!N vector, in real time) const{
        Vector2!T result = vector - this;
        result *= time; result += this;
        return result;
    }
    
    /// Get the Euclidean distance between two vectors.
    real distance(N)(in Vector2!N vector) const{
        return (this - vector).length();
    }
    /// Get the squared Euclidean distance between two vectors.
    T distancesq(N)(in Vector2!N vector) const{
        return (this - vector).lengthsq();
    }
    
    /// Get the normal of this vector.
    @property Vector2!T normal() const{
        return this / this.length();
    }
    /// Normalize this vector.
    void normalize(){
        this /= this.length();
    }
    
    /// Get the length of this vector.
    @property real length() const{
        return sqrt(cast(real) this.lengthsq());
    }
    @property void length(in real length){
        this *= length / this.length();
    }
    /// Get the squared length of this vector.
    @property T lengthsq() const{
        return (this.x * this.x) + (this.y * this.y);
    }
    
    /// Negate this vector.
    void negate(){
        this.x = -this.x; this.y = -this.y;
    }
    
    static Vector2!T forangle(in real radians, in real length = 1){
        return Vector2!T(cos(radians) * length, sin(radians) * length);
    }
    
    /// Get the angle in radians to which this vector points.
    real angle() const{
        return atan2(cast(real) this.y, cast(real) this.x);
    }
    /// Get the angle in radians from this to another vector.
    real angle(N)(in Vector2!N vector) const{
        return (vector - this).angle();
    }
    /// Get the vector pointing at the given angle in radians and of the given length.
    static Vector2!T angle(in real radians, in real length = 1){
        return Vector2!T(cos(radians) * length, sin(radians) * length);
    }
       
    /// Rotate this vector around the origin.
    void rotate(in real radians){
        auto angle = this.angle() + radians;
        auto length = this.length();
        this.x = cast(T) (cos(angle) * length);
        this.y = cast(T) (sin(angle) * length);
    }
    void rotate(N)(in Vector2!N origin, in real radians){
        this.x -= origin.x; this.y -= origin.x;
        auto angle = this.angle() + radians;
        auto length = this.length();
        this.x = cast(T) (cos(angle) * length + origin.x);
        this.y = cast(T) (sin(angle) * length + origin.y);
    }
    
    Vector2!T rotated(in real radians) const{
        return Vector2!T.angle(this.angle() + radians, this.length());
    }
    Vector2!T rotated(in Vector2!T origin, in real radians) const{
        Vector2!T delta = this - origin;
        Vector2!T result = Vector2!T.angle(delta.angle() + radians, delta.length());
        result += origin;
        return result;
    }
    
    real opUnary(string op)() const if (op == "*"){
        return this.length();
    }
    Vector2!T opUnary(string op)() const if (op == "~"){
        return this.normal();
    }
    Vector2!T opUnary(string op)() const if (op == "-"){
        return Vector2!T(-this.x, -this.y);
    }
    
    void opOpAssign(string op, N)(Vector2!N rhs){
        mixin("
            this.x " ~ op ~ "= rhs.x;
            this.y " ~ op ~ "= rhs.y;
        ");
    }
    void opOpAssign(string op, N)(N rhs) if(isNumeric!N){
        mixin("
            this.x " ~ op ~ "= rhs;
            this.y " ~ op ~ "= rhs;
        ");
    }

    Vector2!T opBinary(string op, N)(Vector2!N rhs) const{
        mixin("return Vector2!T(
            this.x " ~ op ~ " rhs.x,
            this.y " ~ op ~ " rhs.y
        );");
    }
    Vector2!T opBinary(string op, N)(N rhs) const if(isNumeric!N){
        mixin("return Vector2!T(
            this.x " ~ op ~ " rhs,
            this.y " ~ op ~ " rhs
        );");
    }
    
    Vector2!T opBinaryRight(string op, N)(N rhs) const if(isNumeric!N){
        mixin("return Vector2!T(
            rhs " ~ op ~ " this.x,
            rhs " ~ op ~ " this.y
        );");
    }
    
    static enum string opindexassert = q{
        assertf((index == 0) | (index == 1), "Index %d is out of bounds.", index);
    };
    T opIndex(in size_t index) const{
        mixin(opindexassert);
        return (index == 0) ? this.x : this.y;
    }
    void opIndexAssign(N)(in N value, in size_t index) if(isNumeric!N){
        mixin(opindexassert);
        if(index == 0) this.x = cast(T) value;
        else this.y = cast(T) value;
    }
    
    bool opEquals(N)(Vector2!N vector) const{
        return (this.x == vector.x) & (this.y == vector.y);
    }
    
    bool opCast(Type: bool)(){
        return this.nonzero();
    }
    Vector2!N opCast(Type: Vector2!N, N)() if(!is(N == T)){
        return Type(this);
    }
    
    string toString(){
        import std.conv : to;
        return to!string(this.x) ~ ", " ~ to!string(this.y);
    }
    
}

version(unittest) import mach.error.unit;
unittest{
    // TODO: More thorough unit testing
    
    alias Vector = Vector2!real;
    tests("2D Vector math", {
        tests("Equality", {
            testeq(Vector(0, 0), Vector(0, 0));
            testeq(Vector(1, 0), Vector(1, 0));
        });
        tests("Length", {
            testeq(Vector(1, 0).length, 1);
            testeq(Vector(0, -1).length, 1);
            testeq(Vector(3, 4).length, 5);
            testgt(Vector(-100, -120).length, Vector(100, 100).length);
        });
        tests("Nonzero", {
            test(Vector(1, 1).nonzero);
            testf(Vector(0, 0).nonzero);
        });
    });
    
}
