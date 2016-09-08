module mach.sdl.input.mouse.cursor;

private:

import derelict.sdl2.sdl;

import std.traits : isNumeric;
import mach.math : isVector2;
import mach.sdl.error : SDLError;
import mach.sdl.graphics.surface : Surface;

public:



/// https://wiki.libsdl.org/SDL_CreateCursor
struct MouseCursor{
    /// https://wiki.libsdl.org/SDL_CreateSystemCursor
    static enum System{
        /// Normal arrow cursor
        Arrow = SDL_SYSTEM_CURSOR_ARROW,
        /// Vertical beam cursor associated with text editing and selection
        IBeam = SDL_SYSTEM_CURSOR_IBEAM,
        ///
        Wait = SDL_SYSTEM_CURSOR_WAIT,
        ///
        Crosshair = SDL_SYSTEM_CURSOR_CROSSHAIR,
        /// Small wait cursor, or wait if not available
        WaitArrow = SDL_SYSTEM_CURSOR_WAITARROW,
        /// Double arrow pointing northwest and southeast
        SizeNWSE = SDL_SYSTEM_CURSOR_SIZENWSE,
        /// Double arrow pointing northeast and southwest
        SizeNESW = SDL_SYSTEM_CURSOR_SIZENESW,
        /// Double arrow pointing west and east
        SizeWE = SDL_SYSTEM_CURSOR_SIZEWE,
        /// Double arrow pointing north and south
        SizeNS = SDL_SYSTEM_CURSOR_SIZENS,
        /// Four-pointed arrow
        SizeAll = SDL_SYSTEM_CURSOR_SIZEALL,
        /// Slashed circle or crossbones
        No = SDL_SYSTEM_CURSOR_NO,
        /// Pointy hand associated with hover over clickable things
        Hand = SDL_SYSTEM_CURSOR_HAND,
    }
    
    SDL_Cursor* cursor;
    
    this(SDL_Cursor* cursor){
        this.cursor = cursor;
    }
    /// https://wiki.libsdl.org/SDL_CreateSystemCursor
    this(System system){
        this.cursor = SDL_CreateSystemCursor(system);
        if(this.cursor is null) throw new SDLError("Failed to create cursor.");
    }
    /// https://wiki.libsdl.org/SDL_CreateColorCursor
    this(SDL_Surface* surface, int x = 0, int y = 0){
        this.cursor = SDL_CreateColorCursor(surface, x, y);
        if(this.cursor is null) throw new SDLError("Failed to create cursor.");
    }
    this(T)(Surface surface, T vector) if(isVector2!T){
        this(surface, vector.x, vector.y);
    }
    this(T)(Surface surface, T x = 0, T y = 0) if(isNumeric!T){
        this(surface.surface, cast(int) x, cast(int) y);
    }
    
    /// https://wiki.libsdl.org/SDL_FreeCursor
    void free(){
        if(this.cursor !is null){
            SDL_FreeCursor(this.cursor);
            this.cursor = null;
        }
    }
    
    /// https://wiki.libsdl.org/SDL_GetDefaultCursor
    @property static typeof(this) defaultcursor(){
        auto cursor = SDL_GetDefaultCursor();
        if(cursor is null) throw new SDLError("Failed to get default cursor.");
        return typeof(this)(cursor);
    }
    /// https://wiki.libsdl.org/SDL_GetCursor
    @property static typeof(this) current(){
        auto cursor = SDL_GetCursor();
        if(cursor is null) throw new SDLError("Failed to get active cursor.");
        return typeof(this)(cursor);
    }
    
    @property bool isactive(){
        return this.cursor !is null && SDL_GetCursor() is this.cursor;
    }
    /// https://wiki.libsdl.org/SDL_SetCursor
    void activate(){
        SDL_SetCursor(this.cursor);
    }
    
    /// https://wiki.libsdl.org/SDL_SetCursor
    static void redraw(){
        SDL_SetCursor(null);
    }
}
