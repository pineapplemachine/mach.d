module mach.sdl.input.helper.history;

private:

import mach.text : text;
import mach.sdl.input.common : Timestamp;

public:



/// Used by helper types to record when an event occurred.
struct EventTime{
    /// The timestamp associated with the event
    Timestamp timestamp = 0;
    /// Where two objects have an identical timestamp, their relative ordering
    /// in the queue can be determined by comparing this value.
    size_t order = 0;
    
    /// Compare two objects.
    int opCmp(in EventTime time) const{
        if(this.timestamp > time.timestamp) return 1;
        else if(this.timestamp < time.timestamp) return -1;
        else if(this.order > time.order) return 1;
        else if(this.order < time.order) return -1;
        else return 0;
    }
    Timestamp opBinary(string op)(in EventTime time) const{
        return this.opBinary!op(time.timestamp);
    }
    Timestamp opBinary(string op)(in Timestamp timestamp) const{
        mixin(`return this.timestamp ` ~ op ~ `timestamp;`);
    }
    string toString() const{
        return text(this.timestamp, 'T', this.order);
    }
}



/// Records a history of EventTime objects.
/// Accepts a max length determining the maximum number of events to keep a
/// history of.
struct EventHistory(size_t maxlength) if(maxlength > 0){
    EventTime[maxlength] times;
    size_t length = 0;
    
    this(EventTime time){
        this.add(time);
    }
    
    /// True when the object has no history data.
    @property bool empty(){
        return this.length == 0;
    }
    /// Clear all history data from the object.
    void clear(){
        this.length = 0;
    }
    /// Get the most recent EventTime, if any.
    auto recent() const in{
        assert(this.length > 0);
    }body{
        return this.times[0];
    }
    /// Add a new event. If the maximum history length is exceeded, the oldest
    /// event data is removed.
    void add(EventTime time) in{
        // Disallow adding times older than the most recent currently known.
        if(this.length) assert(time >= this.recent);
    }body{
        if(this.length){
            for(size_t i = 0; i < this.length - 1; i++){
                this.times[i + 1] = this.times[i];
            }
        }
        if(this.length < maxlength) this.length++;
        this.times[0] = time;
    }
    /// Get an EventTime. Zero index refers to most recent event, if any.
    auto opIndex(size_t index) const in{
        assert(index >= 0 && index < this.length, "Event history index out of bounds.");
    }body{
        return this.times[index];
    }
    /// Iterate over EventTime objects, starting with the most recent and ending
    /// with the oldest.
    int opApply(in int delegate(in ref EventTime) apply) const{
        for(size_t i = 0; i < this.length; i++){
            if(auto result = apply(this.times[i])) return result;
        }
        return 0;
    }
    string toString() const{
        auto str = text("History for ", this.length, " events");
        foreach(time; this) str ~= "\n" ~ time.toString();
        return str;
    }
}



enum ButtonHistoryState{
    Pressed, Released, Repeated
}
    
/// Provides an aggregation of EventHistory objects.
struct EventHistoryAggregation(Key, size_t historylength = 3, bool repeats = false){
    alias Time = EventTime;
    alias History = EventHistory!historylength;
    alias State = ButtonHistoryState;
    
    /// Default argument for methods expecting an interval between events,
    /// measured in milliseconds.
    /// On Windows, the default maximum double-click interval is 500ms.
    /// https://technet.microsoft.com/en-us/library/cc978662.aspx
    static enum Timestamp DefaultTapInterval = 500;
    
    Time time;
    History[Key] presshistory;
    History[Key] releasehistory;
    static if(repeats) History[Key] repeathistory;
    
    /// Returns a reference to the associative array used internally to track
    /// history for the given button state.
    auto statehistory(State state)() const{
        static if(state is State.Pressed) return &this.presshistory;
        else static if(state is State.Released) return &this.releasehistory;
        else static if(state is State.Repeated){
            static if(repeats) return &this.repeathistory;
            else static assert(false, "No history available for repeated state.");
        }
    }
    /// ditto
    auto statehistory()(in State state){
        final switch(state){
            case State.Pressed: return &this.presshistory;
            case State.Released: return &this.releasehistory;
            case State.Repeated:
                static if(repeats) return &this.repeathistory;
                else assert(false, "No history available for repeated state.");
        }
    }
    
    /// Record a new button event at the current time.
    void add(in Key key, in State state){
        auto historyarray = this.statehistory(state);
        if(auto history = key in *historyarray) history.add(this.time);
        else (*historyarray)[key] = History(this.time);
    }
    
    // TODO: Also update state using Keyboard.State, Mouse.State, etc.
    // and call it at app startup to know the initial state of keys
    // (only pressed keys should matter here, not released keys)
    
    /// Update state when there were no polled events.
    /// Must receive the current timestamp, ideally from SDL_GetTicks.
    void update(Timestamp timestamp){
        this.settime(timestamp);
    }
    /// Update state according to a polled event.
    /// Events should always be received in chronological order.
    void update(Timestamp timestamp, in Key key, in State state){
        this.settime(timestamp);
        this.add(key, state);
    }
    
    /// Set the internal representation of the current time.
    /// Called by update methods.
    void settime(Timestamp timestamp){
        EventTime current = EventTime(timestamp);
        if(current.timestamp == this.time.timestamp){
            current.order = this.time.order + 1;
        }
        this.time = current;
    }
    
    /// Clear all button history data.
    /// Does not affect the current time.
    void clear(){
        this.presshistory.clear();
        this.releasehistory.clear();
        static if(repeats) this.repeathistory.clear();
    }
    
    /// Get whether a button is currently being held down.
    bool down(in Key key) const{
        if(auto phistory = key in this.presshistory){
            if(auto rhistory = key in this.releasehistory){
                assert(phistory.recent != rhistory.recent);
                return phistory.recent > rhistory.recent;
            }else{
                return true;
            }
        }else{
            return false;
        }
    }
    /// Get whether a button is not currently being held down.
    bool up(in Key key) const{
        return !this.down(key);
    }
    
    /// Get the number of milliseconds since a button last entered a given state.
    /// Returns -1 if the button has yet to be pressed.
    auto statetime(State state)(in Key key) const{
        if(auto history = key in *(this.statehistory!state)){
            return this.time - history.recent;
        }else{
            return -1;
        }
    }
    /// Get the number of milliseconds since a button was last pressed.
    auto pressedtime(in Key key) const{
        return this.statetime!(State.Pressed)(key);
    }
    /// Get the number of milliseconds since a button was last released.
    auto releasedtime(in Key key) const{
        return this.statetime!(State.Released)(key);
    }
    /// Get the number of milliseconds since a button was last repeated.
    static if(repeats) auto repeatedtime(in Key key) const{
        return this.statetime!(State.Repeated)(key);
    }
    
    /// Get whether an event was just detected placing the button in the given
    /// state.
    bool stated(State state)(in Key key) const{
        if(auto history = key in *(this.statehistory!state)){
            return history.recent.timestamp == this.time.timestamp;
        }else{
            return false;
        }
    }
    /// Get whether a button was just pressed.
    bool pressed(in Key key) const{
        return this.stated!(State.Pressed)(key);
    }
    /// Get whether a button was just released.
    bool released(in Key key) const{
        return this.stated!(State.Released)(key);
    }
    /// Get whether a button was just repeated.
    static if(repeats) bool repeated(in Key key) const{
        return this.stated!(State.Repeated)(key);
    }
    
    /// Used by methods which get the most recent button pressed, released, or
    /// repeated.
    static struct LastEvent{
        bool exists = false;
        Key key = void;
        Time time = void;
        alias button = key;
        void set(Key key, Time time){
            this.key = key;
            this.time = time;
            this.exists = true;
        }
        @property Timestamp timestamp() const in{assert(this.exists);} body{
            return this.time.timestamp;
        }
    }
    /// Get the button most recently set to a given state.
    /// The returned type exposes exists, key, and timestamp properties.
    auto laststated(State state)() const{
        LastEvent last;
        foreach(key, history; *(this.statehistory!state)){
            if(history.length && (!last.exists || history.recent > last.time)){
                last.set(key, history.recent);
            }
        }
        return last;
    }
    /// Get the most recently pressed button.
    auto lastpressed() const{
        return this.laststated!(State.Pressed);
    }
    /// Get the most recently released button.
    auto lastreleased() const{
        return this.laststated!(State.Released);
    }
    /// Get the most recently repeated button.
    static if(repeats) auto lastrepeated() const{
        return this.laststated!(State.Repeated);
    }
    
    /// Get whether a button was just double-pressed, triple-pressed, etc. as
    /// determined by the count. Accepts a maxmimum number of milliseconds
    /// between presses.
    bool npressed(in Key key, in size_t count, in Timestamp interval = DefaultTapInterval) const in{
        assert(count <= historylength);
    }body{
        if(auto history = key in this.presshistory){
            if(history.length >= count){
                for(size_t i; i < count - 1; i++){
                    if((*history)[i] - (*history)[i + 1] > interval) return false;
                }
                return true;
            }
        }
        return false;
    }
    /// Get whether a button was just double-pressed.
    bool doublepressed(in Key key, in Timestamp interval = DefaultTapInterval) const{
        return this.npressed(key, 2, interval);
    }
    /// Get whether a button was just triple-pressed.
    bool triplepressed(in Key key, in Timestamp interval = DefaultTapInterval) const{
        return this.npressed(key, 3, interval);
    }
    
    /// Get whether a button was just pressed and then released, with the whole
    /// enterprise taking no more than the provided number of milliseconds.
    bool tapped(in Key key, in Timestamp interval = DefaultTapInterval) const{
        if(auto rhistory = key in this.releasehistory){
            if(rhistory.recent.timestamp == this.time.timestamp){
                if(auto phistory = key in this.presshistory){
                    return (
                        rhistory.recent > phistory.recent &&
                        rhistory.recent - phistory.recent <= interval
                    );
                }
            }
        }
        return false;
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.io.log;
}
unittest{
    tests("Polled input helper", {
        EventHistoryAggregation!char agg;
        // Verify initial state
        test(!agg.down('a'));
        test(agg.up('a'));
        test(!agg.pressed('a'));
        test(!agg.released('a'));
        test(!agg.lastpressed.exists);
        test(!agg.lastreleased.exists);
        // Step, press a
        agg.update(0, 'a', agg.State.Pressed);
        test(agg.down('a'));
        test(!agg.up('a'));
        test(agg.up('b'));
        test(agg.pressed('a'));
        test(!agg.released('a'));
        test(agg.lastpressed.exists);
        test(agg.lastpressed.timestamp == 0);
        test(agg.lastpressed.key == 'a');
        // Step, no events
        agg.update(1);
        test(agg.down('a'));
        test(!agg.pressed('a'));
        test(!agg.released('a'));
        testeq(agg.pressedtime('a'), 1);
        test(!agg.tapped('b'));
        // Step, press b
        agg.update(2, 'b', agg.State.Pressed);
        test(agg.down('a'));
        test(agg.down('b'));
        test(!agg.pressed('a'));
        test(!agg.released('a'));
        test(agg.pressed('b'));
        test(!agg.tapped('b'));
        test(agg.lastpressed.exists);
        test(agg.lastpressed.timestamp == 2);
        test(agg.lastpressed.key == 'b');
        // No step, release b
        agg.update(2, 'b', agg.State.Released);
        test(agg.down('a'));
        test(agg.up('b'));
        test(agg.pressed('b'));
        test(agg.released('b'));
        test(agg.tapped('b'));
        test(agg.lastreleased.exists);
        test(agg.lastreleased.timestamp == 2);
        test(agg.lastreleased.key == 'b');
        // Step, press b again
        agg.update(3, 'b', agg.State.Pressed);
        test(agg.down('b'));
        test(agg.pressed('b'));
        test(agg.doublepressed('b'));
        test(!agg.triplepressed('b'));
        // Step, release a and b
        agg.update(4, 'a', agg.State.Released);
        agg.update(4, 'b', agg.State.Released);
        test(agg.up('a'));
        test(agg.up('b'));
        test(agg.released('a'));
        test(agg.released('b'));
    });
}
