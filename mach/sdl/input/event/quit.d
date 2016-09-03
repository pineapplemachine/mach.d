module mach.sdl.input.event.quit;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;

public:



/// Event indicating that something has requested to shut down the application.
/// https://wiki.libsdl.org/SDL_QuitEvent
/// https://wiki.libsdl.org/SDL_EventType#SDL_QUIT
struct QuitEvent{
    mixin EventMixin!SDL_QuitEvent;
}
