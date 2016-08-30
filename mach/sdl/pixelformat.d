module mach.sdl.pixelformat;

private:
    
import derelict.sdl2.sdl;
import mach.sdl.mask : Mask;
import mach.sdl.glenum : GLPixelsFormat = PixelsFormat;
import mach.sdl.error : GraphicsError;

public:

// Reference: https://wiki.libsdl.org/SDL_PixelFormat

struct PixelFormat{ // Corresponds to SDL_PixelFormat
    static enum Format{ // Corresponds to SDL_PixelFormatEnum
        Unknown = SDL_PIXELFORMAT_UNKNOWN,
        Index1LSB = SDL_PIXELFORMAT_INDEX1LSB,
        Index1MSB = SDL_PIXELFORMAT_INDEX1MSB,
        Index4LSB = SDL_PIXELFORMAT_INDEX4LSB,
        Index4MSB = SDL_PIXELFORMAT_INDEX4MSB,
        Index8 = SDL_PIXELFORMAT_INDEX8,
        RGB332 = SDL_PIXELFORMAT_RGB332,
        RGB444 = SDL_PIXELFORMAT_RGB444,
        RGB555 = SDL_PIXELFORMAT_RGB555,
        BGR555 = SDL_PIXELFORMAT_BGR555,
        ARGB4444 = SDL_PIXELFORMAT_ARGB4444,
        RGBA4444 = SDL_PIXELFORMAT_RGBA4444,
        ABGR4444 = SDL_PIXELFORMAT_ABGR4444,
        BGRA4444 = SDL_PIXELFORMAT_BGRA4444,
        ARGB1555 = SDL_PIXELFORMAT_ARGB1555,
        RGBA5551 = SDL_PIXELFORMAT_RGBA5551,
        ABGR1555 = SDL_PIXELFORMAT_ABGR1555,
        BGRA5551 = SDL_PIXELFORMAT_BGRA5551,
        RGB565 = SDL_PIXELFORMAT_RGB565,
        BGR565 = SDL_PIXELFORMAT_BGR565,
        RGB24 = SDL_PIXELFORMAT_RGB24,
        BGR24 = SDL_PIXELFORMAT_BGR24,
        RGB888 = SDL_PIXELFORMAT_RGB888,
        RGBX8888 = SDL_PIXELFORMAT_RGBX8888,
        BGR888 = SDL_PIXELFORMAT_BGR888,
        BGRX8888 = SDL_PIXELFORMAT_BGRX8888,
        ARGB8888 = SDL_PIXELFORMAT_ARGB8888,
        RGBA8888 = SDL_PIXELFORMAT_RGBA8888,
        ABGR8888 = SDL_PIXELFORMAT_ABGR8888,
        BGRA8888 = SDL_PIXELFORMAT_BGRA8888,
        ARGB2101010 = SDL_PIXELFORMAT_ARGB2101010,
        YV12 = SDL_PIXELFORMAT_YV12,
        IYUV = SDL_PIXELFORMAT_IYUV,
        YUY2 = SDL_PIXELFORMAT_YUY2,
        UYVY = SDL_PIXELFORMAT_UYVY,
        YVYU = SDL_PIXELFORMAT_YVYU,
    }
    
    const(SDL_PixelFormat*) pixelformat; // Read-only
    
    this(in SDL_Surface surface){
        this.pixelformat = surface.format;
    }
    this(in SDL_PixelFormat* pixelformat){
        this.pixelformat = pixelformat;
    }
    
    @property Format format() const{
        return cast(Format) this.pixelformat.format;
    }
    @property const(SDL_Palette*) palette() const{ // TODO: Also make a wrapper for SDL_Palette
        return this.pixelformat.palette;
    }
    @property ubyte bits() const{
        return this.pixelformat.BitsPerPixel;
    }
    @property ubyte bytes() const{
        return this.pixelformat.BytesPerPixel;
    }
    @property Mask mask() const{
        return Mask(this.pixelformat);
    }
        
    auto opCast(T: SDL_PixelFormat*)(){
        return this.pixelformat;
    }
    GLPixelsFormat opCast(T: GLPixelsFormat)() const{
        import std.conv : to;
        switch(this.format){
            case(Format.RGB888): return GLPixelsFormat.BGR; // ?
            case(Format.BGR888): return GLPixelsFormat.RGB; // ?
            //case(Format.RGBA8888): return GLPixelsFormat.RGBA;
            //case(Format.BGRA8888): return GLPixelsFormat.BGRA;
            case(Format.ABGR8888): return GLPixelsFormat.RGBA; // Works: Windows
            case(Format.RGBA8888): return GLPixelsFormat.RGBA; // OSX - RG swapped, BA swapped?
            case(Format.ARGB8888): return GLPixelsFormat.RGBA; // Works: OSX
            default:
                throw new GraphicsError(
                    "Unable to convert SDL pixel format " ~
                    to!string(this.format) ~" to OpenGL pixel format."
                );
        }
    }
    
    /// Good to go or a surface must be converted before it can become a texture?
    @property bool glcompatible(){
        return(
            (this.format == Format.ABGR8888) ||
            //(this.format == Format.RGBA8888) || // Bad?
            (this.format == Format.ARGB8888)
        );
    }
}
