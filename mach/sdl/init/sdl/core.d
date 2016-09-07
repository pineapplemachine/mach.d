module mach.sdl.init.sdl.core;

private:

import derelict.sdl2.sdl;
import mach.sdl.error : SDLError;
import mach.sdl.flags;

public:



struct Core{
    static load(){DerelictSDL2.load();}
    static unload(){DerelictSDL2.unload();}
    
    /// https://wiki.libsdl.org/SDL_Init
    static enum System: uint{
        None = 0,
        Timer = SDL_INIT_TIMER,
        Audio = SDL_INIT_AUDIO,
        Video = SDL_INIT_VIDEO,
        Joystick = SDL_INIT_JOYSTICK,
        Haptic = SDL_INIT_HAPTIC,
        Controller = SDL_INIT_GAMECONTROLLER,
        Events = SDL_INIT_EVENTS,
        All = SDL_INIT_EVERYTHING,
        Default = All,
    }
    
    /// Wraps a bitmask of system options with helpful methods.
    alias Systems = BitFlagAggregate!(uint, System);
    
    /// https://wiki.libsdl.org/SDL_Init
    /// https://wiki.libsdl.org/SDL_InitSubSystem
    static void initialize(Systems systems){
        if(SDL_Init(systems.flags) != 0){
            throw new SDLError("Failed to initialize core.");
        }
    }
    /// Get which systems have so far been successfully initialized.
    /// https://wiki.libsdl.org/SDL_WasInit
    static Systems initialized(){
        return Systems(SDL_WasInit(0));
    }
    /// https://wiki.libsdl.org/SDL_Quit
    static void quit(){
        SDL_Quit();
    }
    /// https://wiki.libsdl.org/SDL_QuitSubSystem
    static void quit(Systems systems){
        SDL_QuitSubSystem(systems.flags);
    }
}
