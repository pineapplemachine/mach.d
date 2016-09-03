module mach.sdl.input.event.syswm;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;

public:



/// https://wiki.libsdl.org/SDL_SysWindowManagerEvent
struct SysWindowManagerEvent{
    mixin EventMixin!SDL_SysWMEvent;
    @property SDL_SysWMmsg* message() const{
        return this.eventdata.msg;
    }
    @property void message(SDL_SysWMmsg* message){
        this.eventdata.msg = message;
    }
}
