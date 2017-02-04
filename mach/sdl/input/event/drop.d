module mach.sdl.input.event.drop;

private:

import derelict.sdl2.types;
import derelict.sdl2.functions : SDL_free;
import mach.text.cstring : fromcstring;
import mach.sdl.input.event.mixins;

public:



/// https://wiki.libsdl.org/SDL_DropEvent
struct DropFileEvent{
    mixin EventMixin!SDL_DropEvent;
    /// The original SDL event's char* needs to be destroyed using SDL_free.
    /// If using drop events, make sure to call Event.conclude at some point
    /// (which goes on to call this method) in order to avoid memory leaks.
    void conclude(){
        SDL_free(this.eventdata.file);
    }
    /// Get the path to the file dropped.
    @property string path() const{
        return this.eventdata.file.fromcstring;
    }
    /// TODO: What's the best way to allocate and assign a file path?
}
