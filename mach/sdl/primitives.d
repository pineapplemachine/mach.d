module mach.sdl.primitives;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import mach.meta : All;
import mach.traits : isTemplateOf;
import mach.math.vector2 : Vector2;
import mach.math.vector3 : Vector3;

import mach.sdl.error : GLError;
import mach.sdl.window : Window;
import mach.sdl.color : Color;


import mach.io.log;

public:



void glVertex(T)(T x, T y){
    static if(is(T == short)) alias impl = glVertex2s;
    else static if(is(T == int)) alias impl = glVertex2i;
    else static if(is(T == float)) alias impl = glVertex2f;
    else static if(is(T == double)) alias impl = glVertex2d;
    else alias impl = void;
    static if(!is(impl == void)){
        impl(x, y);
    }else static if(isIntegral!T){
        glVertex3i(cast(int) x, cast(int) y);
    }else{
        glVertex3d(cast(double) x, cast(double) y);
    }
}
void glVertex(T)(T x, T y, T z){
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


void glset(T)(Vector2!T vector){
    glVertex!T(vector.x, vector.y);
}

void glset(T)(Vector3!T vector){
    glVertex!T(vector.x, vector.y, vector.z);
}

enum isVector2(T) = isTemplateOf!(T, Vector2);



auto primitives(alias mode, C, Vectors...)(Color!C color, Vectors vectors) if(
    All!(isVector2, Vectors)
){
    static if(vectors.length){
        scope(exit) GLError.enforce();
        color.glset();
        glBegin(mode);
        foreach(vector; vectors) vector.glset();
        glEnd();
    }
}
//auto primitives(alias mode, C, T)(Color!C color, Vector2!T[] vectors){
//    if(vectors && vectors.length){
//        scope(exit) GLError.enforce();
//        color.glset();
//        glBegin(mode);
//        foreach(vector; vectors) vector.glset();
//        glEnd();
//    }
//}



auto points(C, Vectors...)(Color!C color, Vectors vectors) if(
    All!(isVector2, Vectors)
){
    primitives!(GL_POINTS, C, Vectors)(color, vectors);
}

auto lines(C, Vectors...)(Color!C color, float width, Vectors vectors) if(
    All!(isVector2, Vectors)
)in{
    assert(vectors.length % 2 == 0);
}body{
    glLineWidth(width);
    primitives!(GL_LINES, C, Vectors)(color, vectors);
}






