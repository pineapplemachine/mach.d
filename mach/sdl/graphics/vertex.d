module mach.sdl.graphics.vertex;

private:

import derelict.opengl3.gl;

import mach.traits : isNumeric;
import mach.math.vector2 : Vector2;
import mach.math.box : Box;
import mach.sdl.error : GLError;
import mach.sdl.glenum : VertexType, getvertextype, validvertextype;
import mach.sdl.graphics.color : Color;

public:

struct Vertex(Pos = float, Tex = float, Col = float) if(
    validvertextype!Pos && validvertextype!Tex && validvertextype!Col
){
    Vector2!Pos position;
    Vector2!Tex texcoord;
    Color!Col color;
    
    this(A = Pos, B = Tex, C = Col)(
        Vector2!A position = Vector2!A.Zero,
        Vector2!B texcoord = Vector2!B.Zero,
        Color!C color = Color!C.White
    ){
        this.position = cast(Vector2!Pos) position;
        this.texcoord = cast(Vector2!Tex) texcoord;
        this.color = cast(Color!Col) color;
    }
    
    string toString() const{
        import std.format : format;
        return "(%s), (%s), (%s)".format(
            this.position, this.texcoord, this.color
        );
    }
}

struct Vertexes(Pos = float, Tex = float, Col = float) if(
    validvertextype!Pos && validvertextype!Tex && validvertextype!Col
){
    
    alias Verts = Vertexes!(Pos, Tex, Col);
    alias Vert = Vertex!(Pos, Tex, Col);
    Vert[] verts;
    
    this(Vert[] verts){
        this.verts = verts;
    }
    
    static Verts rect(A, B = Col)(
        in Box!A target,
        in Color!B color = Color!B.White
    ){
        return Verts.rect(target.topleft, target.size, color);
    }
    static Verts rect(A, B, C = Tex, D = Col)(
        in Vector2!A position,
        in Vector2!B size,
        in Color!D color = Color!D.White
    ){
        return Verts.rect(position, size, Vector2!Tex.Zero, color);
    }
    static Verts rect(A, B, C = Col)(
        in Vector2!A position,
        in Vector2!B size,
        in Color!C color = Color!C.White
    ){
        return Verts.rect(position, size, Box!Tex(1, 1), color);
    }
    static Verts rect(A, B, C, D = Col)(
        in Vector2!A position, // Position on screen
        in Vector2!B size, // Render target size
        in Box!C texsub, // Portion of texture to render (values should generally be 0-1)
        in Color!D color = Color!D.White // Channel multipliers
    ){
        return Verts([
            Vert(
                position,
                texsub.topleft,
                color
            ),
            Vert(
                Vector2!Pos(position.x + size.x, position.y),
                texsub.topright,
                color
            ),
            Vert(
                Vector2!Pos(position.x, position.y + size.y),
                texsub.bottomleft,
                color
            ),
            Vert(
                position + size,
                texsub.bottomright,
                color
            ),
        ]);
    }
    
    /// Set GL vertex pointers in preparation for a glDrawArrays call.
    void setglpointers() const{
        // Deprecated?
        glVertexPointer(2, getvertextype!(Pos), Vert.sizeof, &this.verts[0].position);
        glTexCoordPointer(2, getvertextype!(Tex), Vert.sizeof, &this.verts[0].texcoord);
        glColorPointer(4, getvertextype!(Col), Vert.sizeof, &this.verts[0].color);
    }
    
    static uint getvertexbuffer(){
        static bool vertexbufferinit = false;
        static uint vertexbuffer;
        if(!vertexbufferinit){
            // https://solarianprogrammer.com/2013/05/13/opengl-101-drawing-primitives/
            glGenBuffers(1, &vertexbuffer);
            glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
            //glBufferData(GL_ARRAY_BUFFER, Vert.sizeof * this.verts.length, this.verts, GL_STATIC_DRAW);
            vertexbufferinit = true;
        }
        return vertexbuffer;
    }
    
    @property size_t length() const{
        return this.verts.length;
    }
    Vert opIndex(in size_t index) const{
        return this.verts[index];
    }
    void opIndexAssign(in Vert value, in size_t index){
        this.verts[index] = value;
    }
    void opOpAssign(T, string op: "~")(in T rhs) if(is(T == Vert) || is(T == Verts)){
        this.verts ~= rhs;
    }
    
}

alias Vertexesf = Vertexes!(float, float, float);

/+ TODO
version(unittest) import mach.error.unit;
unittest{
    import std.stdio;
    writeln(Vertex!float.rect(Vector2!float(0, 0), Vector2!int(10, 10)));
}
+/
