module mach.sdl.input.common;

private:

import derelict.sdl2.sdl;

public:



enum EventState: int{
    Query = SDL_QUERY,
    Ignore = SDL_IGNORE, Disable = Ignore,
    Enable = SDL_ENABLE,
}

enum ButtonState{
    Released = SDL_RELEASED, // 0
    Pressed = SDL_PRESSED, // 1
}

