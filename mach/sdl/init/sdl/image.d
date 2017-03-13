module mach.sdl.init.sdl.image;

private:

import derelict.sdl2.image;
import mach.sdl.error : SDLException;
import mach.sdl.flags;

public:



/// https://www.libsdl.org/projects/SDL_image/
struct Image{
    static load(){DerelictSDL2Image.load();}
    static unload(){DerelictSDL2Image.unload();}
    
    /// https://www.libsdl.org/projects/SDL_image/docs/SDL_image_8.html
    static enum Format: int{
        None = 0,
        JPG = IMG_INIT_JPG,
        PNG = IMG_INIT_PNG,
        TIF = IMG_INIT_TIF,
        WEBP = IMG_INIT_WEBP,
        All = JPG | PNG | TIF | WEBP,
        Default = JPG | PNG,
    }
    
    /// Wraps a bitmask of image format options with helpful methods.
    alias Formats = BitFlagAggregate!(int, Format);
    
    /// https://www.libsdl.org/projects/SDL_image/docs/SDL_image_8.html
    static void initialize(Formats formats){
        int result = IMG_Init(formats.flags);
        if((result & formats.flags) != formats.flags){
            throw new SDLException("Failed to initialize image library.");
        }
    }
    /// Get which formats have so far been successfully initialized.
    static Formats initialized(){
        return Formats(IMG_Init(0));
    }
    /// https://www.libsdl.org/projects/SDL_image/docs/SDL_image_9.html
    static void quit(){
        IMG_Quit();
    }
}
