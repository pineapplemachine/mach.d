module mach.sdl.input.mouse.mouse;

private:

import derelict.sdl2.sdl;

import std.traits : isNumeric;
import mach.math : isVector2;
import mach.sdl.error : SDLError;
import mach.sdl.window : Window;
import mach.sdl.input.mouse.common;
import mach.sdl.input.mouse.cursor;
import mach.sdl.input.mouse.state;

public:



struct Mouse{
    alias ID = MouseID;
    alias TouchID = TouchMouseID;
    alias State = MouseState;
    alias Button = MouseState.Button;
    alias Buttons = MouseState.Buttons;
    alias WheelDirection = MouseWheelDirection;
    alias Cursor = MouseCursor;
    
    /// https://wiki.libsdl.org/SDL_WarpMouseGlobal
    static void warpglobal(T)(T x, T y) if(isNumeric!T){
        SDL_WarpMouseGlobal(cast(int) x, cast(int) y);
    }
    /// ditto
    static void warpglobal(T)(T vector) if(isVector2!T){
        typeof(this).warpglobal(vector.x, vector.y);
    }
    /// https://wiki.libsdl.org/SDL_WarpMouseInWindow
    static void warpwindow(T)(Window window, T x, T y) if(isNumeric!T){
        typeof(this).warpwindow(window.window, x, y);
    }
    /// ditto
    static void warpwindow(T)(Window window, T vector) if(isVector2!vector){
        typeof(this).warpwindow(window.window, vector.x, vector.y);
    }
    /// ditto
    static void warpwindow(T)(SDL_Window* window, T x, T y) if(isNumeric!T){
        SDL_WarpMouseInWindow(window, cast(int) x, cast(int) y);
    }
    
    /// Hide the cursor.
    void hide(){
        this.shown = false;
    }
    /// Show the cursor.
    void show(){
        this.shown = true;
    }
    /// https://wiki.libsdl.org/SDL_ShowCursor
    static @property bool shown(){
        auto result = SDL_ShowCursor(-1);
        if(result < 0) throw new SDLError("Failed to get mouse shown.");
        return cast(bool) result;
    }
    /// https://wiki.libsdl.org/SDL_ShowCursor
    static @property void shown(bool state){
        auto result = SDL_ShowCursor(cast(int) state);
        if(result < 0) throw new SDLError("Failed to set mouse shown.");
    }
}
