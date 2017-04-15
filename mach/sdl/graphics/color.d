module mach.sdl.graphics.color;

private:

import derelict.sdl2.sdl;
import derelict.sdl2.types : SDL_Color;
import derelict.opengl3.gl;

import mach.meta : Aliases;
import mach.traits : isNumeric, isIntegral, isFloatingPoint, isTemplateOf;
import mach.math.round : round;
import mach.math.vector : Vector, vector;
import mach.text.text : text;

public:



enum isColor(T) = isTemplateOf!(T, Color);



struct Color{
    alias Value = float;
    alias Values = Aliases!(Value, Value, Value, Value);
    
    Values values;
    alias values this;
    
    alias red = this.values[0];
    alias green = this.values[1];
    alias blue = this.values[2];
    alias alpha = this.values[3];
    alias r = this.red;
    alias g = this.green;
    alias b = this.blue;
    alias a = this.alpha;
    
    static enum Black = Color(0.0, 0.0, 0.0);
    static enum White = Color(1.0, 1.0, 1.0);
    static enum Red = Color(1.0, 0.0, 0.0);
    static enum Green = Color(0.0, 1.0, 0.0);
    static enum Blue = Color(0.0, 0.0, 1.0);
    static enum Yellow = Color(1.0, 1.0, 0.0);
    static enum Cyan = Color(0.0, 1.0, 1.0);
    static enum Magenta = Color(1.0, 0.0, 1.0);
    static enum Gray = Color(0.5, 0.5, 0.5);
    static enum Orange = Color(1.0, 0.5, 0.0);
    static enum Violet = Color(0.5, 0.0, 1.0);
    static enum Rose = Color(1.0, 0.0, 0.5);
    static enum Aqua = Color(0.0, 0.5, 1.0);
    static enum Lime = Color(0.5, 1.0, 0.0);
    
    /// Get a color from integral RGBA values in the range [0, 255].
    static typeof(this) bytes(T)(
        in T red, in T green, in T blue, in T alpha = 255
    ) if(isIntegral!T){
        return typeof(this)(red / 255.0, green / 255.0, blue / 255.0, alpha / 255.0);
    }
    
    this(T)(in T gray, in T alpha = 1) if(isNumeric!T){
        this(gray, gray, gray, alpha);
    }
    this(T)(in T red, in T green, in T blue, in T alpha = 1) if(isNumeric!T){
        this.red = cast(Value) red;
        this.green = cast(Value) green;
        this.blue = cast(Value) blue;
        this.alpha = cast(Value) alpha;
    }
    this(T)(in Vector!(3, T) rgb){
        this(rgb[0], rgb[1], rgb[2]);
    }
    this(T)(in Vector!(4, T) rgba){
        this(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
    this(SDL_Color color){
        this(color.r / 255.0, color.g / 255.0, color.b / 255.0, color.a / 255.0);
    }
    this(in uint value, in SDL_PixelFormat* format){
        ubyte r, g, b, a;
        SDL_GetRGBA(value, format, &r, &g, &b, &a);
        this(r / 255.0, g / 255.0, b / 255.0, a / 255.0);
    }
    
    /// Get a vector representing the RGB components of this color.
    @property auto rgb() const{
        return vector(this.r, this.g, this.b);
    }
    @property void rgb(T)(in Vector!(3, T) vec){
        this[0] = vec[0];
        this[1] = vec[1];
        this[2] = vec[2];
    }
    /// Get a vector representing the RGBA components of this color.
    @property auto rgba() const{
        return vector(this.r, this.g, this.b, this.a);
    }
    @property void rgba(T)(in Vector!(4, T) vec){
        this[0] = vec[0];
        this[1] = vec[1];
        this[2] = vec[2];
        this[3] = vec[3];
    }
    /// Get a vector representing the ARGB components of this color.
    @property auto argb() const{
        return vector(this.a, this.r, this.g, this.b);
    }
    @property void argb(T)(in Vector!(4, T) vec){
        this[0] = vec[1];
        this[1] = vec[2];
        this[2] = vec[3];
        this[3] = vec[0];
    }
    
    auto bytes() const{
        return cast(Vector!(4, int))(this.rgba * 255);
    }
    @property auto ired() const{
        return cast(uint) round(this.red * 255);
    }
    @property auto igreen() const{
        return cast(uint) round(this.green * 255);
    }
    @property auto iblue() const{
        return cast(uint) round(this.blue * 255);
    }
    @property auto ialpha() const{
        return cast(uint) round(this.alpha * 255);
    }
    
    uint format(in SDL_PixelFormat* format) const{
        return SDL_MapRGBA(format,
            cast(ubyte) this.ired, cast(ubyte) this.igreen,
            cast(ubyte) this.iblue, cast(ubyte) this.ialpha
        );
    }
    SDL_Color opCast(Type: SDL_Color)() const{
        return SDL_Color(
            cast(ubyte) this.ired, cast(ubyte) this.igreen,
            cast(ubyte) this.iblue, cast(ubyte) this.ialpha
        );
    }
    
    auto equals(in Color color) const{
        return this.equals(color, 0x1p-9);
    }
    auto equals(E)(in Color color, in E epsilon) const if(isNumeric!E){
        assert(epsilon >= 0, "Epsilon must be non-negative.");
        foreach(i, _; Values){
            immutable delta = this[i] - color[i];
            if(delta < -epsilon || delta > epsilon) return false;
        }
        return true;
    }
    
    /// Get a copy of this color with the same RGB values but a perfectly
    /// opaque alpha value of 1.0.
    auto opaque() const{
        return typeof(this)(this.r, this.g, this.b, 1.0);
    }
    
    auto opBinary(string op, N)(in N rhs) const if(isNumeric!N){
        mixin(`return typeof(this)(
            this.r ` ~ op ~ ` rhs,
            this.g ` ~ op ~ ` rhs,
            this.b ` ~ op ~ ` rhs,
            this.a
        );`);
    }
    auto opBinaryRight(string op: "*", N)(in N rhs) const if(isNumeric!N){
        return this.opBinary!(op)(rhs);
    }
    auto opOpAssign(string op, N)(in N rhs) if(isNumeric!N){
        mixin(`
            this[0] ` ~ op ~ `= rhs;
            this[1] ` ~ op ~ `= rhs;
            this[2] ` ~ op ~ `= rhs;
        `);
    }
    
    auto opBinary(string op, N)(in Vector!(3, N) rhs) const{
        mixin(`return typeof(this)(
            this[0] ` ~ op ~ ` rhs.x,
            this[1] ` ~ op ~ ` rhs.y,
            this[2] ` ~ op ~ ` rhs.z,
            this[3]
        );`);
    }
    auto opBinaryRight(string op, N)(in Vector!(3, N) rhs) const{
        mixin(`return typeof(this)(
            rhs.x ` ~ op ~ ` this[0],
            rhs.y ` ~ op ~ ` this[1],
            rhs.z ` ~ op ~ ` this[2],
            this[3]
        );`);
    }
    auto opOpAssign(string op, N)(in Vector!(3, N) rhs) const{
        mixin(`
            this[0] ` ~ op ~ `= rhs[0];
            this[1] ` ~ op ~ `= rhs[1];
            this[2] ` ~ op ~ `= rhs[2];
        `);
    }
    
    auto opBinary(string op, N)(in Vector!(4, N) rhs) const{
        mixin(`return typeof(this)(
            this[0] ` ~ op ~ ` rhs[0],
            this[1] ` ~ op ~ ` rhs[1],
            this[2] ` ~ op ~ ` rhs[2],
            this[3] ` ~ op ~ ` rhs[3],
        );`);
    }
    auto opBinaryRight(string op, N)(in Vector!(4, N) rhs) const{
        mixin(`return typeof(this)(
            rhs[0] ` ~ op ~ ` this[0],
            rhs[1] ` ~ op ~ ` this[1],
            rhs[2] ` ~ op ~ ` this[2],
            rhs[3] ` ~ op ~ ` this[3],
        );`);
    }
    auto opOpAssign(string op, N)(in Vector!(4, N) rhs) const{
        mixin(`
            this[0] ` ~ op ~ `= rhs;
            this[1] ` ~ op ~ `= rhs;
            this[2] ` ~ op ~ `= rhs;
            this[3] ` ~ op ~ `= rhs;
        `);
    }
    
    auto opBinary(string op)(in Color rhs) const{
        return this.opBinary!op(rhs.rgba);
    }
    auto opOpAssign(string op)(in Color rhs) const{
        return this.opBinary!op(rhs.rgba);
    }
    
    string toString() const{
        return text(
            "(", this.red, "R, ", this.green, "G, ", this.blue, "B, ", this.alpha, "A)"
        );
    }
}
