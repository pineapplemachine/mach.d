module mach.sdl.graphics.color;

private:

import derelict.sdl2.sdl;
import derelict.sdl2.types : SDL_Color;
import derelict.opengl3.gl;

import mach.traits : isNumeric, isIntegral, isFloatingPoint, isTemplateOf;
import mach.math.round : round;
import mach.sdl.error : GLError;

public:



enum isColor(T) = isTemplateOf!(T, Color);



/// Represents a color.
/// When T is integral, color ranges from 0 to 255.
/// When T is a floating point, color ranges from 0.0 to 1.0.
/// TODO: What even is endianness?
struct Color(T = float) if(isNumeric!T){
    
    T red, green, blue, alpha;
    
    static if(isFloatingPoint!T){
        static enum T Max = 1; // Highest allowed value for any dimension
        static enum T ToByte = 255; // Multiply dimensions to get bytes
    }else{
        static enum T Max = 255;
        static enum T ToByte = 1;
    }
    
    static immutable Black = Color(0, 0, 0);
    static immutable White = Color(this.Max, this.Max, this.Max);
    static immutable Red = Color(this.Max, 0, 0);
    static immutable Green = Color(0, this.Max, 0);
    static immutable Blue = Color(0, 0, this.Max);
    static immutable Yellow = Color(this.Max, this.Max, 0);
    static immutable Cyan = Color(0, this.Max, this.Max);
    static immutable Magenta = Color(this.Max, 0, this.Max);
    
    this(N)(in N r, in N g, in N b, in N a = cast(N) this.Max) if(isNumeric!N){
        this.red = cast(T) r; this.green = cast(T) g;
        this.blue = cast(T) b; this.alpha = cast(T) a;
    }
    this(in uint hex){
        const T a = cast(T) (((hex >> 24) & 255) / this.ToByte);
        const T b = cast(T) (((hex >> 16) & 255) / this.ToByte);
        const T c = cast(T) (((hex >> 8) & 255) / this.ToByte);
        const T d = cast(T) ((hex & 255) / this.ToByte);
        version(LittleEndian) this(a, b, c, d);
        else this(d, c, b, a);
    }
    this(N)(in Color!N color){
        static if(is(N == T)) this(color.r, color.g, color.b, color.a);
        else this(color.r!T, color.g!T, color.b!T, color.a!T);
    }
    this(SDL_Color color){
        this(color.r / this.ToByte, color.g / this.ToByte, color.b / this.ToByte, color.a / this.ToByte);
    }
    this(in uint value, in SDL_PixelFormat* format){
        ubyte r, g, b, a;
        SDL_GetRGBA(value, format, &r, &g, &b, &a);
        this(r, g, b, a);
    }
    
    static auto gray(N)(in N gray, in N alpha = cast(N) this.Max){
        return typeof(this)(gray, gray, gray, alpha);
    }
    
    As valueas(As, string name)() const{
        mixin(`
            static if(is(As == T)){
                return this.` ~ name ~ `;
            }else static if(isFloatingPoint!T && isIntegral!As){
                return cast(As) round(this.` ~ name ~ ` * this.ToByte);
            }else static if(isIntegral!T && isFloatingPoint!As){
                return (cast(As) this.` ~ name ~ `) / this.Max;
            }else{
                return cast(As) this.` ~ name ~ `;
            }
        `);
    }
    void valueas(As, string name)(in As value) const{
        mixin(`
            static if(is(As == T)){
                this.` ~ name ~ ` = value;
            }else static if(isFloatingPoint!T && isIntegral!As){
                this.` ~ name ~ ` = value / cast(T) this.ToByte;
            }else static if(isIntegral!T && isFloatingPoint!As){
                this.` ~ name ~ ` = cast(T) round(value * this.Max);
            }else{
                this.` ~ name ~ ` = cast(T) value;
            }
        `);
    }
    @property As r(As = T)() const{
        return this.valueas!(As, "red")();
    }
    @property As g(As = T)() const{
        return this.valueas!(As, "green")();
    }
    @property As b(As = T)() const{
        return this.valueas!(As, "blue")();
    }
    @property As a(As = T)() const{
        return this.valueas!(As, "alpha")();
    }
    
    uint format(in SDL_PixelFormat* format) const{
        return SDL_MapRGBA(format, this.r!ubyte, this.g!ubyte, this.b!ubyte, this.a!ubyte);
    }
    
    static uint pack(in ubyte a, in ubyte b, in ubyte c, in ubyte d){
        return (a << 24) | (b << 16) | (c << 8) | d;
    }
    uint hex() const{
        version(LittleEndian){
            return pack(this.r!ubyte, this.g!ubyte, this.b!ubyte, this.a!ubyte);
        }else{
            return pack(this.a!ubyte, this.b!ubyte, this.g!ubyte, this.r!ubyte);
        }
    }
    
    void clamp(){
        this.clamp(0, this.Max);
    }
    void clamp(N)(in N max) if(isNumeric!N){
        this.clamp(0, max);
    }
    void clamp(N)(in N min, in N max) if(isNumeric!N && !is(N == T)){
        this.clamp(cast(T) min, cast(T) max);
    }
    void clamp(in T min, in T max){
        for(size_t i = 0; i < 4; i++){
            if(this[i] < min) this[i] = min;
            else if(this[i] > max) this[i] = max;
        }
    }
    
    static auto glget(){
        float[4] params;
        glGetFloatv(GL_CURRENT_COLOR, params.ptr);
        return typeof(this)(params[0], params[1], params[2], params[3]);
    }
    
    /// Set glColor to the RGB color represented by this object.
    /// Reference: https://www.opengl.org/sdk/docs/man2/xhtml/glColor.xml
    void glset3(){
        scope(exit) GLError.enforce();
        glColor3f(this.r!float, this.g!float, this.b!float);
    }
    /// Set glColor to the RGBA color represented by this object.
    /// Reference: https://www.opengl.org/sdk/docs/man2/xhtml/glColor.xml
    void glset4(){
        scope(exit) GLError.enforce();
        // TODO: Why does glColor4ub work on Win7 but not OSX?
        glColor4f(this.r!float, this.g!float, this.b!float, this.a!float);
    }
    alias glset = glset4;
    
    Color!N opCast(Type: Color!N, N)() const{
        return Color!N(this);
    }
    SDL_Color opCast(Type: SDL_Color)() const{
        return SDL_Color(this.r!ubyte, this.g!ubyte, this.b!ubyte, this.a!ubyte);
    }
    
    Color!T opBinary(string op, N)(in N rhs) const if(isNumeric!N){
        mixin("return Color!T(
            this.red " ~ op ~ " rhs,
            this.green " ~ op ~ " rhs,
            this.blue " ~ op ~ " rhs,
            this.alpha " ~ op ~ " rhs
        );");
    }
    Color!T opBinaryRight(string op, N)(in N rhs) const if(isNumeric!N){
        mixin("return Color!T(
            rhs " ~ op ~ " this.red,
            rhs " ~ op ~ " this.green,
            rhs " ~ op ~ " this.blue,
            rhs " ~ op ~ " this.alpha
        );");
    }
    void opOpAssign(string op, N)(in N rhs) if(isNumeric!N){
        mixin("
            this.red " ~ op ~ "= rhs;
            this.green " ~ op ~ "= rhs;
            this.blue " ~ op ~ "= rhs;
            this.alpha " ~ op ~ "= rhs;
        ");
    }
    
    T opIndex(in size_t index) const{
        assert((index >= 0) & (index < 4));
        if(index == 0) return this.r;
        else if(index == 1) return this.g;
        else if(index == 2) return this.b;
        else return this.a;
    }
    void opIndexAssign(N)(in N value, in size_t index) if(isNumeric!N){
        assert((index >= 0) & (index < 4));
        if(index == 0) this.red = cast(T) value;
        else if(index == 1) this.green = cast(T) value;
        else if(index == 2) this.blue = cast(T) value;
        else this.alpha = cast(T) value;
    }
    
    bool opEquals(N)(in Color!N color) const{
        return(
            (this.r!ubyte == color.r!ubyte) &
            (this.g!ubyte == color.g!ubyte) &
            (this.b!ubyte == color.b!ubyte) &
            (this.a!ubyte == color.a!ubyte)
        );
    }
    bool opEquals(in uint color) const{
        return this.hex() == color;
    }
    
    string toString() const{
        import std.format : format;
        return "%sR %sG %sB %sA".format(
            this.red, this.green, this.blue, this.alpha
        );
    }
    
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    enum WHITE_HEX = 0xffffffff;
    enum RED_HEX = 0xff0000ff;
    alias Colorf = Color!float;
    alias Colorb = Color!ubyte;
    
    /+ Endians how do they work?
    import std.stdio;
    import std.format;
    Color c = Color(0xffa06000);
    writefln("%8x", c.hex);
    writefln("R: %s", c.red);
    writefln("G: %s", c.green);
    writefln("B: %s", c.blue);
    writefln("A: %s", c.alpha);
    +/
    
    tests("Color", {
        tests("Equality", {
            testeq(Colorf(0.25, 1.0, 0.75, 0.5), Colorf(0.25, 1.0, 0.75, 0.5));
            testeq(Colorb(1, 1, 2, 2), Colorb(1, 1, 2, 2));
            testeq(Color!ubyte(1, 2, 3, 4), Color!uint(1, 2, 3, 4));
            testeq(Colorf(1, 0.5, 0), Colorb(255, 128, 0));
        });
        tests("Hex conversion", {
            testeq(Colorf(RED_HEX), Colorf.Red);
            testeq(Colorf.White.hex(), WHITE_HEX);
            testeq(Colorf(RED_HEX), RED_HEX);
        });
        tests("Indexing", {
            Colorb col = Colorb(0, 1, 2, 3);
            testeq(col[0], 0);
            testeq(col[1], 1);
            testeq(col[2], 2);
            testeq(col[3], 3);
            col[0] = 4;
            testeq(col[0], 4);
            testfail({col[4];});
            testfail({col[4] = 4;});
        });
        tests("Casting", {
            tests("Integral to float", {
                Colorb colb = Colorb(0, 255, 0, 255);
                Colorf colf = cast(Colorf) colb;
                testeq(colf.red, 0.0);
                testeq(colf.green, 1.0);
                testeq(colf.blue, 0.0);
                testeq(colf.alpha, 1.0);
            });
            tests("Float to integral", {
                Colorf colf = Colorf(0, 1.0, 0, 1.0);
                Colorb colb = cast(Colorb) colf;
                testeq(colb.red, 0);
                testeq(colb.green, 255);
                testeq(colb.blue, 0);
                testeq(colb.alpha, 255);
            });
        });
    });
}
