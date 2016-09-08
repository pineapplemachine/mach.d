module mach.sdl.input.mouse.common;

private:

import derelict.sdl2.sdl;

public:



alias MouseID = uint;

enum TouchMouseID = SDL_TOUCH_MOUSEID;



/// An enumeration of recognized mouse buttons.
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
