// This program provides an example of using a fragment shader to affect the
// video output.

import mach.sdl;
import mach.math;
import derelict.opengl3.gl;
import mach.io;

class FragShader: Application{
    
    GLVertexArray vao;
    
    GLProgram program;
    GLShader vertshader;
    GLShader fragshader;
    
    /// Transform screen space 2D pixel coordinates to OpenGL coordinates
    static immutable vertsource = `
    #version 330 core
    uniform vec2 resolution;
    in vec2 position;
    void main(){
        vec2 pos = (position * 2.0 / resolution) - vec2(1.0);
        gl_Position = vec4(
            pos.x, -pos.y, 0.0, 1.0
        );
    }
    `;
    /// Fragment shader suitable for primitives filled entirely with one color.
    static immutable fragsource = `
    #version 330 core
    uniform vec4 tintcolor;
    out vec4 fragcolor;
    void main(){
        fragcolor = tintcolor;
    }
    `;
    /// Fragment shader suitable for textures.
    static immutable texfragsource = `
    #version 330 core
    uniform vec4 tintcolor;
    out vec4 fragcolor;
    
    `;
    
    // Initialize the window.
    override void initialize(){
        window = new Window("FragShader", 200, 200);
    }
    
    // After the window and OpenGL have been fully initialized, load a shader.
    override void postinitialize(){
        GLVertexArray array0;
        array0.initialize();
        array0.bind();
        
        // Load and compile a shader from an external file.
        vertshader = GLShader(GLShader.Type.Vertex, vertsource);
        fragshader = GLShader(GLShader.Type.Fragment, fragsource);
        // Create, link, and use a program with that shader attached.
        program.initialize();
        program.add(vertshader);
        program.add(fragshader);
        program.link();
        program.use();
        
        GLint posattrib = glGetAttribLocation(program.program, "position");
        
        GLVertexArray.enable(posattrib);
        
        auto verts = GLBuffer(GLBuffer.Target.Array);
        verts.setdata(
            posattrib, GLBuffer.Target.Array, GLBuffer.Usage.StaticDraw,
            //[
            //    Vector2!float(-.5, +.5), Vector2!float(+.5, +.5),
            //    Vector2!float(+.5, -.5), Vector2!float(-.5, -.5),
            //]
            [
                Vector2!float(10, 50), Vector2!float(50, 50),
                Vector2!float(50, 10), Vector2!float(10, 10),
            ]
        );
        
        
        
        
        
        //glBindAttribLocation(program.program, 0, "position");
        //glBindAttribLocation(program.program, 1, "color");
        
        
        // Set the value of the "resolution" uniform vec2 referred to in the shader.
        program.setuniformf("resolution", window.size);
        
        program.setuniformf("tintcolor", Color.Red);
    }
    
    // Free resources from memory when they are no longer needed.
    override void conclude(){
        program.free();
        vertshader.free();
        fragshader.free();
    }
    
    // The main application loop.
    override void main(){
        assert(program.program != 0);
        // Set the value of the "ticks" uniform float referred to in the shader.
        //program.setuniformf("ticks", ticks);
        // Draw a rectangle that the shader will be applied to.
        //Render.rect(Vector2!int(0, 0), window.size);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        swap();
    }
}

void main(){
    new FragShader().begin;
}
