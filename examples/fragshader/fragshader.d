// This program provides an example of using a fragment shader to affect the
// video output.

import mach.sdl;
import mach.math;

class FragShader: Application{
    GLShader fragshader;
    GLProgram program;
    
    // Initialize the window.
    override void initialize(){
        window = new Window("FragShader", 200, 200);
    }
    
    // After the window and OpenGL have been fully initialized, load a shader.
    override void postinitialize(){
        // Load and compile a shader from an external file.
        fragshader = GLShader.load(GLShader.Type.Fragment, "shader.glsl");
        // Create, link, and use a program with that shader attached.
        program = GLProgram(fragshader);
        program.use();
        // Set the value of the "resolution" uniform vec2 referred to in the shader.
        program.setuniformf("resolution", window.size);
    }
    
    // Free resources from memory when they are no longer needed.
    override void conclude(){
        program.free();
        fragshader.free();
    }
    
    // The main application loop.
    override void main(){
        // Set the value of the "ticks" uniform float referred to in the shader.
        program.setuniformf("ticks", ticks);
        // Draw a rectangle that the shader will be applied to.
        Render.rect(Vector2!int(0, 0), window.size);
        swap();
    }
}

void main(){
    new FragShader().begin;
}
