module mach.sdl.graphics.texture;

private:

import derelict.opengl3.gl;

import mach.traits : isNumeric;
import mach.math.vector : Vector, Vector2;
import mach.math.box : Box;
import mach.sdl.error : GLException;
import mach.sdl.glenum : TextureTarget, TextureParam;
import mach.sdl.glenum : PixelsType, PixelsFormat;
import mach.sdl.glenum : GLPrimitive, VertexType, getvertextype, validvertextype;
import mach.sdl.glenum : TextureWrap, TextureFilter;
import mach.sdl.glenum : TextureMinFilter, TextureMagFilter;
import mach.sdl.graphics.surface : Surface;
import mach.sdl.graphics.pixelformat : SDLPixelFormat = PixelFormat;
import mach.sdl.graphics.vertex : Vertex, Vertexes, Vertexesf;

public:



struct Texture{
    /// Enumeration of wrapping modes.
    alias Wrap = TextureWrap;
    /// Enumeration of filter modes available for both min and mag filters.
    alias Filter = TextureFilter;
    /// Enumeration of filter modes available when an image is scaled down.
    alias MinFilter = TextureMinFilter;
    /// Enumeration of filter modes available when an image is scaled up.
    alias MagFilter = TextureMagFilter;
    
    alias Name = GLuint;
    Name name;
    
    this(in Name name){
        this.name = name;
    }
    
    /// Load a texture from a path.
    this(in string path){
        auto surface = Surface(path);
        this(surface);
    }
    
    /// Create a texture from a surface.
    this(Surface surface){
        auto converted = surface.convert(SDLPixelFormat.Format.RGBA8888); // TODO: only convert when necessary
        this(converted.pixels, converted.width, converted.height, PixelsFormat.RGBA);
    }
    
    /// Create a texture given width, height, and raw pixel data.
    /// (You probably won't be calling this one directly.)
    this(
        in void* pixels, int width, int height,
        PixelsFormat format = PixelsFormat.RGBA
    ){
        assert(width > 0 && height > 0, "Invalid texture size.");
        glGenTextures(1, &this.name);
        this.bind();
        this.wrap(Wrap.Repeat);
        this.filter(Filter.Nearest);
        glTexImage2D(
            TextureTarget.Texture2D, 0, format,
            width, height, 0, format, GL_UNSIGNED_INT_8_8_8_8, pixels
        );
        GLException.enforce("Failed to create texture.");
    }
    
    /// Immediately free the texture data, if it hasn't already been freed.
    void free(){
        glDeleteTextures(1, &this.name);
        this.name = 0;
    }
    /// Free multiple textures at once.
    static void free(Texture[] textures...){
        glDeleteTextures(textures.length, cast(GLuint*) textures.ptr);
        foreach(texture; textures) texture.name = 0;
    }
    
    /// True when the object refers to an existing texture.
    /// https://www.khronos.org/registry/OpenGL-Refpages/es1.1/xhtml/glIsTexture.xml
    bool opCast(To: bool)() const{
        return cast(bool) glIsTexture(this.name);
    }
    
    /// Bind this texture; subsequent OpenGL calls will apply to this texture name.
    void bind() const nothrow{
        glBindTexture(TextureTarget.Texture2D, this.name);
    }
    /// Unbind this texture.
    void unbind() const nothrow{
        glBindTexture(TextureTarget.Texture2D, 0);
    }
    /// Get the currently bound texture.
    static auto bound(){
        GLint name; // Texture names are uints but glGetIntegerv expects a signed int
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &name);
        return Texture(cast(Name) name);
    }
    /// True if this texture's name is currently bound.
    @property bool isbound() const{
        return Texture.bound().name == this.name;
    }
    
    /// Get the width of the texture.
    @property auto width() const{
        this.bind();
        GLint width;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &width);
        return width;
    }
    /// Get the height of the texture.
    @property auto height() const{
        this.bind();
        GLint height;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &height);
        return height;
    }
    /// Get the size of the texture as a vector.
    @property Vector2!int size() const{
        return Vector2!int(this.width, this.height);
    }
    
    /// Set filter used when scaling the image.
    @property void filter(in Filter filter){
        this.bind();
        this.minfilter(cast(TextureMinFilter) filter);
        this.magfilter(cast(TextureMagFilter) filter);
    }
    /// Set filter used when scaling the image down.
    @property void minfilter(in MinFilter filter){
        this.bind();
        glTexParameteri(TextureTarget.Texture2D, TextureParam.MinFilter, filter);
    }
    /// Set filter used when scaling the image up.
    @property void magfilter(in MagFilter filter){
        this.bind();
        glTexParameteri(TextureTarget.Texture2D, TextureParam.MagFilter, filter);
    }
    
    /// Set how the texture wraps.
    @property void wrap(in Wrap wrap){
        this.bind();
        glTexParameteri(TextureTarget.Texture2D, TextureParam.WrapS, wrap);
        glTexParameteri(TextureTarget.Texture2D, TextureParam.WrapT, wrap);
    }
    
    void mipmap(){
        this.bind();
        // Doesn't work (Crashes because glGenerateMipmap isn't loaded)
        //glGenerateMipmapEXT(TextureTarget.Texture2D);
        // Not sure if this works or not honestly, but at least it doesn't crash
        glTexParameteri(TextureTarget.Texture2D, GL_GENERATE_MIPMAP, true);
    }
    
    //void update(){
    //    auto formatted = FormattedSurface.make!convert(surface);
    //    scope(exit) formatted.conclude();
    //    this.update(
    //        formatted.pixels, Box!int(offset, offset + formatted.size),
    //        formatted.format
    //    );
    //}
    void update(
        in void* pixels, Box!int box, PixelsFormat format = PixelsFormat.RGBA
    ){
        assert(pixels, "Invalid pixel data.");
        this.bind();
        glTexSubImage2D(
            TextureTarget.Texture2D, 0,
            box.x, box.y, box.width, box.height,
            format, PixelsType.Ubyte, pixels
        );
        GLException.enforce("Failed to update texture.");
    }
    
    /// Draw the texture at a position.
    void draw(N)(in N x, in N y) if(isNumeric!N){
        this.draw(Vector2!N(x, y));
    }
    /// ditto
    void draw(T)(in Vector!(2, T) position){
        this.draw(Vertexesf.rect(position, this.size));
    }
    /// Draw a portion of a texture at a position.
    /// The subrect represents floating-point texture coords from 0.0 to 1.0.
    void draw(X, Y)(in Vector!(2, X) position, in Box!Y sub){
        this.draw(Vertexesf.rect(position, sub.size * this.size, sub));
    }
    /// Draw the texture to a rectangular target.
    void draw(T)(in Box!T target){
        this.draw(Vertexesf.rect(target));
    }
    /// Draw a portion of the texture to a rectangular target.
    /// The subrect represents floating-point texture coords from 0.0 to 1.0.
    void draw(X, Y)(in Box!X target, in Box!Y sub){
        this.draw(Vertexesf.rect(target.topleft, target.size, sub));
    }
    void draw(A, B, C)(in Vertexes!(A, B, C) verts){
        this.bind();
        verts.setglpointers();
        glDrawArrays(GLPrimitive.TriangleStrip, 0, cast(uint) verts.length);
        GLException.enforce("Error drawing texture.");
    }
    
    /// Draw a portion of the texture to a position.
    /// The subrect represents integral pixel coordinates on the texture.
    void drawsub(X, Y)(in Vector!(2, X) position, in Box!Y sub){
        this.draw(position, Box!double(sub) / this.size);
    }
    /// Draw a portion of the texture to a rectangular target.
    /// The subrect represents integral pixel coordinates on the texture.
    void drawsub(X, Y)(in Box!X target, in Box!Y sub){
        this.draw(target, Box!double(sub) / this.size);
    }
}
