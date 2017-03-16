module mach.sdl.graphics.rendercontext;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import mach.traits : isNumeric;
import mach.math : clamp, Vector, Vector2, Box;
import mach.sdl.window : Window;
import mach.sdl.graphics.color : Color;
import mach.sdl.graphics.texture : Texture;
import mach.sdl.graphics.vertex : Vertexesf;
import mach.sdl.graphics.primitives;

public:



deprecated struct RenderContext{
    Color rendercolor;
    // TODO: Offset, viewport
    
    this(Color color){
        this.rendercolor = color;
        this.rendercolor.glset();
    }
    
    @property auto color() const{
        return this.rendercolor;
    }
    @property void color(in Color color){
        this.rendercolor = color;
        this.rendercolor.glset();
    }
    
    void point(T)(in T x, in T y){
        this.point(Vector2!T(x, y));
    }
    void point(T)(in Vector!(2, T) x){
        this.rendercolor.glset();
        drawpoints(x);
    }
    void points(T)(in Vector!(2, T)[] p...){
        this.rendercolor.glset();
        drawpoints(p);
    }
    
    void line(T)(
        in Vector!(2, T) x,
        in Vector!(2, T) y
    ){
        this.lines(x, y);
    }
    void lines(T)(in Vector!(2, T)[] v...){
        this.rendercolor.glset();
        drawlines(v);
    }
    void lineloop(T)(in Vector!(2, T)[] v...){
        this.rendercolor.glset();
        drawlineloop(v);
    }
    void linestrip(T)(in Vector!(2, T)[] v...){
        this.rendercolor.glset();
        drawlinestrip(v);
    }
    
    void triangle(T)(
        in Vector!(2, T) x,
        in Vector!(2, T) y,
        in Vector!(2, T) z
    ){
        this.triangles(x, y, z);
    }
    void triangles(T)(in Vector!(2, T)[] v...){
        this.rendercolor.glset();
        drawtriangles(v);
    }
    void trianglestrip(T)(in Vector!(2, T)[] v...){
        this.rendercolor.glset();
        drawtrianglestrip(v);
    }
    void trianglefan(T)(in Vector!(2, T)[] v...){
        this.rendercolor.glset();
        drawtrianglefan(v);
    }
    
    void rect(T)(in T x, in T y, in T width, in T height){
        this.rect(Box!T(x, y).at(x, y));
    }
    void rect(T)(
        in Vector!(2, T) topleft,
        in Vector!(2, T) bottomright
    ){
        this.rect(Box!T(topleft, bottomright));
    }
    void rect(T)(in Box!T box){
        this.rendercolor.glset();
        drawquads(box.corners);
    }
    
    void circle(T, R)(in T x, in T y, in R radius){
        this.circle(Vector2!T(x, y), radius);
    }
    void circle(V, R)(in Vector!(2, V) position, in R radius){
        this.circle(position, radius, clamp(cast(uint)(radius / 2), 8, 128));
    }
    void circle(V, R)(in Vector!(2, V) position, in R radius, in uint segments){
        this.rendercolor.glset();
        drawcircle(position, radius, segments);
    }
    
    void texture(T)(Texture* texture, in Vector!(2, T) pos) const{
        this.texture(texture, pos.x, pos.y);
    }
    void texture(T)(Texture* texture, in T x, in T y) const if(isNumeric!T){
        this.texture(texture, Box!T(x, y, x + texture.width, y + texture.height));
    }
    void texture(T)(Texture* texture, in Box!T target) const{
        texture.draw(Vertexesf.rect(
            target.topleft, target.size,
            Box!double(0, 0, 1, 1),
            this.color
        ));
    }
}
