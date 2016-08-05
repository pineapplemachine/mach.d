module mach.sdl.surface;

private:

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import std.string : toStringz;

import mach.sdl.error : SDLError;
import mach.sdl.color : Color;
import mach.sdl.pixelformat : PixelFormat;
import mach.sdl.mask : Mask;
import mach.math.box : Box;
import mach.math.vector2 : Vector2;

public:

enum BlendMode : int {
    None = SDL_BLENDMODE_NONE,
    Alpha = SDL_BLENDMODE_BLEND,
    Additive = SDL_BLENDMODE_ADD,
    Modulate = SDL_BLENDMODE_MOD,
}

SDL_Rect toSDLrect(in Box!int box){
    return SDL_Rect(box.x, box.y, box.width, box.height);
}
Box!int toBox(in SDL_Rect rect){
    return Box!int(rect.x, rect.y, rect.x + rect.w, rect.y + rect.h);
}

/// Wraps an SDL_Surface, which stores image data in RAM.
struct Surface {
    
    /// The underlying SDL_Surface
    SDL_Surface* surface;
    
    static enum int DEFAULT_DEPTH = 32;
    static enum int DEFAULT_CREATION_FLAGS = 0;

    this(
        void* pixels, int width, int height,
        int depth = DEFAULT_DEPTH, Mask mask = Mask.Default, int pitch = -1
    ){
        this(SDL_CreateRGBSurfaceFrom(
            pixels, width, height, depth,
            pitch >= 0 ? pitch : (depth >> 3) * width,
            mask.r, mask.g, mask.b, mask.a
        ));
        this.enforcevalid();
    }
    this(
        void* pixels, int width, int height,
        ref PixelFormat format, int pitch = -1
    ){
        this(pixels, width, height, format.bits, format.mask, pitch);
    }
    this(
        void* pixels, int width, int height,
        ref SDL_PixelFormat format, int pitch = -1
    ){
        this(pixels, width, height, format.BitsPerPixel, Mask(format), pitch);
    }
    
    this(
        in int width, in int height,
        in int depth = DEFAULT_DEPTH, in Mask mask = Mask.Default,
        in uint flags = DEFAULT_CREATION_FLAGS,
    ){
        this(SDL_CreateRGBSurface(
            flags, width, height, depth,
            mask.r, mask.g, mask.b, mask.a
        ));
        this.enforcevalid();
    }
    this(
        in int width, in int height, in ref PixelFormat format,
        in uint flags = DEFAULT_CREATION_FLAGS
    ){
        this(width, height, format.bits, format.mask, flags);
    }
    this(
        in int width, in int height, in ref SDL_PixelFormat format,
        in uint flags = DEFAULT_CREATION_FLAGS
    ){
        this(width, height, format.BitsPerPixel, Mask(format), flags);
    }
    
    /// Load image from file path.
    this(in string path){
        SDL_Surface* image = IMG_Load(toStringz(path));
        if(image is null) throw new SDLError("Failed to load image at \"" ~ path ~ "\".");
        this(image);
    }
    this(SDL_Surface* surface){
        surface.refcount++;
        this.surface = surface;
        this.enforcevalid();
    }
    
    this(this){
        // https://dlang.org/spec/struct.html#struct-postblit
        if(this.surface) this.surface.refcount++;
    }
    
    ~this(){
        if(this.surface) this.free();
    }
    
    /// Determine whether this object is tied to an SDL_Surface and if that surface has any pixel data.
    @property bool valid() const{
        return this.surface && this.surface.pixels;
    }
    /// Throw an exception if this surface isn't valid.
    void enforcevalid(size_t line = __LINE__, string file = __FILE__) const{
        if(!this.surface){
            throw new SDLError("Invalid surface.", null, line, file);
        }
        if(!this.surface.pixels){
            throw new SDLError("Invalid pixel data for surface.", null, line, file);
        }
    }
    
    /// Free the underlying SDL_Surface
    void free(){
        if(!this.surface){
            throw new SDLError("Can't free invalid surface.");
        }
        SDL_FreeSurface(this.surface); // Respects reference counts
        this.surface = null;
    }
    
    /// Get the number of references to the underlying SDL_Surface
    @property int refcount(){
        return this.surface ? this.surface.refcount : 0;
    }
    /// Set the number of references to the underlying SDL_Surface
    @property void refcount(in int value){
        assert(this.surface);
        this.surface.refcount = value;
    }
    
    @property void RLEoptimized(bool enabled){
        if(SDL_SetSurfaceRLE(this.surface, enabled) != 0){
            throw new SDLError("Failed to set surface RLE optimization.");
        }
    }
    
    Surface convert(in Surface surface, in uint flags = 0){
        return this.convert(surface.pixelformat, flags);
    }
    Surface convert(PixelFormat format, uint flags = 0){
        return this.convert(cast(SDL_PixelFormat) format, flags);
    }
    Surface convert(in SDL_PixelFormat format, uint flags = 0){
        return this.convert(&format, flags);
    }
    /// Return another surface which is this surface in another format.
    Surface convert(in SDL_PixelFormat* format, uint flags = 0){
        SDL_Surface* result = SDL_ConvertSurface(this.surface, format, flags);
        if(!result) throw new SDLError("Failed to convert surface to new format.");
        return Surface(result);
    }
    
    /// Formats available for saving the surface as an image.
    static enum SaveFormat : int function(SDL_Surface* surface, const(char)* path){
        PNG = (surface, path) => (IMG_SavePNG(surface, path)),
        BMP = (surface, path) => (SDL_SaveBMP(surface, path))
    }
    /// Save the surface to an image file.
    void save(in string path, in SaveFormat format = SaveFormat.PNG){
        if(format(this.surface, toStringz(path)) != 0){
            throw new SDLError("Failed to save surface.");
        }
    }
    
    /// Get an SDL_Rect representing the bounds of this surface.
    @property SDL_Rect boundsrect(){
        Vector2!int size = this.size();
        return SDL_Rect(0, 0, size.x, size.y);
    }
    
    void fill(in uint color){
        SDL_Rect rect = this.boundsrect();
        this.fill(&rect, color);
    }
    void fill(T)(in Color!T color){
        SDL_Rect rect = this.boundsrect();
        this.fill(&rect, color.format(this.surface.format));
    }
    void fill(in ubyte r, in ubyte g, in ubyte b, in ubyte a = 255){
        SDL_Rect rect = this.boundsrect();
        this.fill(&rect, SDL_MapRGBA(this.surface.format, r, g, b, a));
    }
    void fill(in Box!int box, in uint color){
        SDL_Rect rect = box.toSDLrect();
        this.fill(&rect, color);
    }
    void fill(T)(in Box!int box, in Color!T color){
        SDL_Rect rect = box.toSDLrect();
        this.fill(&rect, color.format(this.surface.format));
    }
    void fill(in Box!int box, in ubyte r, in ubyte g, in ubyte b, in ubyte a = 255){
        SDL_Rect rect = box.toSDLrect();
        this.fill(&rect, SDL_MapRGBA(this.surface.format, r, g, b, a));
    }
    void fill(in SDL_Rect* rect, in uint color){
        if(SDL_FillRect(this.surface, rect, color) != 0){
            throw new SDLError("Failed to fill surface.");
        }
    }
    
    void lock(){
        if(SDL_LockSurface(this.surface) != 0){
            throw new SDLError("Failed to lock surface.");
        }
    }
    void unlock(){
        SDL_UnlockSurface(this.surface);
    }
    @property bool mustlock(){
        return this.surface && SDL_MUSTLOCK(this.surface) == SDL_TRUE;
    }
    @property bool locked(){
        return this.lockcount != 0;
    }
    @property int lockcount(){
        return this.surface ? this.surface.locked : 0;
    }
    
    @property void blend(in BlendMode mode){
        if(SDL_SetSurfaceBlendMode(this.surface, mode) != 0){
            throw new SDLError("Failed to set surface blend mode.");
        }
    }
    @property BlendMode blend(){
        SDL_BlendMode mode; // Secretly an int
        if(SDL_GetSurfaceBlendMode(this.surface, &mode) != 0){
            throw new SDLError("Failed to retrieve surface blend mode.");
        }
        return cast(BlendMode) mode;
    }
    
    SDL_Rect cliprect(){
        this.enforcevalid();
        SDL_Rect clip;
        SDL_GetClipRect(this.surface, &clip);
        return clip;
    }
    bool cliprect(in SDL_Rect clip){
        this.enforcevalid();
        return SDL_SetClipRect(this.surface, &clip) == SDL_TRUE;
    }
    bool cliprect(in Box!int clip){
        return this.cliprect(clip.toSDLrect());
    }
    @property Box!int clip(){
        return this.cliprect().toBox();
    }
    @property void clip(in Box!int clip){
        this.cliprect(clip);
    }
    
    static string SurfaceAttributeMixin(string type, string name, string attribute){
        import std.format : format;
        return `
            @property %s %s() const @trusted{
                if(!this.surface){
                    throw new SDLError("Can't retrieve %s of invalid surface.");
                }
                return this.surface.%s;
            }
        `.format(type, name, name, attribute);
    }
    
    mixin(SurfaceAttributeMixin("int", "width", "w"));
    mixin(SurfaceAttributeMixin("int", "height", "h"));
    mixin(SurfaceAttributeMixin("int", "pitch", "pitch"));
    mixin(SurfaceAttributeMixin("ubyte", "bits", "format.BitsPerPixel"));
    mixin(SurfaceAttributeMixin("ubyte", "bytes", "format.BytesPerPixel"));
    
    @property PixelFormat pixelformat() const{
        if(!this.surface) throw new SDLError("Can't retrieve format of invalid surface.");
        return PixelFormat(*this.surface.format);
    }
    @property Mask mask() const{
        if(!this.surface) throw new SDLError("Can't retrieve masks of invalid surface.");
        return Mask(
            this.surface.format.Rmask,
            this.surface.format.Gmask,
            this.surface.format.Bmask,
            this.surface.format.Amask
        );
    }
    @property Vector2!int size() const{
        if(!this.surface) throw new SDLError("Can't retrieve size of invalid surface.");
        return Vector2!int(this.surface.w, this.surface.h);
    }
    
    /// Blit pixel data from another surface onto this one.
    void blit(Surface source){
        immutable Box!int box = Box!int(source.size);
        this.blit(source, box, box);
    }
    void blit(Surface source, in Box!int from){
        this.blit(source, from, Box!int(from.size));
    }
    void blit(Surface source, in Box!int from, in Box!int to){
        this.enforcevalid(); source.enforcevalid();
        SDL_Rect fromrect = from.toSDLrect();
        SDL_Rect torect = to.toSDLrect();
        bool result = (from.size == to.size) ? (
            SDL_BlitSurface(source.surface, &fromrect, this.surface, &torect) != 0
        ) : (
            SDL_BlitScaled(source.surface, &fromrect, this.surface, &torect) != 0
        );
        if(result != 0) throw new SDLError("Failed to blit surface.");
    }
    
    /// Make a copy of this surface.
    Surface copy(){
        return this.sub(Box!int(this.size));
    }
    /// Get a rectangular portion of this surface as another surface.
    Surface sub(in Box!int box){
        this.enforcevalid();
        Surface sub = Surface(box.width, box.height, *this.surface.format);
        SDL_Rect rect = box.toSDLrect();
        if(SDL_BlitSurface(this.surface, &rect, sub.surface, null) != 0){
            throw new SDLError("Failed to blit surface.");
        }
        return sub;
    }
    
    // Thanks to http://sdl.beuc.net/sdl.wiki/Pixel_Access
    static uint getpixelatptr(in ubyte bytes, in void* ptr){
        if(bytes == 4){
            return *(cast(uint*) ptr);
        }else if(bytes == 1){
            return *(cast(ubyte*) ptr);
        }else if(bytes == 2){
            return *(cast(ushort*) ptr);
        }else if(bytes == 3){
            ubyte* bptr = cast(ubyte*) ptr;
            version(BigEndian){
                return (bptr[0] << 16) | (bptr[1] << 8) | bptr[2];
            }else{
                return (bptr[2] << 16) | (bptr[1] << 8) | bptr[0];
            }
        }else{
            assert(false);
        }
    }
    static void putpixelatptr(in ubyte bytes, in void* ptr, in uint pixel){
        if(bytes == 4){
            (cast(uint*) ptr)[0] = cast(uint) pixel;
        }else if(bytes == 1){
            (cast(ubyte*) ptr)[0] = cast(ubyte) pixel;
        }else if(bytes == 2){
            (cast(ushort*) ptr)[0] = cast(ushort) pixel;
        }else if(bytes == 3){
            ubyte* bptr = cast(ubyte*) ptr;
            version(BigEndian){
                bptr[0] = (pixel >> 16) & 0xff;
                bptr[1] = (pixel >> 8) & 0xff;
                bptr[2] = pixel & 0xff;
            }else{
                bptr[2] = (pixel >> 16) & 0xff;
                bptr[1] = (pixel >> 8) & 0xff;
                bptr[0] = pixel & 0xff;
            }
        }else{
            assert(false);
        }
    }
    
    /// Get a pointer to the pixel at some coordinate.
    const(void*) pixelptr(in int x, in int y) const pure nothrow{
        return(
            this.surface.pixels +
            y * this.surface.pitch +
            x * this.surface.format.BytesPerPixel
        );
    }
    uint getpixelvalue()(in int x, in int y) const{
        return this.getpixelatptr(this.surface.format.BytesPerPixel, this.pixelptr(x, y));
    }
    void putpixelvalue()(in int x, in int y, in uint value){
        this.putpixelatptr(this.surface.format.BytesPerPixel, this.pixelptr(x, y), value);
    }
    Color!T getpixel(T = ubyte)(in int x, in int y) const{
        return Color!T(this.getpixelvalue(x, y), this.surface.format);
    }
    void putpixel(T)(in int x, in int y, in Color!T color){
        this.putpixelvalue(x, y, color.format(this.surface.format));
    }
    
    Surface opIndex(T)(in Box!T box){
        return this.sub(cast(Box!int) box);
    }
    Color!ubyte opIndex(in int x, in int y){
        return this.getpixel!ubyte(x, y);
    }
    Color!ubyte opIndex(T)(in Vector2!T vector){
        return this.getpixel!ubyte(cast(int) vector.x, cast(int) vector.y);
    }
    
    void opIndexAssign(T)(in Color!T color, in int x, in int y){
        this.putpixel(x, y, color);
    }
    void opIndexAssign(T1, T2)(in Color!T1 color, in Vector2!T2 vector){
        this.putpixel(cast(int) vector.x, cast(int) vector.y, color);
    }
    void opIndexAssign(in uint value, in int x, in int y){
        this.putpixelvalue(x, y, value);
    }
    void opIndexAssign(T)(in uint value, in Vector2!T vector){
        this.putpixelvalue(cast(int) vector.x, cast(int) vector.y, value);
    }
    
    SDL_Surface* opCast(T: SDL_Surface*)() const{
        return this.surface;
    }
    
}

version(unittest) import mach.error.unit;
unittest{
    
    // TODO: More tests
    
    DerelictSDL2.load(); // Not necessary to fully initialize SDL for this test
    
    Surface surface = Surface(10, 10);
    surface.fill(Color!float(1, 0, 0));
    foreach(x; 0 .. surface.width){
        foreach(y; 0 .. surface.height){
            testeq(surface[x, y], Color!ubyte(255, 0, 0));
        }
    }
    surface[2, 2] = Color!float(0, 1, 1, 0.5);
    testeq(surface[2, 2], Color!ubyte(0, 255, 255, 128));
    
}
