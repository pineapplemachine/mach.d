module mach.sdl.graphics.vao;

private:

import derelict.opengl3.arb;
import derelict.opengl3.gl3;

import mach.traits : isNumeric, Unqual;
import mach.math.vector : isVector;

import mach.sdl.error : GLException;

// TODO: Possibly not the best place for this
template GLTypeEnum(T){
    alias U = Unqual!T;
    static if(is(T == byte)) enum GLTypeEnum = GL_BYTE;
    else static if(is(T == short)) enum GLTypeEnum = GL_SHORT;
    else static if(is(T == int)) enum GLTypeEnum = GL_INT;
    else static if(is(T == ubyte)) enum GLTypeEnum = GL_UNSIGNED_BYTE;
    else static if(is(T == ushort)) enum GLTypeEnum = GL_UNSIGNED_SHORT;
    else static if(is(T == uint)) enum GLTypeEnum = GL_UNSIGNED_INT;
    else static if(is(T == float)) enum GLTypeEnum = GL_FLOAT;
    else static if(is(T == double)) enum GLTypeEnum = GL_DOUBLE;
    else static assert(false, "Type has no OpenGL enum analog.");
}

public:



// Useful references:
// https://www.opengl.org/discussion_boards/showthread.php/169070-(3-2)-Inline-Replacement-for-the-Matrix-Stack
// https://www.khronos.org/opengl/wiki/Tutorial2:_VAOs,_VBOs,_Vertex_and_Fragment_Shaders_(C_/_SDL)
// https://open.gl/introduction



struct GLVertexArray{
    
    GLuint array;
    
    this(GLuint array){
        this.array = array;
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGenVertexArrays.xhtml
    void initialize(){
        assert(glGenVertexArrays !is null, "glGenVertexArrays not available.");
        glGenVertexArrays(1, &this.array);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glDeleteVertexArrays.xhtml
    void free(){
        glDeleteVertexArrays(1, &this.array);
        this.array = 0;
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glIsVertexArray.xhtml
    bool opCast(To: bool)() const{
        return cast(bool) glIsVertexArray(this.array);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBindVertexArray.xhtml
    void bind() const{
        assert(this.array != 0);
        glBindVertexArray(this.array);
    }
    
    /// Enable the currently bound vertex array object.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glEnableVertexAttribArray.xhtml
    static void enable(T)(in T index) if(isNumeric!T){
        glEnableVertexAttribArray(cast(GLuint) index);
        GLException.enforce("Failed to enable vertex array object.");
    }
    /// Disable the currently bound vertex array object.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glEnableVertexAttribArray.xhtml
    static void disable(T)(in T index) if(isNumeric!T){
        glDisableVertexAttribArray(cast(GLuint) index);
        GLException.enforce("Failed to disable vertex array object.");
    }
    
    /// Enable this vertex array object. OpenGL 4.5+ only.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glEnableVertexAttribArray.xhtml
    void enablethis(T)(in T index) const if(isNumeric!T){
        assert(this.array != 0);
        assert(glEnableVertexArrayAttrib !is null, "glEnableVertexArrayAttrib not available.");
        glEnableVertexArrayAttrib(this.array, cast(GLuint) index);
    }
    /// Disable this vertex array object. OpenGL 4.5+ only.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glEnableVertexAttribArray.xhtml
    void disablethis(T)(in T index) const if(isNumeric!T){
        assert(this.array != 0);
        assert(glDisableVertexArrayAttrib !is null, "glDisableVertexArrayAttrib not available.");
        glDisableVertexArrayAttrib(this.array, cast(GLuint) index);
    }
}



/// https://www.khronos.org/opengl/wiki/Buffer_Object#Data_Specification
struct GLBuffer{
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBindBuffer.xhtml
    static enum Target: GLuint{
        Array = GL_ARRAY_BUFFER, /// Vertex attributes
        AtomicCounter = GL_ATOMIC_COUNTER_BUFFER, /// Atomic counter storage
        CopyRead = GL_COPY_READ_BUFFER, /// Buffer copy source
        CopyWrite = GL_COPY_WRITE_BUFFER, /// Buffer copy destination
        DispatchIndirect = GL_DISPATCH_INDIRECT_BUFFER, /// Indirect compute dispatch commands
        DrawIndirect = GL_DRAW_INDIRECT_BUFFER, /// Indirect command arguments
        ElementArray = GL_ELEMENT_ARRAY_BUFFER, /// Vertex array indexes
        PixelPack = GL_PIXEL_PACK_BUFFER, /// Pixel read target
        PixelUnpack = GL_PIXEL_UNPACK_BUFFER, /// Texture data source
        Query = GL_QUERY_BUFFER, /// Query result buffer
        ShaderStorage = GL_SHADER_STORAGE_BUFFER, /// Read-write storage for shaders
        Texture = GL_TEXTURE_BUFFER, /// Texture data buffer
        TransformFeedback = GL_TRANSFORM_FEEDBACK_BUFFER, /// Transform feedback buffer
        Uniform = GL_UNIFORM_BUFFER, /// Uniform block storage
    }
    /// https://www.khronos.org/opengl/wiki/Buffer_Object#Buffer_Object_Usage
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBufferData.xhtml
    /// Draw: The user will write data to the buffer, but not read it.
    /// Read: The user will read data from the buffer, but not write it.
    /// Copy: The user will not read nor write data. (Only OpenGL will internally.)
    /// Static: The buffer will be written to only once (or very infrequently),
    /// whether directly or by OpenGL.
    /// Dynamic: The buffer will be written to occassionally.
    /// Stream: The buffer will be updated frequently.
    static enum Usage: GLuint{
        StreamDraw = GL_STREAM_DRAW,
        StreamRead = GL_STREAM_READ,
        StreamCopy = GL_STREAM_COPY,
        StaticDraw = GL_STATIC_DRAW,
        StaticRead = GL_STATIC_READ,
        StaticCopy = GL_STATIC_COPY,
        DynamicDraw = GL_DYNAMIC_DRAW,
        DynamicRead = GL_DYNAMIC_READ,
        DynamicCopy = GL_DYNAMIC_COPY,
    }
    /// https://www.khronos.org/opengl/wiki/GLAPI/glBufferStorage
    alias StorageFlags = GLuint;
    static enum StorageFlag: StorageFlags{
        Dynamic = GL_DYNAMIC_STORAGE_BIT,
        MapRead = GL_MAP_READ_BIT,
        MapWrite = GL_MAP_WRITE_BIT,
        MapPersistent = GL_MAP_PERSISTENT_BIT,
        MapCoherent = GL_MAP_COHERENT_BIT,
        Client = GL_CLIENT_STORAGE_BIT,
    }
    
    GLuint buffer;
    
    this(in GLuint buffer){
        this.buffer = buffer;
    }
    /// Generate a buffer and bind it to a given target.
    this(in Target target){
        this.initialize();
        this.bind(target);
    }
    
    void initialize(){
        glGenBuffers(1, &this.buffer);
        if(this.buffer == 0) throw new GLException("Failed to create vertex buffer.");
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glDeleteBuffers.xhtml
    void free(){
        glDeleteBuffers(1, &this.buffer);
        this.buffer = 0;
    }
    
    /// True when the object refers to an existing, bound buffer.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glIsBuffer.xhtml
    bool opCast(To: bool)() const{
        return cast(bool) glIsBuffer(this.buffer);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBindBuffer.xhtml
    void bind(in Target target){
        assert(this.buffer != 0);
        glBindBuffer(target, this.buffer);
        GLException.enforce("Failed to bind buffer.");
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBindBuffer.xhtml
    static void unbind(in Target target){
        glBindBuffer(target, 0);
    }
    
    /// https://www.khronos.org/opengl/wiki/GLAPI/glBufferStorage
    static void storeimmutable(T)(in Target target, in StorageFlags flags, in T[] data){
        glBufferStorage(
            target, cast(GLsizeiptr)(data.length * T.sizeof),
            cast(void*) data.ptr, flags
        );
        GLException.enforce("Failed to store data in buffer.");
    }
    
    /// https://www.khronos.org/opengl/wiki/GLAPI/glBufferData
    static void storemutable(T)(in Target target, in Usage usage, in T[] data){
        glBufferData(
            target, cast(GLsizeiptr)(data.length * T.sizeof),
            cast(void*) data.ptr, usage
        );
        GLException.enforce("Failed to store data in buffer.");
    }
    
    /// Specify location and data format of an array of attributes at an index
    /// given a data type such as a number or a vector.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glVertexAttribPointer.xhtml
    @trusted static void vertexattr(T, X)(
        in X index, in size_t stride = 0, in size_t offset = 0
    ) if(isNumeric!X){
        assert(glVertexAttribPointer !is null);
        static if(isNumeric!T){
            glVertexAttribPointer(
                cast(GLuint) index, 1, GLTypeEnum!T, true,
                cast(GLsizei) stride, cast(void*) offset
            );
        }else static if(isVector!T){
            static assert(T.size >= 1 && T.size < 4, "Illegal vector size.");
            glVertexAttribPointer(
                cast(GLuint) index, cast(GLint) T.size, GLTypeEnum!(T.Value), true,
                cast(GLsizei) stride, cast(void*) offset
            );
        }
    }
    
    /// Bind this buffer, store some mutable data in it, indicate the
    /// vertex attribute information at an index.
    void setdata(T, X)(in X index, in Target target, in Usage usage, in T[] data) if(isNumeric!X){
        this.bind(target);
        this.storemutable(target, usage, data);
        this.vertexattr!T(index);
        GLException.enforce("Failed to set buffer data.");
    }
}
