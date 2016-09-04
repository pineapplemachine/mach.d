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

/// Timestamps measure the number of milliseconds since the SDL library
/// was initialized.
/// Timestamps of events represent when SDL_PumpEvents was last called and
/// not necessarily exactly when those events actually occurred.
/// References:
/// https://forums.libsdl.org/viewtopic.php?p=38148&sid=316e65d429d7668b40c879b105fa0b93
/// https://github.com/ioquake/ioq3/issues/215
alias Timestamp = uint;


