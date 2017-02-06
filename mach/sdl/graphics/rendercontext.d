module mach.sdl.graphics.rendercontext;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import mach.math : clamp, Vector2, Box;
import mach.sdl.window : Window;
import mach.sdl.graphics.color : Color;
import mach.sdl.graphics.primitives;

public:



struct RenderContext{
    Color!float rendercolor;
    
    @property auto color(T = float)() const{
        return cast(Color!T) this.rendercolor;
    }
    @property void color(T)(in Color!T color){
        this.rendercolor = cast(typeof(this.rendercolor)) color;
    }
    
    void point(T)(in T x, in T y){
        this.point(Vector2!T(x, y));
    }
    void point(T)(in Vector2!T x){
        this.rendercolor.glset();
        .points(this.rendercolor, x);
    }
    void points(T)(in Vector2!T[] p...){
        this.rendercolor.glset();
        .points(this.rendercolor, p);
    }
    
    void line(T)(in T x0, in T y0, in T x1, in T y1){
        this.line(Vector2!T(x0, y0), Vector2!T(x1, y1));
    }
    void line(T)(in Vector2!T x, in Vector2!T y){
        this.rendercolor.glset();
        .lines(this.rendercolor, x, y);
    }
    void lines(T)(in Vector2!T[] v...){
        this.rendercolor.glset();
        .lines(this.rendercolor, v);
    }
    
    void rect(T)(in T x, in T y, in T width, in T height){
        this.rect(Box!T(x, y).at(x, y));
    }
    void rect(T)(in Box!T box){
        this.rendercolor.glset();
        .quads(this.rendercolor, box.corners);
    }
    
    void circle(T, R)(in T x, in T y, in R radius){
        this.circle(Vector2!T(x, y), radius);
    }
    void circle(V, R)(in Vector2!V position, in R radius){
        this.circle(position, radius, clamp(radius / 2, 8, 128));
    }
    void circle(V, R)(in Vector2!V position, in R radius, in uint segments){
        this.rendercolor.glset();
        .circle(position, radius, segments);
    }
}
