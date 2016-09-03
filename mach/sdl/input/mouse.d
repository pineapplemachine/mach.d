module mach.sdl.input.mouse;

private:

import derelict.sdl2.sdl;

public:



alias MouseID = uint;

enum TouchMouseID = SDL_TOUCH_MOUSEID;




/// https://wiki.libsdl.org/SDL_MouseButtonEvent
enum MouseButton: ubyte{
    Left = SDL_BUTTON_LEFT,
    Middle = SDL_BUTTON_MIDDLE,
    Right = SDL_BUTTON_RIGHT,
    X1 = SDL_BUTTON_X1,
    X2 = SDL_BUTTON_X2,
}

/// https://wiki.libsdl.org/SDL_MouseWheelEvent
enum MouseWheelDirection: SDL_MouseWheelDirection{
    Normal = SDL_MOUSEWHEEL_NORMAL,
    Flipped = SDL_MOUSEWHEEL_FLIPPED,
}



/// https://wiki.libsdl.org/SDL_GetMouseState
/// https://wiki.libsdl.org/SDL_MouseMotionEvent
struct MouseState{
    alias Buttons = ubyte;
    
    enum ButtonMask: Buttons{
        Left = SDL_BUTTON_LMASK,
        Right = SDL_BUTTON_RMASK,
        Middle = SDL_BUTTON_MMASK,
        X1 = SDL_BUTTON_X1MASK,
        X2 = SDL_BUTTON_X2MASK,
    }
    
    Buttons buttons;
    int x, y;
    
    /// Get the current mouse state.
    static MouseState current(){
        MouseState state;
        state.buttons = cast(Buttons) SDL_GetMouseState(&state.x, &state.y);
        return state;
    }
    /// Get the mouse state relative to the last call, or if none has so far
    /// been made, relative to SDL initialization.
    static MouseState relative(){
        MouseState state;
        state.buttons = cast(Buttons) SDL_GetRelativeMouseState(&state.x, &state.y);
        return state;
    }
    
    private template ButtonMaskPropertyMixin(ButtonMask mask){
        @property bool ButtonMaskPropertyMixin() const{
            return (this.buttons & mask) != 0;
        }
        @property void ButtonMaskPropertyMixin(bool active){
            if(active) this.buttons |= mask;
            else this.buttons &= ~mask;
        }
    }
    
    alias left = ButtonMaskPropertyMixin!(ButtonMask.Left);
    alias right = ButtonMaskPropertyMixin!(ButtonMask.Left);
    alias middle = ButtonMaskPropertyMixin!(ButtonMask.Left);
    alias X1 = ButtonMaskPropertyMixin!(ButtonMask.Left);
    alias X2 = ButtonMaskPropertyMixin!(ButtonMask.Left);
}
