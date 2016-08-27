module mach.sdl.primitives;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import mach.math.vector2 : Vector2;
import mach.math.vector3 : Vector3;

import mach.sdl.error : GLError;
import mach.sdl.window : Window;
import mach.sdl.color : Color;


import mach.io.log;

public:



void glset(T)(Vector2!T vector){
    static if(is(T == short)) alias glVertex = glVertex2s;
    else static if(is(T == int)) alias glVertex = glVertex2i;
    else static if(is(T == float)) alias glVertex = glVertex2f;
    else static if(is(T == double)) alias glVertex = glVertex2d;
    else static assert(false);
    glVertex(vector.x, vector.y);
}

void glset(T)(Vector3!T vector){
    static if(is(T == short)) alias glVertex = glVertex3s;
    else static if(is(T == int)) alias glVertex = glVertex3i;
    else static if(is(T == float)) alias glVertex = glVertex3f;
    else static if(is(T == double)) alias glVertex = glVertex3d;
    else static assert(false);
    glVertex(vector.x, vector.y, vector.z);
}



auto line(A, B, C)(Window window, Vector2!A v0, Vector2!B v1, Color!C color, float width = 1){
    scope(exit) GLError.enforce();
    window.use();
    color.glset();
    glLineWidth(width);
    glBegin(GL_LINES);
    v0.glset();
    v1.glset();
    glEnd();
}




