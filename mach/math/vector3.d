module mach.math.vector3;

private:

import std.math : sin, cos, atan2, sqrt;
import mach.types : tuple;
import mach.traits : isNumeric, isTemplateOf;

public:



enum isVector3(T) = isTemplateOf!(T, Vector3);



auto Vector(N)(N x, N y, N z) if(isNumeric!N){
    return Vector3!N(x, y, z);
}



struct Vector3(T) if(isNumeric!T){
    static enum Zero = Vector3!T(0);
    
    T x, y, z;
    
    @property auto astuple(){
        return tuple(this.x, this.y, this.z);
    }
    alias astuple this;
    
    this(N)(in N x) if(isNumeric!N){
        this(x, x, x);
    }
    this(N)(in N x, in N y, in N z) if(isNumeric!N){
        this.x = cast(T) x;
        this.y = cast(T) y;
        this.z = cast(T) z;
    }
    this(N)(in Vector3!N vector){
        this(vector.x, vector.y, vector.z);
    }
    
    /// Get the null vector.
    static Vector3!T zero(){
        return Vector3!T(0, 0, 0);
    }
    
    /// Returns true if this is not the null vector.
    @property bool nonzero() const{
        return (this.x != 0) | (this.y != 0) | (this.z != 0);
    }
    
    T dot(N)(in Vector3!N vector) const{
        return this.x * vector.x + this.y * vector.y + this.z * vector.z;
    }
    alias scalar = dot;
    
    Vector3!T cross(N)(in Vector3!N vector) const{
        return Vector3!T(
            this.y * vector.z - this.z * vector.y,
            this.z * vector.x - this.x * vector.z,
            this.x * vector.y - this.y * vector.x
        );
    }
    
    Vector3!T lerp(N)(in Vector3!N vector, in double time) const{
        Vector3!T result = vector - this;
        result *= time; result += this;
        return result;
    }
    
    /// Get the Euclidean distance between two vectors.
    double distance(N)(in Vector3!N vector) const{
        return (this - vector).length();
    }
    /// Get the squared Euclidean distance between two vectors.
    T distancesq(N)(in Vector3!N vector) const{
        return (this - vector).lengthsq();
    }
    
    /// Get the normal of this vector.
    @property Vector3!T normal() const{
        return this / this.length();
    }
    /// Normalize this vector.
    void normalize(){
        this /= this.length();
    }
    
    /// Get the length of this vector.
    @property double length() const{
        return sqrt(cast(double) this.lengthsq());
    }
    @property void length(in double length){
        this *= length / this.length();
    }
    /// Get the squared length of this vector.
    @property T lengthsq() const{
        return (this.x * this.x) + (this.y * this.y) + (this.z * this.z);
    }
    
    /// Negate this vector.
    void negate(){
        this.x = -this.x; this.y = -this.y; this.z = -this.z;
    }
    
    double opUnary(string op)() const if (op == `*`){
        return this.length();
    }
    Vector3!T opUnary(string op)() const if (op == `~`){
        return this.normal();
    }
    Vector3!T opUnary(string op)() const if (op == `-`){
        return Vector3!T(-this.x, -this.y, -this.z);
    }
    
    void opOpAssign(string op, N)(Vector3!N rhs){
        mixin(`
            this.x ` ~ op ~ `= rhs.x;
            this.y ` ~ op ~ `= rhs.y;
            this.z ` ~ op ~ `= rhs.z;
        `);
    }
    void opOpAssign(string op, N)(N rhs) if(isNumeric!N){
        mixin(`
            this.x ` ~ op ~ `= rhs;
            this.y ` ~ op ~ `= rhs;
            this.z ` ~ op ~ `= rhs;
        `);
    }

    Vector3!T opBinary(string op, N)(Vector3!N rhs) const{
        mixin(`return Vector3!T(
            this.x ` ~ op ~ ` rhs.x,
            this.y ` ~ op ~ ` rhs.y,
            this.z ` ~ op ~ ` rhs.z
        );`);
    }
    Vector3!T opBinary(string op, N)(N rhs) const if(isNumeric!N){
        mixin(`return Vector3!T(
            this.x ` ~ op ~ ` rhs,
            this.y ` ~ op ~ ` rhs,
            this.z ` ~ op ~ ` rhs
        );`);
    }
    
    Vector3!T opBinaryRight(string op, N)(N rhs) const if(isNumeric!N){
        mixin(`return Vector3!T(
            rhs ` ~ op ~ ` this.x,
            rhs ` ~ op ~ ` this.y,
            rhs ` ~ op ~ ` this.z
        );`);
    }
    
    bool opEquals(N)(Vector3!N vector) const{
        return(
            (this.x == vector.x) & 
            (this.y == vector.y) &
            (this.z == vector.z)
        );
    }
    
    bool opCast(Type : bool)(){
        return this.nonzero();
    }
    Vector3!N opCast(Type : Vector3!N, N)() if(!is(N == T)){
        return Type(this);
    }
}



unittest{
    // TODO
}
