module mach.sdl.input.event.keyboard;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;
import mach.sdl.input.keycode;
import mach.sdl.input.keymod;

public:



/// Event related to keyboard input.
/// https://wiki.libsdl.org/SDL_KeyboardEvent
struct KeyboardEvent{
    mixin EventMixin!SDL_KeyboardEvent;
    mixin WindowEventMixin;
    mixin ButtonStateEventMixin;
    /// Get whether this is a key repeat.
    @property bool isrepeat() const{
        return this.eventdata.repeat != 0;
    }
    /// Set whether this is a key repeat.
    @property void isrepeat(bool repeat){
        this.eventdata.repeat = repeat;
    }
    /// Get the scancode of the key associated with the event.
    @property ScanCode scancode() const{
        return cast(ScanCode) this.eventdata.keysym.scancode;
    }
    /// Set the scancode of the key associated with the event.
    @property void scancode(ScanCode code) const{
        this.eventdata.keysym.scancode = code;
    }
    /// Get the keykode of the key associated with the event.
    @property KeyCode keycode() const{
        return cast(KeyCode) this.eventdata.keysym.sym;
    }
    /// Set the keykode of the key associated with the event.
    @property void keycode(KeyCode code) const{
        this.eventdata.keysym.sym = code;
    }
    /// Get the modifier state of the key associated with the event.
    @property KeyMod keymod() const{
        return KeyMod(this.eventdata.keysym.sym);
    }
    /// Set the modifier state of the key associated with the event.
    @property void keymod(KeyMod mod) const{
        this.eventdata.keysym.mod = cast(ushort) mod;
    }
    /// Get the human-readable name of the key associated with the event.
    @property string name() const{
        return this.keycode.name;
    }
}
