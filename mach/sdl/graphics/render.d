module mach.sdl.graphics.render;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import mach.traits : isNumeric, isIntegral;
import mach.math : vector, Vector, isVector, Box;
import mach.sdl.graphics.color : Color;
import mach.sdl.graphics.texture : Texture;
import mach.sdl.graphics.vertex : Vertexesf;
import mach.sdl.error : GLException;

public:



/// Thrown when Render methods fail due to illegal input.
class RenderError: Error{
    this(string message, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, null);
    }
    auto enforce(T)(T cond) const{
        if(!cond) throw this;
        return cond;
    }
}



struct Render{
    /// An enumeration of recognized OpenGL rendering modes.
    static enum Mode: uint{
        Points = GL_POINTS,
        Lines = GL_LINES,
        LineStrip = GL_LINE_STRIP,
        LineLoop = GL_LINE_LOOP,
        Triangles = GL_TRIANGLES,
        TriangleStrip = GL_TRIANGLE_STRIP,
        TriangleFan = GL_TRIANGLE_FAN,
        Quads = GL_QUADS,
        QuadStrip = GL_QUAD_STRIP,
        Polygon = GL_POLYGON,
    }
    
    private template isVertexVector(T){
        enum bool isVertexVector = isVector!(2, T) || isVector!(3, T);
    }
    
    @disable this();
    
    /// Set glColor to the specified RGB values.
    /// https://www.opengl.org/sdk/docs/man2/xhtml/glColor.xml
    static void rgb(in float red, in float green, in float blue){
        scope(exit) GLException.enforce();
        glColor3f(red, green, blue);
    }
    /// Set glColor to the specified RGBA values.
    /// https://www.opengl.org/sdk/docs/man2/xhtml/glColor.xml
    static void rgba(in float red, in float green, in float blue, in float alpha){
        // TODO: Why does glColor4ub work on Win7 but not OSX?
        scope(exit) GLException.enforce();
        glColor4f(red, green, blue, alpha);
    }
    
    static @property auto color(){
        float[4] params;
        glGetFloatv(GL_CURRENT_COLOR, params.ptr);
        return Color(params[0], params[1], params[2], params[3]);
    }
    static @property void color(in Color color){
        typeof(this).rgba(color.r, color.g, color.b, color.a);
    }
    
    /// Begin specifying vertexes for a given draw mode.
    static void begin(in uint mode){
        glBegin(mode);
    }
    /// End specifying vertexes for a given draw mode.
    static void end(){
        glEnd();
    }
    /// If any OpenGL errors have been set, throw an exception.
    static void enforce(){
        GLException.enforce();
    }
    /// Begin drawing in a given mode, call the delegate, then end drawing
    /// and check whether any errors occurred.
    static void draw(in uint mode, in void delegate() apply){
        scope(exit) typeof(this).enforce();
        typeof(this).begin(mode);
        apply();
        typeof(this).end();
    }
    /// Begin drawing in a given mode, add the given vertexes, then end drawing
    /// and check whether any errors occurred.
    static void draw(V)(in uint mode, in V[] vectors...) if(isVertexVector!V){
        scope(exit) typeof(this).enforce();
        typeof(this).begin(mode);
        foreach(vector; vectors) typeof(this).add(vector);
        typeof(this).end();
    }
    
    /// Add a vertex to be rendered in the current mode.
    static void add(V)(in V vector) if(isVertexVector!V){
        typeof(this).add(vector.values);
    }
    /// Ditto
    static void add(T)(in T x, in T y) if(isNumeric!T){
        static if(is(T == short)) alias impl = glVertex2s;
        else static if(is(T == int)) alias impl = glVertex2i;
        else static if(is(T == float)) alias impl = glVertex2f;
        else static if(is(T == double)) alias impl = glVertex2d;
        else alias impl = void;
        static if(!is(impl == void)){
            impl(x, y);
        }else static if(isIntegral!T){
            glVertex2i(cast(int) x, cast(int) y);
        }else{
            glVertex2d(cast(double) x, cast(double) y);
        }
    }
    /// Ditto
    static void add(T)(in T x, in T y, in T z) if(isNumeric!T){
        static if(is(T == short)) alias impl = glVertex3s;
        else static if(is(T == int)) alias impl = glVertex3i;
        else static if(is(T == float)) alias impl = glVertex3f;
        else static if(is(T == double)) alias impl = glVertex3d;
        else alias impl = void;
        static if(!is(impl == void)){
            impl(x, y, z);
        }else static if(isIntegral!T){
            glVertex3i(cast(int) x, cast(int) y, cast(int) z);
        }else{
            glVertex3d(cast(double) x, cast(double) y, cast(double) z);
        }
    }
    
    static void point(T)(in T x, in T y){
        points(Vector2!T(x, y));
    }
    static void point(V)(in V vector) if(isVertexVector!V){
        points(vector);
    }
    static void points(V)(in V[] vectors...) if(isVertexVector!V){
        draw(Mode.Points, vectors);
    }
    
    /// Draw a line between the points (x, y) and (z, w).
    static void line(T)(in T x, in T y, in T z, in T w) if(isNumeric!T){
        lines(vector(x, y), vector(z, w));
    }
    /// Draw a line between two points.
    static void line(V)(in V x, in V y) if(isVertexVector!V){
        lines(x, y);
    }
    /// Draw lines represented by a series of points.
    static void lines(V)(in V[] vectors...) if(isVertexVector!V) in{
        static const error = new RenderError("Incorrect number of vertexes.");
        error.enforce(vectors.length % 2 == 0);
    }body{
        draw(Mode.Lines, vectors);
    }
    static void linestrip(V)(in V[] vectors...) if(isVertexVector!V){
        draw(Mode.LineStrip, vectors);
    }
    static void lineloop(V)(in V[] vectors...) if(isVertexVector!V){
        draw(Mode.LineLoop, vectors);
    }
    
    /// Points should progress in a clockwise direction, otherwise the result
    /// won't be visible.
    static void triangle(V)(in V x, in V y, in V z) if(isVertexVector!V){
        triangles(x, y, z);
    }
    static void triangles(V)(in V[] vectors...) if(isVertexVector!V){
        draw(Mode.Triangles, vectors);
    }
    static void trianglestrip(V)(in V[] vectors...) if(isVertexVector!V){
        draw(Mode.TriangleStrip, vectors);
    }
    static void trianglefan(V)(in V[] vectors...) if(isVertexVector!V){
        draw(Mode.TriangleLoop, vectors);
    }
    
    static void rect(T)(in T leftx, in T topy, in T rightx, in T bottomy){
        rects(
            vector(leftx, topy), vector(rightx, topy),
            vector(rightx, bottomy), vector(leftx, bottomy)
        );
    }
    static void rect(V)(in V topleft, in V bottomright) if(isVector!(2, V)){
        rects(
            topleft, V(bottomright.x, topleft.y),
            bottomright, V(topleft.x, bottomright.y)
        );
    }
    static void rect(T)(in Box!T box){
        rects(box.corners);
    }
    static void rects(V)(in V[] vectors...) if(isVertexVector!V){
        draw(Mode.Quads, vectors);
    }
    static void quadstrip(V)(in V[] vectors...) if(isVertexVector!V){
        draw(Mode.QuadStrip, vectors);
    }
    
    static void circle(bool fill = true, T, R)(in T x, in T y, in R radius){
        circle!fill(Vector2!T(x, y), radius);
    }
    static void circle(bool fill = true, V, R)(in Vector!(2, V) position, in R radius){
        circle!fill(position, radius, clamp(cast(uint)(radius / 2), 8, 128));
    }
    /// Credit http://slabode.exofire.net/circle_draw.shtml
    /// TODO: Ellipses
    static void circle(bool fill = true, V, R)(in Vector!(2, V) position, in R radius, in uint segments){
        scope(exit) typeof(this).enforce();
        immutable double theta = tau / cast(double) segments;
        immutable double c = cos(theta);
        immutable double s = sin(theta);
        immutable dcenter = cast(Vector!(2, double)) center;
        double x = cast(double) radius;
        double y = 0.0;
        static if(fill){
            typeof(this).begin(Mode.TriangleFan);
            typeof(this).add(dcenter);
        }else{
            typeof(this).begin(Mode.LineLoop);
        }
        for(uint i = 0; i < segments; i++){
            typeof(this).add(dcenter + Vector2!double(x, y));
            immutable double t = x;
            x = c * x - s * y;
            y = s * t + c * y;
        }
        static if(fill){
            typeof(this).add(dcenter + Vector2!double(x, y));
        }
        typeof(this).end();
    }
    
    /// Draw a texture tinted the current rendering settings.
    /// Drawing the texture independently with its own draw call will not
    /// respect the rendering settings.
    static void texture(T)(Texture texture, in Vector!(2, T) pos) const{
        this.texture(texture, pos.x, pos.y);
    }
    static void texture(T)(Texture texture, in T x, in T y) const if(isNumeric!T){
        this.texture(texture, Box!T(x, y, x + texture.width, y + texture.height));
    }
    static void texture(T)(Texture texture, in Box!T target) const{
        texture.draw(Vertexesf.rect(
            target.topleft, target.size,
            Box!double(0, 0, 1, 1),
            this.color
        ));
    }
}
