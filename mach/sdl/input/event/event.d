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
    /// https://wiki.libsdl.org/SDL_SetEventFilter
    alias Filter = SDL_EventFilter;
    /// https://wiki.libsdl.org/SDL_AddEventWatch
    alias Watch = SDL_EventFilter;
    
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
    
    private template CommonPropertyMixin(string attrname, T, Only...){
        import std.meta : staticIndexOf;
        import mach.traits : hasProperty;
        @property auto CommonPropertyMixin() const{
            template prop(string typestruct, string typeenum, string eventname){
                enum prop = `
                    static if(
                        hasProperty!(` ~ typestruct ~ `, name) && (
                            Only.length == 0 ||
                            staticIndexOf!(` ~ typestruct ~ `, Only) >= 0
                        )
                    ){
                        if(this.type is ` ~ typeenum ~`){
                            return cast(T) this.` ~ eventname ~ `.` ~ attrname ~ `;
                        }
                        pragma(msg, typestruct ~ " has property " ~ attrname);
                    }
                `;
            }
            mixin prop!(`WindowEvent`, `Window`, `win`);
            mixin prop!(`KeyboardEvent`, `Keyboard`, `key`);
            mixin prop!(`TextEditingEvent`, `TextEditing`, `textedit`);
            mixin prop!(`TextInputEvent`, `TextInput`, `textinput`);
            mixin prop!(`MouseMotionEvent`, `MouseMotion`, `mousemotion`);
            mixin prop!(`MouseButtonEvent`, `MouseButton`, `mousebutton`);
            mixin prop!(`MouseWheelEvent`, `MouseWheel`, `mousewheel`);
            mixin prop!(`JoyAxisEvent`, `JoyAxis`, `joyaxis`);
            mixin prop!(`JoyButtonEvent`, `JoyButton`, `joybutton`);
            mixin prop!(`JoyHatEvent`, `JoyHat`, `joyhat`);
            mixin prop!(`JoyBallEvent`, `JoyBall`, `joyball`);
            mixin prop!(`JoyDeviceEvent`, `JoyDevice`, `joydevice`);
            mixin prop!(`ControllerAxisEvent`, `ControllerAxis`, `ctrlaxis`);
            mixin prop!(`ControllerButtonEvent`, `ControllerButton`, `ctrlbutton`);
            mixin prop!(`ControllerDeviceEvent`, `ControllerDevice`, `ctrldevice`);
            mixin prop!(`AudioDeviceEvent`, `AudioDevice`, `audiodevice`);
            mixin prop!(`QuitEvent`, `Quit`, `quit`);
            mixin prop!(`UserEvent`, `User`, `user`);
            mixin prop!(`SysWindowManagerEvent`, `SysWindowManager`, `syswm`);
            mixin prop!(`TouchFingerEvent`, `TouchFinger`, `touchfinger`);
            mixin prop!(`MultiGestureEvent`, `MultiGesture`, `multigesture`);
            mixin prop!(`DollarGestureEvent`, `DollarGesture`, `dollargesture`);
            mixin prop!(`DropFileEvent`, `DropFile`, `dropfile`);
            assert(false, "No such property for this event type.");
        }
    }
    
    alias mousex = CommonPropertyMixin!(`x`, int, MouseMotionEvent, MouseButtonEvent);
    alias mousey = CommonPropertyMixin!(`y`, int, MouseMotionEvent, MouseButtonEvent);
    alias touchx = CommonPropertyMixin!(`x`, float, TouchFingerEvent, MultiGestureEvent, DollarGestureEvent);
    alias touchy = CommonPropertyMixin!(`y`, float, TouchFingerEvent, MultiGestureEvent, DollarGestureEvent);
    alias windowid = CommonPropertyMixin!(`windowid`, Window.ID);
    alias joystickid = CommonPropertyMixin!(`joystickid`, Joystick.ID);
    alias touchid = CommonPropertyMixin!(`touchid`, TouchFingerEvent.TouchID);
    
    //@property Window window(){
    //    return Window.byid(this.windowid);
    //}
    //@property Joystick joystick(){
    //    return Joystick.byid(this.joystickid);
    //}
    //@property Controller controller(){
    //    return Controller.byid(this.joystickid);
    //}
    
    /// Allocate an SDL_Event.
    static SDL_Event* allocevent(Allocator = GCAllocator)(){
        return Allocator.instance.make!SDL_Event;
    }
    
    /// Populate the event queue and update input device state information.
    /// https://wiki.libsdl.org/SDL_PumpEvents
    static void pump(){
        SDL_PumpEvents();
    }
    /// Wait indefinitely for an event to be added to the queue.
    /// https://wiki.libsdl.org/SDL_WaitEvent
    static void wait(){
        auto result = SDL_WaitEvent(null);
        if(result == 0) throw new SDLError("Error while waiting for events.");
    }
    /// Wait for an event to be added to the queue for the given number of
    /// milliseconds. Returns true if the wait was terminated because an event
    /// was added to the queue, false otherwise.
    /// https://wiki.libsdl.org/SDL_WaitEventTimeout
    static bool wait(int timeout){
        return SDL_WaitEventTimeout(null, timeout) == 1;
    }
    /// Return true if there are no events in the queue, false otherwise.
    static bool empty(){
        return SDL_PollEvent(null) != 1;
    }
    /// Remove and return the foremost event from the queue. If the queue is
    /// empty, then the `exists` property of the returned object will be false.
    static typeof(this) pop(){
        SDL_Event* event = typeof(this).allocevent();
        auto result = SDL_PollEvent(event);
        return typeof(this)(event);
    }
    /// Return a range for iterating over pending events.
    static auto queue(){
        return EventQueueRange();
    }
    /// Determine whether a Quit event is present in the queue.
    /// https://wiki.libsdl.org/SDL_QuitRequested
    static bool quitrequested(){
        return cast(bool) SDL_QuitRequested();
    }
    /// Remove all events of the given type from the queue.
    /// https://wiki.libsdl.org/SDL_FlushEvent
    static void flush(Type type){
        SDL_FlushEvent(type);
    }
    /// Add an event to the queue. Return false if the event was filtered, true
    /// otherwise.
    /// https://wiki.libsdl.org/SDL_PushEvent
    bool push(){
        auto result = SDL_PushEvent(this.event);
        if(result < 0) throw new SDLError("Failed to add event to queue.");
        return result == 1;
    }
    
    /// Get whether events of a given type are enabled.
    static bool enabled(Type type){
        return cast(bool) SDL_EventState(type, EventState.Query);
    }
    /// Get whether events of a given type are disabled.
    static bool disabled(Type type){
        return !typeof(this).enabled(type);
    }
    /// ditto
    alias ignored = disabled;
    /// Enable events of a given type.
    static void enable(Type type){
        SDL_EventState(type, EventState.Enable);
    }
    /// Disable events of a given type.
    static void disable(Type type){
        SDL_EventState(type, EventState.Disable);
    }
    /// ditto
    alias ignore = disable;
    
    /// Set an event filter.
    /// https://wiki.libsdl.org/SDL_SetEventFilter
    static void setfilter(Filter filter, void* data){
        SDL_SetEventFilter(filter, data);
    }
    /// Type returned by getfilter method.
    struct GetFilterResult{
        bool exists = void; Filter filter = void; void* data = void;
    }
    /// Query the current event filter.
    /// https://wiki.libsdl.org/SDL_GetEventFilter
    static auto getfilter(){
        GetFilterResult get;
        auto result = SDL_GetEventFilter(&get.filter, &get.data);
        get.exists = cast(bool) result;
        return get;
    }
    /// Add an event watch.
    /// https://wiki.libsdl.org/SDL_AddEventWatch
    static void addwatch(Watch watch, void* data){
        SDL_AddEventWatch(watch, data);
    }
    /// Remove an event watch.
    /// https://wiki.libsdl.org/SDL_DelEventWatch
    static void removewatch(Watch watch, void* data){
        SDL_DelEventWatch(watch, data);
    }
    
    /// Register a new user event type. Returns the code of the registered event.
    static UserEvent.Code register(){
        return typeof(this).register(1);
    }
    /// Register multiple user event types. Returns the code of the first
    /// registered event.
    /// https://wiki.libsdl.org/SDL_RegisterEvents
    static UserEvent.Code register(int events){
        auto code = SDL_RegisterEvents(events);
        if(code == uint.max) throw new SDLError("Failed to register events.");
        return code;
    }
}

/// Range for iterating over and consuming the event queue.
/// https://wiki.libsdl.org/SDL_PollEvent
struct EventQueueRange{
    SDL_Event event;
    bool empty;
    @property auto front(){
        return Event(&this.event);
    }
    void popFront(){
        this.empty = SDL_PollEvent(&this.event) != 1;
    }
    static typeof(this) opCall(){
        EventQueueRange range;
        range.popFront();
        return range;
    }
}
