module mach.sdl.graphics.displaymode;

private:

import derelict.sdl2.sdl;
import mach.sdl.error : SDLError;
import mach.math : Vector2, Box;

public:

static struct DisplayMode{
    version(BigEndian){
        static enum DEFAULT_FORMAT = SDL_PIXELFORMAT_RGBA8888;
    }else{
        static enum DEFAULT_FORMAT = SDL_PIXELFORMAT_ABGR8888;
    }
    
    int width;
    int height;
    int refreshrate;
    uint format;
    
    this(SDL_DisplayMode mode){
        this(mode.w, mode.h, mode.refresh_rate, mode.format);
    }
    this(in Box!int box, in int refreshrate = 0, in uint format = DEFAULT_FORMAT){
        this(box.width, box.height, refreshrate, format);
    }
    this(in Vector2!int size, in int refreshrate = 0, in uint format = DEFAULT_FORMAT){
        this(size.x, size.y, refreshrate, format);
    }
    this(in int width, in int height, in int refreshrate = 0, in uint format = DEFAULT_FORMAT){
        this.width = width;
        this.height = height;
        this.refreshrate = refreshrate;
        this.format = format;
    }
    
    @property Vector2!int size() const{
        return Vector2!int(this.width, this.height);
    }
    
    static DisplayMode desktop(in ubyte display = 0){
        SDL_DisplayMode mode;
        if(SDL_GetDesktopDisplayMode(display, &mode) != 0){
            throw new SDLError("Failed to retrieve desktop display mode.");
        }
        return DisplayMode(mode);
    }
    
    SDL_DisplayMode opCast(T: SDL_DisplayMode)() const{
        return SDL_DisplayMode(this.format, this.width, this.height, this.refreshrate);
    }
    
    string toString() const{
        import std.format : format;
        return "DisplayMode: Dimensions: (%d, %d), Refresh: %dhz, Format: %d".format(
            this.width, this.height, this.refreshrate, this.format
        );
    }
}

version(unittest){
    import mach.error.unit;
    import mach.sdl.init : initSDL;
}
unittest{
    // TODO: More better tests
    
    // Should throw an SDL not initialized error
    //fail((thrown) => (cast(SDLError) thrown !is null), {
    //    DisplayMode.desktop();
    //});
    
    // Should succeed
    //initSDL();
    //DisplayMode.desktop();
}
