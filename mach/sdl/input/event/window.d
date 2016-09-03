module mach.sdl.input.event.window;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;

public:



/// Event related to a window state change.
/// https://wiki.libsdl.org/SDL_WindowEvent
struct WindowEvent{
    mixin EventMixin!SDL_WindowEvent;
    mixin WindowEventMixin;
    /// The various types of window events.
    enum Type: ubyte{
        None = SDL_WINDOWEVENT_NONE,
        Shown = SDL_WINDOWEVENT_SHOWN,
        Hidden = SDL_WINDOWEVENT_HIDDEN,
        Exposed = SDL_WINDOWEVENT_EXPOSED,
        Moved = SDL_WINDOWEVENT_MOVED,
        Resized = SDL_WINDOWEVENT_RESIZED,
        SizeChanged = SDL_WINDOWEVENT_SIZE_CHANGED,
        Minimized = SDL_WINDOWEVENT_MINIMIZED,
        Maximized = SDL_WINDOWEVENT_MAXIMIZED,
        Restored = SDL_WINDOWEVENT_RESTORED,
        Enter = SDL_WINDOWEVENT_ENTER, MouseEntered = Enter,
        Leave = SDL_WINDOWEVENT_LEAVE, MouseLeft = Leave,
        FocusGained = SDL_WINDOWEVENT_FOCUS_GAINED,
        FocusLost = SDL_WINDOWEVENT_FOCUS_LOST,
        Close = SDL_WINDOWEVENT_CLOSE, Closed = Close,
    }
    /// Get the type of the window event.
    @property Type type() const{
        return cast(Type) this.eventdata.event;
    }
    /// Set the type of the window event.
    @property void type(Type type){
        this.eventdata.event = type;
    }
    /// Get x for events having position data, width for event having size data.
    @property int data1() const{
        return this.eventdata.data1;
    }
    /// Set x for events having position data, width for event having size data.
    @property void data1(int data){
        this.eventdata.data1 = data;
    }
    /// Get y for events having position data, height for events having size data.
    @property int data2() const{
        return this.eventdata.data2;
    }
    /// Set y for events having position data, height for events having size data.
    @property void data2(int data){
        this.eventdata.data2 = data;
    }
    alias x = data1;
    alias y = data2;
    alias width = data1;
    alias height = data2;
}
