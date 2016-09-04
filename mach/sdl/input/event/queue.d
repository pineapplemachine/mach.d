module mach.sdl.input.event.queue;

private:

import derelict.sdl2.sdl;
import mach.sdl.input.event.type;
import mach.sdl.input.event.event;

public:



/// Provides methods for interacting with the event queue.
interface EventQueue{
    /// https://wiki.libsdl.org/SDL_SetEventFilter
    alias Filter = SDL_EventFilter;
    /// https://wiki.libsdl.org/SDL_AddEventWatch
    alias Watch = SDL_EventFilter;
    
    /// Return true if there are no events in the queue, false otherwise.
    static bool empty(){
        return SDL_PollEvent(null) != 1;
    }
    
    /// Populate the event queue and update input device state information.
    /// https://wiki.libsdl.org/SDL_PumpEvents
    static void pump(){
        SDL_PumpEvents();
    }
    
    /// Get whether any events of the given type are present in the queue.
    static bool contains(EventType type){
        return cast(bool) SDL_HasEvent(type);
    }
    /// Determine whether a quit event is present in the queue.
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
    /// Remove and return the foremost event from the queue. If the queue is
    /// empty, then the `exists` property of the returned object will be false.
    static typeof(this) pop(){
        SDL_Event* event = typeof(this).allocevent();
        auto result = SDL_PollEvent(event);
        return typeof(this)(event);
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
    
    /// Return a range for iterating over pending events.
    static auto events(){
        return EventQueueRange();
    }
    /// ditto
    alias asrange = events;
    
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
