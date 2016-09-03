module mach.sdl.input.event.text;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;

public:



/// https://wiki.libsdl.org/SDL_TextInputEvent
/// https://wiki.libsdl.org/Tutorials/TextInput
struct TextInputEvent{
    mixin EventMixin!SDL_TextInputEvent;
    mixin TextEventMixin;
}

/// https://wiki.libsdl.org/SDL_TextEditingEvent
/// https://wiki.libsdl.org/Tutorials/TextInput
struct TextEditingEvent{
    mixin EventMixin!SDL_TextEditingEvent;
    mixin TextEventMixin;
    @property int start() const{
        return this.eventdata.start;
    }
    @property void start(int start){
        this.eventdata.start = start;
    }
    @property int length() const{
        return this.eventdata.length;
    }
    @property void length(int length){
        this.eventdata.length = length;
    }
}
