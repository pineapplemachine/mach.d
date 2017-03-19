// Example of a fragment shader which uses a texture loaded from an image as a
// sampler.
// Image source: https://en.wikipedia.org/wiki/File:Ara_chloropterus_-Birmingham_Zoo,_Alabama,_USA-8a.jpg

import mach.sdl;
import mach.math;

// GLSL source for fragment shader.
enum ShaderGLSL = `
#version 330 core

uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D image;

out vec4 color;

void main(){
    vec2 uv = gl_FragCoord.xy / resolution;
    uv.y = 1.0 - uv.y; // Account for flipped Y-axis.
    vec2 origin = uv - mouse;
    float l = length(origin);
    float t = (l > 0.4 ? 0 : (0.4 - l)) * 3.14;
    float a = atan(origin.y, origin.x) + t * t;
    color = texture(image, vec2(cos(a), sin(a)) * length(origin) + mouse);
}
`;

class Sampler: Application{
    GLProgram program;
    GLShader shader;
    GLSampler sampler;
    Texture image;
    
    // Initialize the window.
    override void initialize(){
        window = new Window("Sampler", 200, 200);
    }
    
    // After the window and OpenGL have been fully initialized, load stuff.
    override void postinitialize(){
        enum texunit = 0;
        image = Texture("parrot.jpg");
        window.size = image.size * 0.75;
        sampler = GLSampler(image, texunit);
        shader = GLShader(GLShader.Type.Fragment, ShaderGLSL);
        program = GLProgram(shader);
        program.use();
        program.setuniformf("resolution", window.size);
        program.setuniformi("image", texunit);
    }
    
    // Free memory when it's no longer needed.
    override void conclude(){
        program.free();
        shader.free();
        sampler.free();
        image.free();
    }
    
    // The main application loop.
    override void main(){
        // Update mouse location uniform.
        program.setuniformf("mouse", cast(Vector2f) mouse.position / window.size);
        // Render a rectangle to which the fragment shader will be applied.
        Render.rect(Vector2!int(0, 0), window.size);
        swap();
    }
}

void main(){
    new Sampler().begin;
}
