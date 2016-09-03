module mach.sdl.input.event.user;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;

public:



/// User-defined event.
/// https://wiki.libsdl.org/SDL_UserEvent
struct UserEvent{
    mixin EventMixin!SDL_UserEvent;
    mixin WindowEventMixin;
    alias Code = int;
    @property Code code() const{
        return this.eventdata.code;
    }
    @property void code(Code code){
        this.eventdata.code = code;
    }
    @property void* data1() const{
        return this.eventdata.data1;
    }
    @property void data1(void* data){
        this.eventdata.data1 = data;
    }
    @property void* data2() const{
        return this.eventdata.data2;
    }
    @property void data2(void* data){
        this.eventdata.data2 = data;
    }
}
