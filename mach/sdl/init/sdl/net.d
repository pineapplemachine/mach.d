module mach.sdl.init.sdl.net;

private:

import derelict.sdl2.net;
import mach.sdl.error : SDLException;

public:



/// https://www.libsdl.org/projects/SDL_net/
struct Net{
    static load(){DerelictSDL2Net.load();}
    static unload(){DerelictSDL2Net.unload();}
    
    static bool initialized = false;
    /// https://www.libsdl.org/projects/SDL_net/docs/SDL_net_8.html
    static void initialize(){
        scope(exit) initialized = true;
        if(SDLNet_Init() != 0) throw new SDLException("Failed to initialize network library.");
    }
    /// https://www.libsdl.org/projects/SDL_net/docs/SDL_net_9.html
    static void quit(){
        scope(exit) initialized = false;
        SDLNet_Quit();
    }
}
