module mach.sdl.error.sdl;

private:

import derelict.sdl2.sdl : SDL_GetError, SDL_ClearError;

import std.string : fromStringz;
import mach.error : ThrowableCtorMixin;

public:



/// Class for errors which occur interfacing with SDL.
class SDLError: Exception{
    string error = null;
    mixin(ThrowableCtorMixin!("Encountered SDL error."));
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this.error = cast(string) fromStringz(SDL_GetError());
        if(this.error.length > 0){
            super(message ~ " " ~ this.error, file, line, next);
            SDL_ClearError();
        }else{
            super(message, file, line, next);
        }
    }
}
