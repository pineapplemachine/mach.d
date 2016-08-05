module mach.sdl.pixelformat;

private:
    
import derelict.sdl2.sdl;
import mach.sdl.mask : Mask;
import mach.sdl.glenum : GLPixelsFormat = PixelsFormat;
import mach.sdl.error : GraphicsError;

public:

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
    
    // TODO: Just wrap a pointer to SDL_PixelFormat instead of handling all this crap
    Format format;
    const SDL_Palette* palette;
    ubyte bits; // per pixel
    ubyte bytes; // per pixel
    Mask mask = Mask.Default;
    
    this(
        in Format format, in ubyte bits,
        in SDL_Palette* palette = null, in Mask mask = Mask.Default
    ){
        this.format = format;
        this.palette = palette;
        this.bits = bits;
        this.bytes = bits >> 3;
        this.mask = mask;
    }
    this(in SDL_PixelFormat sdlformat){
        this.format = cast(Format) sdlformat.format;
        this.palette = sdlformat.palette;
        this.bits = sdlformat.BitsPerPixel;
        this.bytes = sdlformat.BytesPerPixel;
        this.mask = Mask(sdlformat);
    }
    
    SDL_PixelFormat opCast(T: SDL_PixelFormat)(){
        return SDL_PixelFormat(
            this.format, cast(SDL_Palette*) this.palette, this.bits, this.bytes,
            [0, 0], this.mask.r, this.mask.g, this.mask.b, this.mask.a
        );
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
