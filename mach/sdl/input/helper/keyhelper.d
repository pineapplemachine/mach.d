module mach.sdl.input.helper.keyhelper;

private:

import derelict.sdl2.sdl;

import mach.text : text;
import mach.sdl.input.event.event;
import mach.sdl.input.common : Timestamp;
import mach.sdl.input.keycode;
import mach.sdl.input.keymod;
import mach.sdl.input.keyboard;
import mach.sdl.input.helper.history;

public:



/// Processes polled events to generate a data structure convenient for checking
/// keyboard input.
struct KeyHelper(size_t historylength = 3, bool repeats = false){
    alias History = EventHistoryAggregation!(ScanCode, historylength, void, repeats);
    
    History history; /// For tracking keypress and release history.
    KeyMod mod; /// The most recent state of the keyboard modifiers.
    
    /// Update state when there were no polled events.
    void update(){
        this.history.update(SDL_GetTicks());
        this.updatemod();
    }
    /// Update state according to a polled event.
    /// Events should always be received in chronological order.
    void update(Event event){
        if(event.type is event.Type.KeyDown){
            auto state = History.State.Pressed;
            static if(repeats){
                if(event.key.isrepeat) state = History.State.Repeated;
            }
            this.history.update(event.timestamp, event.key.scancode, state);
        }else if(event.type is event.Type.KeyUp){
            this.history.update(
                event.timestamp, event.key.scancode, History.State.Released
            );
        }else{
            this.history.update(event.timestamp);
        }
        this.updatemod();
    }
    /// Update given a keyboard state. Clears all prior history.
    /// Really only intended for running at initialization.
    void update(in Keyboard.State state){
        this.history.clear();
        foreach(scancode, pressed; state){
            if(pressed) this.history.add(cast(ScanCode) scancode, History.State.Pressed);
        }
        this.updatemod();
    }
    
    /// Update the internal modifier keys state. Called automatically when
    /// an event is received.
    void updatemod(){
        this.mod = KeyMod.current();
    }
    
    /// Get whether a key is currently being held down.
    bool down(in KeyCode code) const{return this.history.down(code.scancode);}
    /// ditto
    bool down(in ScanCode code) const{return this.history.down(code);}
    /// Get whether a key is not currently being held down.
    bool up(in KeyCode code) const{return this.history.up(code.scancode);}
    /// ditto
    bool up(in ScanCode code) const{return this.history.up(code);}
    
    /// Get whether a key was just pressed.
    auto pressed(in KeyCode code) const{return this.history.pressed(code.scancode);}
    /// ditto
    auto pressed(in ScanCode code) const{return this.history.pressed(code);}
    /// Get whether a key was just released.
    auto released(in KeyCode code) const{return this.history.released(code.scancode);}
    /// ditto
    auto released(in ScanCode code) const{return this.history.released(code);}
    
    static if(repeats){
        /// Get whether a key was just repeated.
        auto repeated(in KeyCode code) const{return this.history.repeated(code.scancode);}
        /// ditto
        auto repeated(in ScanCode code) const{return this.history.repeated(code);}
    }
    
    /// Get the number of ticks since a key was last pressed.
    auto pressedtime(in KeyCode code) const{return this.history.pressedtime(code.scancode);}
    /// ditto
    auto pressedtime(in ScanCode code) const{return this.history.pressedtime(code);}
    /// Get the number of ticks since a key was last released.
    auto releasedtime(in KeyCode code) const{return this.history.releasedtime(code.scancode);}
    /// ditto
    auto releasedtime(in ScanCode code) const{return this.history.releasedtime(code);}
    
    static if(repeats){
        /// Get the number of ticks since a key was last repeated.
        /// Returns -1 if the key has yet to be repeated.
        bool repeatedtime(in KeyCode code) const{return this.history.repeatedtime(code.scancode);}
        /// ditto
        bool repeatedtime(in ScanCode code) const{return this.history.repeatedtime(code);}
    }
    
    /// Get the most recently pressed key.
    auto lastpressed() const{return this.history.lastpressed();}
    /// Get the most recently released key.
    auto lastreleased() const{return this.history.lastreleased();}
    
    static if(repeats){
        /// Get the most recently repeated key.
        auto lastrepeated() const{return this.history.lastrepeated();}
    }
    
    /// Get whether a button was just double-pressed, triple-pressed, etc. as
    /// determined by the count. Accepts a maxmimum number of ticks
    /// between presses.
    auto npressed(in KeyCode code, size_t count, in Timestamp interval = History.DefaultTapInterval){
        return this.history.npressed(code.scancode, count, interval);
    }
    /// ditto
    auto npressed(in ScanCode code, size_t count, in Timestamp interval = History.DefaultTapInterval){
        return this.history.npressed(code, count, interval);
    }
    /// Get whether a button was just double-pressed.
    auto doublepressed(in KeyCode code, in Timestamp interval = History.DefaultTapInterval){
        return this.history.doublepressed(code.scancode, interval);
    }
    /// ditto
    auto doublepressed(in ScanCode code, in Timestamp interval = History.DefaultTapInterval){
        return this.history.doublepressed(code, interval);
    }
    /// Get whether a button was just triple-pressed.
    auto triplepressed(in KeyCode code, in Timestamp interval = History.DefaultTapInterval){
        return this.history.triplepressed(code.scancode, interval);
    }
    /// ditto
    auto triplepressed(in ScanCode code, in Timestamp interval = History.DefaultTapInterval){
        return this.history.triplepressed(code, interval);
    }
    
    /// Get whether a key was just pressed and then released, with the whole
    /// enterprise taking no more than the provided number of ticks.
    auto tapped(in KeyCode code, in Timestamp interval = History.DefaultTapInterval){
        return this.history.tapped(code.scancode, interval);
    }
    /// ditto
    auto tapped(in ScanCode code, in Timestamp interval = History.DefaultTapInterval){
        return this.history.tapped(code, interval);
    }
}
