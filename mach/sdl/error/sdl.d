module mach.sdl.error.sdl;

private:

import derelict.sdl2.sdl : SDL_GetError, SDL_ClearError;

import std.string : fromStringz;

public:



/// Class for exceptions which occur interfacing with SDL.
class SDLError: Exception{
    string error = null;
    
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this("Encountered SDL error.", next, line, file);
    }
    
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        if(SDL_GetError !is null){
            // Only attempt SDL_GetError if core bindings have been successfully loaded
            this.error = cast(string) fromStringz(SDL_GetError());
            if(this.error !is null && this.error.length > 0){
                super(message ~ " " ~ this.error, file, line, next);
                SDL_ClearError();
            }else{
                super(message, file, line, next);
            }
        }else{
            super(message, file, line, next);
        }
    }
}
