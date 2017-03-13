module mach.sdl.init.sdl.ttf;

private:

import derelict.sdl2.ttf;
import mach.sdl.error : SDLException;

public:



/// https://www.libsdl.org/projects/SDL_ttf/
struct TTF{
    static load(){DerelictSDL2ttf.load();}
    static unload(){DerelictSDL2ttf.unload();}
    
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_8.html
    static void initialize(){
        if(TTF_Init() != 0) throw new SDLException("Failed to initialize TTF library.");
    }
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_9.html
    static bool initialized(){
        return cast(bool) TTF_WasInit();
    }
    /// https://www.libsdl.org/projects/SDL_ttf/docs/SDL_ttf_10.html
    static void quit(){
        TTF_Quit();
    }
}
