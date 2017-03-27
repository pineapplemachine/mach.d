module mach.sdl.graphics.primitive;

private:

import mach.math : Vector;
import mach.sdl.graphics.vao;

public:



struct Triangles{
    /// Transform screen space 2D pixel coordinates to OpenGL coordinates
    static immutable VertexShaderSource = `
        #version 150 core
        uniform vec2 resolution;
        in vec2 position;
        in vec4 incolor;
        out vec4 vertcolor;
        void main(){
            vec2 pos = (position * 2.0 / resolution) - vec2(1.0);
            gl_Position = vec4(pos.x, -pos.y, 0.0, 1.0);
            vertcolor = incolor;
        }
    `;
    /// Fragment shader suitable for primitives filled entirely with one color.
    static immutable FragmentShaderSource = `
        #version 150 core
        in vec4 vertcolor;
        out vec4 fragcolor;
        void main(){
            fragcolor = vertcolor;
        }
    `;
    
    alias Vertex = Vector!(2, float);
    
    GLShader vertshader;
    GLShader fragshader;
    GLProgram program;
    GLBuffer vbo;
    Vertex[] vertexes;
    
    @property void resolution(N)(in Vector!(2, N) resolution){
        this.program.setuniform("resolution", resolution);
    }
    
    void initialize(){
        this.vbo.initialize();
        this.vertshader = GLShader(GLShader.Type.Vertex, VertexShaderSource);
        this.fragshader = GLShader(GLShader.Type.Fragment, FragmentShaderSource);
        this.program = GLProgram(vertshader, fragshader);
    }
    void free(){
        this.vbo.free();
    }
    void flush(){
        this.vbo.bind();
        this.vbo.setdata(
            0, GLBuffer.Target.Array, GLBuffer.Usage.StaticDraw, this.vertexes
        );
        this.program.use();
    }
}

