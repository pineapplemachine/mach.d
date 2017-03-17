module mach.sdl.graphics.shader;

private:

import derelict.opengl3.arb;
import derelict.opengl3.gl;
import derelict.opengl3.functions;

import mach.traits : isString, isNumeric, isIntegral, isArrayOf;
import mach.math.vector : Vector, isVector, isVector2, isVector3, isVector4;
import mach.math.matrix : Matrix, isMatrix;
import mach.text.cstring : tocstring;
import mach.range.asarray : asarray;
import mach.io.file.path : Path;

import mach.sdl.error : GLException;

public:



/// Represents an OpenGL program, to which shaders are attached.
/// TODO: More exhaustive support of program features
struct GLProgram{
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetProgram.xhtml
    static enum Parameter: uint{
        Deleting = GL_DELETE_STATUS,
        Linked = GL_LINK_STATUS,
        Valid = GL_VALIDATE_STATUS,
        InfoLength = GL_INFO_LOG_LENGTH,
        ShadersLength = GL_ATTACHED_SHADERS,
        AtomicCounterBuffers = GL_ACTIVE_ATOMIC_COUNTER_BUFFERS,
        Attributes = GL_ACTIVE_ATTRIBUTES,
        MaxAttributeLength = GL_ACTIVE_ATTRIBUTE_MAX_LENGTH,
        Uniforms = GL_ACTIVE_UNIFORMS,
        MaxUniformLength = GL_ACTIVE_UNIFORM_MAX_LENGTH,
        UniformBlocks = GL_ACTIVE_UNIFORM_BLOCKS, // OpenGL 3.1 and greater
        MaxUniformBlockLength = GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH, // OpenGL 3.1 and greater
        WorkGroupSize = GL_COMPUTE_WORK_GROUP_SIZE, /// OpenGL 4.3 and greater
        BinaryLength = GL_PROGRAM_BINARY_LENGTH,
        TransformBufferMode = GL_TRANSFORM_FEEDBACK_BUFFER_MODE,
        TransformVaryings = GL_TRANSFORM_FEEDBACK_VARYINGS,
        MaxTransformVaryingLength = GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH,
        VertexesOut = GL_GEOMETRY_VERTICES_OUT,
        InputType = GL_GEOMETRY_INPUT_TYPE,
        OutputType = GL_GEOMETRY_OUTPUT_TYPE,
    }
    
    /// Exception type thrown when program linking fails.
    class LinkException: GLException{
        this(string message, size_t line = __LINE__, string file = __FILE__){
            super("\n" ~ message, null, line, file);
        }
    }
    
    @disable this(this);
    
    GLuint program;
    
    /// Create a new program with the given shaders attached to it, and then
    /// link the program.
    this(GLShader*[] shaders...){
        this.initialize();
        foreach(shader; shaders) this.add(shader);
        this.link();
    }
    
    ~this(){
        if(this.program != 0) this.free();
    }
    
    /// Create a new, empty program.
    void initialize(){
        this.program = glCreateProgram();
        if(this.program == 0) throw new GLException("Failed to create program.");
    }
    
    /// Detach shaders then delete the program from memory.
    void free(){
        this.removeall();
        glDeleteProgram(program);
        this.program = 0;
    }
    
    /// Link the program. Throws a LinkException if linking fails.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glLinkProgram.xhtml
    void link(){
        glLinkProgram(this.program);
        if(!this.linked) throw new LinkException(this.info);
    }
    
    /// Use this program for the current rendering state.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glUseProgram.xhtml
    void use(){
        assert(this.program != 0);
        glUseProgram(this.program);
        GLException.enforce("Failed to use program.");
    }
    
    /// Get the program's info log, generated upon linking.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetProgramInfoLog.xhtml
    @property string info(){
        assert(this.program != 0);
        auto length = this.infolength;
        if(length == 0) return "";
        char[] result = new char[length - 1];
        glGetProgramInfoLog(this.program, cast(GLsizei) result.length, null, result.ptr);
        return cast(string) result;
    }
    
    /// Get attached shaders.
    /// Returns an array of identifiers. (Not an array of GLShader objects!)
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetAttachedShaders.xhtml
    @property auto shaders(){
        assert(this.program != 0);
        auto length = this.shaderslength;
        GLuint[] result = new GLuint[length];
        glGetAttachedShaders(this.program, length, null, result.ptr);
        return result;
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetProgram.xhtml
    auto parameter(in Parameter parameter) const{
        assert(this.program != 0);
        assert(parameter != Parameter.WorkGroupSize,
            "Parameter unsupported by this method; use workgroupsize instead."
        );
        GLint result = -1;
        glGetProgramiv(this.program, parameter, &result);
        // If result wasn't modified, indicates an error occurred.
        // (-1 should never be a valid result.)
        if(result == -1) throw new GLException("Failed to get program parameter.");
        return result;
    }
    
    /// Get the size of a program's compute work group as a three-dimensional vector.
    /// OpenGL Superbible p. 674
    @property auto workgroupsize(){
        assert(this.program != 0);
        auto size = Vector!(3, GLint)(-1, -1, -1);
        glGetProgramiv(this.program, Parameter.WorkGroupSize, cast(GLint*) &size);
        if(size.x == -1) throw new GLException("Failed to get program parameter.");
        return size;
    }
    
    /// Get the length in characters of the program's info log.
    @property auto infolength() const{
        return this.parameter(Parameter.InfoLength);
    }
    /// Get the the number of shaders attached to this program.
    @property auto shaderslength() const{
        return this.parameter(Parameter.ShadersLength);
    }
    /// Get whether the program has been successfully linked.
    @property bool linked() const{
        return cast(bool) this.parameter(Parameter.Linked);
    }
    /// Get whether the program has been flagged for deletion.
    @property bool deleting() const{
        return cast(bool) this.parameter(Parameter.Deleting);
    }
    
    /// Attach a shader to this program.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glAttachShader.xhtml
    void add(in GLuint shader){
        glAttachShader(this.program, shader);
    }
    /// Ditto
    void add(in GLShader* shader){
        this.add(shader.shader);
    }
    /// Detach a shader from this program.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glDetachShader.xhtml
    void remove(in GLuint shader){
        glDetachShader(this.program, shader);
    }
    /// Ditto
    void remove(in GLShader* shader){
        this.remove(shader.shader);
    }
    /// Deatch all attached shaders from this program.
    void removeall(){
        foreach(shader; this.shaders) this.remove(shader);
    }
    
    auto uniformlocation(in string name) const{
        assert(this.program != 0);
        auto location = glGetUniformLocation(this.program, name.tocstring);
        if(location == -1) throw new GLException("Invalid uniform name.");
        return location;
    }
    
    template UniformMatrixFunction(size_t width, size_t height){
        static assert(T.width >= 2 && T.width <= 4 && T.height >= 2 && T.height <= 4,
            "Unsupported matrix size."
        );
        static if(width == height){
            mixin(`alias UniformMatrixFunction = (
                glUniformMatrix` ~ ctint(width) ~ `fv
            );`);
        }else{
            mixin(`alias UniformMatrixFunction = (
                glUniformMatrix` ~ ctint(width) ~ `x` ~ ctint(height) ~ `fv
            );`);
        }
    }
    private void SetUniformGeneric(GLtype, string glchar, T)(in string name, in T value){
        mixin(`
            alias uniform1 = glUniform1` ~ glchar ~ `;
            alias uniform2 = glUniform2` ~ glchar ~ `;
            alias uniform3 = glUniform3` ~ glchar ~ `;
            alias uniform4 = glUniform4` ~ glchar ~ `;
            alias uniform1v = glUniform1` ~ glchar ~ `v;
            alias uniform2v = glUniform2` ~ glchar ~ `v;
            alias uniform3v = glUniform3` ~ glchar ~ `v;
            alias uniform4v = glUniform4` ~ glchar ~ `v;
        `);
        immutable loc = this.uniformlocation(name);
        static if(isNumeric!T){
            uniform1(loc, cast(GLtype) value);
        }else static if(isVector2!T){
            uniform2(loc, (cast(Vector!(T.size, GLtype)) value).values);
        }else static if(isVector3!T){
            uniform3(loc, (cast(Vector!(T.size, GLtype)) value).values);
        }else static if(isVector4!T){
            uniform4(loc, (cast(Vector!(T.size, GLtype)) value).values);
        }else static if(isArrayOf!(isNumeric, T)){
            immutable vecs = value.asarray!GLtype.ptr;
            uniform1v(loc, cast(GLsizei) value.length, vecs.ptr);
        }else static if(isArrayOf!(isVector2, T)){
            immutable vecs = value.asarray!(Vector!(2, GLtype)).ptr;
            uniform2v(loc, cast(GLsizei) value.length, vecs.ptr);
        }else static if(isArrayOf!(isVector3, T)){
            immutable vecs = value.asarray!(Vector!(3, GLtype)).ptr;
            uniform3v(loc, cast(GLsizei) value.length, vecs.ptr);
        }else static if(isArrayOf!(isVector4, T)){
            immutable vecs = value.asarray!(Vector!(4, GLtype)).ptr;
            uniform4v(loc, cast(GLsizei) value.length, vecs.ptr);
        }else static if(is(GLtype == GLfloat) && isMatrix!T){
            alias uniform = UniformMatrixFunction!(T.width, T.height);
            assert(uniform !is null, "Matrix type unsupported by OpenGL version.");
            immutable mat = cast(Matrix!(T.width, T.height, GLfloat)) value;
            uniform(loc, 1, false, &mat);
        }else static if(is(GLtype == GLfloat) && isArrayOf!(isMatrix, T)){
            alias uniform = UniformMatrixFunction!(typeof(T[0]).width, typeof(T[0]).height);
            assert(uniform !is null, "Matrix type unsupported by OpenGL version.");
            immutable mats = value.asarray!(Matrix!(T.width, T.height, GLfloat));
            uniform(loc, 1, false, mats.ptr);
        }else{
            static assert(false, "Unsupported argument type.");
        }
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glUniform.xhtml
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetUniformLocation.xhtml
    void setuniformf(T)(in string name, in T value){
        this.SetUniformGeneric!(GLfloat, "f")(name, value);
    }
    /// Ditto
    void setuniformi(T)(in string name, in T value){
        this.SetUniformGeneric!(GLint, "i")(name, value);
    }
    /// Ditto
    void setuniformu(T)(in string name, in T value){
        this.SetUniformGeneric!(GLuint, "ui")(name, value);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetUniform.xhtml
    void getuniform(T)(in string name){
        // TODO
    }
}



/// Represents an OpenGL shader.
struct GLShader{
    /// An enumeration of the different types of shaders.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glCreateShader.xhtml
    static enum Type: uint{
        Compute = GL_COMPUTE_SHADER,
        Vertex = GL_VERTEX_SHADER,
        TessControl = GL_TESS_CONTROL_SHADER,
        TessEvaluation = GL_TESS_EVALUATION_SHADER,
        Geometry = GL_GEOMETRY_SHADER,
        Fragment = GL_FRAGMENT_SHADER,
    }
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetShader.xhtml
    static enum Parameter: uint{
        Type = GL_SHADER_TYPE,
        Deleting = GL_DELETE_STATUS,
        Compiled = GL_COMPILE_STATUS,
        InfoLength = GL_INFO_LOG_LENGTH,
        SourceLength = GL_SHADER_SOURCE_LENGTH,
    }
    
    /// Exception type thrown when shader compilation fails.
    class CompileException: GLException{
        this(string message, size_t line = __LINE__, string file = __FILE__){
            super("\n" ~ message, null, line, file);
        }
    }
    
    @disable this(this);
    
    /// Stores a shader ID assigned upon creation.
    GLuint shader;
    
    /// Load a shader from a string literal.
    this(in Type type, in string source){
        this.shader = glCreateShader(type);
        if(this.shader == 0) throw new GLException("Failed to create shader.");
        this.source = source;
        this.compile();
    }
    
    /// Load a shader from a file path.
    static auto load(S)(in Type type, in S path) if(isString!S){
        return new typeof(this)(type, cast(string) Path(path).readall);
    }
    
    /// Delete the shader from memory when the object is destroyed.
    ~this(){
        if(this.shader != 0) this.free();
    }
    
    /// Free a previously-created shader.
    void free(){
        glDeleteShader(this.shader);
        this.shader = 0;
    }
    
    /// Set the shader's source code as a string.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glShaderSource.xhtml
    @property void source(in string source){
        assert(this.shader != 0);
        auto length = cast(GLint) source.length;
        auto ptr = source.ptr;
        glShaderSource(this.shader, 1, &ptr, &length);
    }
    /// Get the shader's source code.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetShaderSource.xhtml
    @property string source() const{
        assert(this.shader != 0);
        auto length = this.sourcelength;
        if(length == 0) return "";
        char[] result = new char[length - 1];
        glGetShaderSource(this.shader, cast(GLsizei) result.length, null, result.ptr);
        return cast(string) result;
    }
    
    /// Compile the shader. Throws a CompileException if compilation fails.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glCompileShader.xhtml
    void compile(){
        glCompileShader(this.shader);
        if(!this.compiled) throw new CompileException(this.info);
    }
    
    /// Get the shader's info log, generated upon compilation.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetShaderInfoLog.xhtml
    @property string info() const{
        assert(this.shader != 0);
        auto length = this.infolength;
        if(length == 0) return "";
        char[] result = new char[length - 1];
        glGetShaderInfoLog(this.shader, cast(GLsizei) result.length, null, result.ptr);
        return cast(string) result;
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetShader.xhtml
    auto parameter(in Parameter parameter) const{
        assert(this.shader != 0);
        GLint result = -1;
        glGetShaderiv(this.shader, parameter, &result);
        // If result wasn't modified, indicates an error occurred.
        // (-1 should never be a valid result.)
        if(result == -1) throw new GLException("Failed to get shader parameter.");
        return result;
    }
    
    /// Get the length in characters of the shader's source.
    @property auto sourcelength() const{
        return this.parameter(Parameter.SourceLength);
    }
    /// Get the length in characters of the shader's info log.
    @property auto infolength() const{
        return this.parameter(Parameter.InfoLength);
    }
    /// Get the shader type.
    @property Type type() const{
        return cast(Type) this.parameter(Parameter.Type);
    }
    /// Get whether the shader has been successfully compiled.
    @property bool compiled() const{
        return cast(bool) this.parameter(Parameter.Compiled);
    }
    /// Get whether the shader has been flagged for deletion.
    @property bool deleting() const{
        return cast(bool) this.parameter(Parameter.Deleting);
    }
}
