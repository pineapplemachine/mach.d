module mach.sdl.input.event.event;

private:

import derelict.sdl2.sdl;

import std.experimental.allocator : make, dispose;
import std.experimental.allocator.gc_allocator : GCAllocator;

import mach.sdl.error : SDLError;
import mach.sdl.window : Window;
import mach.sdl.input.joystick : Joystick;
import mach.sdl.input.controller : Controller;
import mach.sdl.input.common;
import mach.sdl.input.event.type;
import mach.sdl.input.event.audio;
import mach.sdl.input.event.controller;
import mach.sdl.input.event.drop;
import mach.sdl.input.event.joystick;
import mach.sdl.input.event.keyboard;
import mach.sdl.input.event.mouse;
import mach.sdl.input.event.quit;
import mach.sdl.input.event.syswm;
import mach.sdl.input.event.text;
import mach.sdl.input.event.touch;
import mach.sdl.input.event.user;
import mach.sdl.input.event.window;

public:



struct Event{
    /// Timestamps measure the number of milliseconds since the SDL library
    /// was initialized.
    /// Timestamps of events represent when SDL_PumpEvents was last called and
    /// not necessarily exactly when those events actually occurred.
    /// References:
    /// https://forums.libsdl.org/viewtopic.php?p=38148&sid=316e65d429d7668b40c879b105fa0b93
    /// https://github.com/ioquake/ioq3/issues/215
    alias Timestamp = uint;
    /// https://wiki.libsdl.org/SDL_Event
    alias Type = EventType;
    
    /// Allocate an SDL_Event.
    static SDL_Event* allocevent(Allocator = GCAllocator)(){
        return Allocator.instance.make!SDL_Event;
    }
    
    SDL_Event* event;
    
    /// Determine whether there is any data currently associated with this
    /// event object.
    @property bool exists() const{
        return this.event !is null;
    }
    
    /// Get the type of the event.
    @property Type type() const{
        return cast(Type) this.event.type;
    }
    /// Set the type of the event.
    @property void type(Type type){
        this.event.type = type;
    }
    /// Get the timestamp for when this event was detected. Measured in
    /// millisecs since SDL initialization.
    @property Timestamp timestamp() const{
        return cast(Timestamp) this.event.common.timestamp;
    }
    /// Set the timestamp for when this event was detected. Measured in
    /// millisecs since SDL initialization.
    @property void timestamp(Timestamp timestamp){
        this.event.common.timestamp = timestamp;
    }
    
    /// Register user event types. Returns the code of the first registered
    /// event. If more than one event was registered, then the codes will be
    /// sequential beginning with the returned value.
    /// https://wiki.libsdl.org/SDL_RegisterEvents
    static UserEvent.Code register(int events = 1){
        auto code = SDL_RegisterEvents(events);
        if(code == uint.max) throw new SDLError("Failed to register events.");
        return code;
    }
    
    /// Some events possess resources which must be explicitly deallocated.
    /// Best practice would be to always call this when you're done with an
    /// event, but practically speaking it's only necessary for file drop
    /// events. (But that could change! Who knows?)
    void conclude(){
        if(this.type is Type.DropFile) this.dropfile.conclude();
    }
    
    @property auto win() const{return WindowEvent(cast(SDL_Event*) this.event);}
    @property auto key() const{return KeyboardEvent(cast(SDL_Event*) this.event);}
    @property auto textedit() const{return TextEditingEvent(cast(SDL_Event*) this.event);}
    @property auto textinput() const{return TextInputEvent(cast(SDL_Event*) this.event);}
    @property auto mousemotion() const{return MouseMotionEvent(cast(SDL_Event*) this.event);}
    @property auto mousebutton() const{return MouseButtonEvent(cast(SDL_Event*) this.event);}
    @property auto mousewheel() const{return MouseWheelEvent(cast(SDL_Event*) this.event);}
    @property auto joyaxis() const{return JoyAxisEvent(cast(SDL_Event*) this.event);}
    @property auto joybutton() const{return JoyButtonEvent(cast(SDL_Event*) this.event);}
    @property auto joyhat() const{return JoyHatEvent(cast(SDL_Event*) this.event);}
    @property auto joyball() const{return JoyBallEvent(cast(SDL_Event*) this.event);}
    @property auto joydevice() const{return JoyDeviceEvent(cast(SDL_Event*) this.event);}
    @property auto ctrlaxis() const{return ControllerAxisEvent(cast(SDL_Event*) this.event);}
    @property auto ctrlbutton() const{return ControllerButtonEvent(cast(SDL_Event*) this.event);}
    @property auto ctrldevice() const{return ControllerDeviceEvent(cast(SDL_Event*) this.event);}
    @property auto audiodevice() const{return AudioDeviceEvent(cast(SDL_Event*) this.event);}
    @property auto quit() const{return QuitEvent(cast(SDL_Event*) this.event);}
    @property auto user() const{return UserEvent(cast(SDL_Event*) this.event);}
    @property auto syswm() const{return SysWindowManagerEvent(cast(SDL_Event*) this.event);}
    @property auto touchfinger() const{return TouchFingerEvent(cast(SDL_Event*) this.event);}
    @property auto multigesture() const{return MultiGestureEvent(cast(SDL_Event*) this.event);}
    @property auto dollargesture() const{return DollarGestureEvent(cast(SDL_Event*) this.event);}
    @property auto dropfile() const{return DropFileEvent(cast(SDL_Event*) this.event);}
    
    @property int mousex() const{
        switch(this.type){
            case Type.MouseButtonUp:
            case Type.MouseButtonDown: return this.mousebutton.x;
            case Type.MouseMotion: return this.mousemotion.x;
            default: assert(false, "No such property for this event type.");
        }
    }
    @property int mousey() const{
        switch(this.type){
            case Type.MouseButtonUp:
            case Type.MouseButtonDown: return this.mousebutton.y;
            case Type.MouseMotion: return this.mousemotion.y;
            default: assert(false, "No such property for this event type.");
        }
    }
    
    @property float touchx() const{
        switch(this.type){
            case Type.FingerUp:
            case Type.FingerDown:
            case Type.FingerMotion: return this.touchfinger.x;
            case Type.MultiGesture: return this.multigesture.x;
            case Type.DollarGesture:
            case Type.DollarRecord: return this.dollargesture.x;
            default: assert(false, "No such property for this event type.");
        }
    }
    @property float touchy() const{
        switch(this.type){
            case Type.FingerUp:
            case Type.FingerDown:
            case Type.FingerMotion: return this.touchfinger.y;
            case Type.MultiGesture: return this.multigesture.y;
            case Type.DollarGesture:
            case Type.DollarRecord: return this.dollargesture.y;
            default: assert(false, "No such property for this event type.");
        }
    }
    @property auto touchid() const{
        switch(this.type){
            case Type.FingerUp:
            case Type.FingerDown:
            case Type.FingerMotion: return this.touchfinger.touchid;
            case Type.MultiGesture: return this.multigesture.touchid;
            case Type.DollarGesture:
            case Type.DollarRecord: return this.dollargesture.touchid;
            default: assert(false, "No such property for this event type.");
        }
    }
    
    @property Window window(){
        return Window.byid(this.windowid);
    }
    @property auto windowid() const{
        switch(this.type){
            case Type.Window: return this.win.windowid;
            case Type.KeyUp:
            case Type.KeyDown: return this.key.windowid;
            case Type.TextEditing: return this.textedit.windowid;
            case Type.TextInput: return this.textinput.windowid;
            case Type.MouseMotion: return this.mousemotion.windowid;
            case Type.MouseButtonUp:
            case Type.MouseButtonDown: return this.mousebutton.windowid;
            case Type.MouseWheel: return this.mousewheel.windowid;
            case Type.User: return this.user.windowid;
            default: assert(false, "No such property for this event type.");
        }
    }
    
    @property Joystick joystick(){
        return Joystick.byid(this.joystickid);
    }
    @property Controller controller(){
        return Controller.byid(this.joystickid);
    }
    @property auto joystickid() const{
        switch(this.type){
            case Type.JoyAxisMotion: return this.joyaxis.joystickid;
            case Type.JoyBallMotion: return this.joyball.joystickid;
            case Type.JoyHatMotion: return this.joyhat.joystickid;
            case Type.JoyButtonUp:
            case Type.JoyButtonDown: return this.joybutton.joystickid;
            case Type.ControllerAxisMotion: return this.ctrlaxis.joystickid;
            case Type.ControllerButtonUp:
            case Type.ControllerButtonDown: return this.ctrlbutton.joystickid;
            default: assert(false, "No such property for this event type.");
        }
    }
    @property auto axispos() const{
        switch(this.type){
            case Type.JoyAxisMotion: return this.joyaxis.position;
            case Type.ControllerAxisMotion: return this.ctrlaxis.position;
            default: assert(false, "No such property for this event type.");
        }
    }
}
