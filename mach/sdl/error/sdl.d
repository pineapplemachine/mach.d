module mach.sdl.error.sdl;

private:

import derelict.sdl2.sdl : SDL_GetError, SDL_ClearError;

import mach.text.cstring : fromcstring;

public:



/// Class for exceptions which occur interfacing with SDL.
class SDLException: Exception{
    string error = null;
    
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this("Encountered SDL error.", next, line, file);
    }
    
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        auto sdlerror = this.errortext;
        if(sdlerror !is null){
            this(sdlerror, message, next, line, file);
        }else{
            super(message, file, line, next);
        }
    }
    
    this(string sdlerror, string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message ~ " " ~ sdlerror, file, line, next);
        this.error = sdlerror;
    }
    
    static @property string errortext(){
        // Only attempt SDL_GetError if core bindings were successfully loaded
        if(SDL_GetError !is null){
            auto error = SDL_GetError();
            if(error !is null && error[0] != '\0'){
                return error.fromcstring;
            }
        }
        return null;
    }
    
    static void clearerror(){
        // Only attempt SDL_ClearError if core bindings were successfully loaded
        if(SDL_ClearError !is null){
            SDL_ClearError();
        }
    }
}
