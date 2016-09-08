module mach.sdl.input.mouse.state;

private:

import derelict.sdl2.sdl;
import mach.math : Vector;
import mach.sdl.flags;
import mach.sdl.input.mouse.common;

public:




/// https://wiki.libsdl.org/SDL_GetMouseState
/// https://wiki.libsdl.org/SDL_MouseMotionEvent
struct MouseState{
    alias Button = MouseButton;
    alias Buttons = BitFlagAggregate!(ubyte, Button);
    
    /// The state of each mouse button
    Buttons buttons;
    /// The position of the mouse
    int x, y;
    
    /// Get the current mouse state in relation to the active window.
    /// https://wiki.libsdl.org/SDL_GetMouseState
    static typeof(this) current(){
        typeof(this) state;
        state.buttons = Buttons(cast(ubyte) SDL_GetMouseState(&state.x, &state.y));
        return state;
    }
    /// Get the current state of the mouse in relation to the desktop.
    /// https://wiki.libsdl.org/SDL_GetGlobalMouseState
    static typeof(this) desktop(){
        typeof(this) state;
        state.buttons = Buttons(cast(ubyte) SDL_GetGlobalMouseState(&state.x, &state.y));
        return state;
    }
    /// Get the mouse state relative to the last call or, if none has so far
    /// been made, relative to SDL initialization.
    /// https://wiki.libsdl.org/SDL_GetRelativeMouseState
    static typeof(this) relative(){
        typeof(this) state;
        state.buttons = Buttons(cast(ubyte) SDL_GetRelativeMouseState(&state.x, &state.y));
        return state;
    }
    
    /// Get mouse position as a vector.
    @property auto position() const{
        return Vector(this.x, this.y);
    }
    /// Set mouse position as a vector.
    @property void position(T)(T vector) if(isVector2!T){
        this.x = vector.x;
        this.y = vector.y;
    }
    
    private template ButtonPropertyMixin(Button mask){
        @property bool ButtonPropertyMixin() const{
            return mask in this.buttons;
        }
        @property void ButtonPropertyMixin(bool state){
            this.buttons[mask] = state;
        }
    }
    
    /// Get/set the state of the left mouse button.
    alias left = ButtonPropertyMixin!(Button.Left);
    /// Get/set the state of the right mouse button.
    alias right = ButtonPropertyMixin!(Button.Right);
    /// Get/set the state of the middle mouse button.
    alias middle = ButtonPropertyMixin!(Button.Middle);
    /// Get/set the state of the X1 mouse button.
    alias X1 = ButtonPropertyMixin!(Button.X1);
    /// Get/set the state of the X2 mouse button.
    alias X2 = ButtonPropertyMixin!(Button.X2);
}
