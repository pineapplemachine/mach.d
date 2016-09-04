module mach.sdl.input.event.text;

private:

import derelict.sdl2.sdl;
import mach.sdl.input.event.mixins;

public:



/// https://wiki.libsdl.org/SDL_TextInputEvent
/// https://wiki.libsdl.org/Tutorials/TextInput
struct TextInputEvent{
    mixin EventMixin!SDL_TextInputEvent;
    mixin TextEventMixin;
    
    // TODO: Is this really the right place to put these methods?
    // Seems a little out of the way
    
    /// Get whether text input events are currently enabled.
    /// https://wiki.libsdl.org/SDL_IsTextInputActive
    static bool enabled(){
        return cast(bool) SDL_IsTextInputActive();
    }
    /// Start receiving text input events.
    /// https://wiki.libsdl.org/SDL_StartTextInput
    static void start(){
        SDL_StartTextInput();
    }
    /// Stop receiving text input events.
    /// https://wiki.libsdl.org/SDL_StopTextInput
    static void stop(){
        SDL_StopTextInput();
    }
    /// Controls where the candidate list will open, if supported.
    /// https://wiki.libsdl.org/SDL_SetTextInputRect
    static @property void inputrect(int x, int y, int w, int h){
        auto rect = SDL_Rect(x, y, w, h);
        SDL_SetTextInputRect(&rect);
    }
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
