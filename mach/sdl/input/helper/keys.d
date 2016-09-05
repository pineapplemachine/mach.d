module mach.sdl.input.helper.keys;

private:

import derelict.sdl2.sdl;

import mach.text : text;
import mach.sdl.input.event.event;
import mach.sdl.input.common;
import mach.sdl.input.keycode;
import mach.sdl.input.keymod;
import mach.sdl.input.keyboard;

public:



/// Used by Keys type to record when a key event occured.
struct KeyTime{
    /// The timestamp associated with the event
    Timestamp timestamp = 0;
    /// Where two objects have an identical timestamp, their relative ordering
    /// in the queue can be determined by comparing this value.
    size_t order = 0;
    /// Compare two objects.
    int opCmp(in KeyTime time) const{
        if(this.timestamp > time.timestamp) return 1;
        else if(this.timestamp < time.timestamp) return -1;
        else if(this.order > time.order) return 1;
        else if(this.order < time.order) return -1;
        else return 0;
    }
    Timestamp opBinary(string op)(in KeyTime time) const{
        return this.opBinary!op(time.timestamp);
    }
    Timestamp opBinary(string op)(in Timestamp timestamp) const{
        mixin(`return this.timestamp ` ~ op ~ `timestamp;`);
    }
    string toString() const{
        return text(this.timestamp, 'T', this.order);
    }
}



/// Processes polled events to generate a data structure convenient for checking
/// keyboard input.
struct Keys{
    /// Record the last time that internal state was updated
    KeyTime lasttime;
    /// Record the last time that each key was pressed, not including repeats.
    KeyTime[ScanCode] pressedtime;
    /// Record the last time that each key was repeated, not including the
    /// initial press.
    KeyTime[ScanCode] repeattime;
    /// Record the last time that each key was released.
    KeyTime[ScanCode] releasedtime;
    /// The most recent state of the keyboard modifiers.
    KeyMod mod;
    
    /// Update state when there were no polled events.
    void update(){
        KeyTime currenttime = KeyTime(SDL_GetTicks());
        if(currenttime.timestamp == this.lasttime.timestamp){
            currenttime.order = this.lasttime.order + 1;
        }
        this.lasttime = currenttime;
    }
    /// Update state according to a polled event.
    /// Events should always be received in chronological order.
    void update(Event event){
        KeyTime currenttime = KeyTime(event.timestamp);
        if(currenttime.timestamp == this.lasttime.timestamp){
            currenttime.order = this.lasttime.order + 1;
        }
        if(event.type is event.Type.KeyDown){
            if(!event.key.isrepeat){
                this.pressedtime[event.key.scancode] = currenttime;
            }else{
                this.repeattime[event.key.scancode] = currenttime;
            }
        }else if(event.type is event.Type.KeyUp){
            this.releasedtime[event.key.scancode] = currenttime;
        }
        this.lasttime = currenttime;
    }
    
    /// Update the internal modifier keys state. Called automatically when
    /// an event is received.
    void updatemod(){
        this.mod = KeyMod.current();
    }
    
    /// Get whether a key is currently being held down.
    bool down(in KeyCode code) const{return this.down(code.scancode);}
    /// ditto
    bool down(in ScanCode code) const{
        if(auto ptime = code in this.pressedtime){
            if(auto rtime = code in this.releasedtime){
                assert(*ptime != *rtime);
                return *ptime > *rtime;
            }else{
                return true;
            }
        }else{
            return false;
        }
    }
    /// Get whether a key is not currently being held down.
    bool up(in KeyCode code) const{return this.up(code.scancode);}
    /// ditto
    bool up(in ScanCode code) const{
        if(auto rtime = code in this.releasedtime){
            if(auto ptime = code in this.pressedtime){
                assert(*ptime != *rtime);
                return *ptime < *rtime;
            }else{
                return true;
            }
        }else{
            return false;
        }
    }
    
    /// Get the number of milliseconds since a key was last pressed. Returns -1
    /// if the key has yet to be pressed.
    auto downtime(in KeyCode code) const{return this.downtime(code.scancode);}
    /// ditto
    auto downtime(in ScanCode code) const{
        if(auto ptime = code in this.pressedtime){
            return this.lasttime - *ptime;
        }else{
            return -1;
        }
    }
    /// Get the number of milliseconds since a key was last released. Returns -1
    /// if the key has yet to be released.
    auto uptime(in KeyCode code) const{return this.uptime(code.scancode);}
    /// ditto
    auto uptime(in ScanCode code) const{
        if(auto rtime = code in this.releasedtime){
            return this.lasttime - *rtime;
        }else{
            return -1;
        }
    }
    
    /// Get whether a key was just pressed.
    bool pressed(in KeyCode code) const{return this.pressed(code.scancode);}
    /// ditto
    bool pressed(in ScanCode code) const{
        if(auto time = code in this.pressedtime){
            return time.timestamp == this.lasttime.timestamp;
        }else{
            return false;
        }
    }
    /// Get whether a key was just released.
    bool released(in KeyCode code) const{return this.released(code.scancode);}
    /// ditto
    bool released(in ScanCode code) const{
        if(auto time = code in this.releasedtime){
            return time.timestamp == this.lasttime.timestamp;
        }else{
            return false;
        }
    }
    /// Get whether a key was just repeated.
    bool repeated(in KeyCode code) const{return this.repeated(code.scancode);}
    /// ditto
    bool repeated(in ScanCode code) const{
        if(auto time = code in this.repeattime){
            return *time == this.lasttime;
        }else{
            return false;
        }
    }
    
    /// Get whether a key was just pressed and then released, with the whole
    /// enterprise taking no more than the provided number of milliseconds.
    bool tapped(in KeyCode code, in Timestamp time = 200){
        return this.tapped(code.scancode, time);
    }
    /// ditto
    bool tapped(in ScanCode code, in Timestamp time = 200){
        if(auto rtime = code in this.releasedtime){
            if(rtime.timestamp == this.lasttime.timestamp){
                if(auto ptime = code in this.pressedtime){
                    return *rtime > *ptime && *rtime - *ptime <= time;
                }
            }
        }
        return false;
    }
}
