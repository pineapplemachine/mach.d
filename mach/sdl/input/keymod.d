module mach.sdl.input.keymod;

private:

import derelict.sdl2.sdl;
import std.traits : isIntegral;

public:



/// Wraps an SDL_Keymod value, which is a bitfield indicating which modifier
/// keys are pressed at a given time. Provides helpful methods for accessing
/// those flags.
struct KeyMod{
    // Reference: https://wiki.libsdl.org/SDL_Keymod
    static enum Code: SDL_Keymod{
        // Single keys
        None = KMOD_NONE,
        LShift = KMOD_LSHIFT,
        RShift = KMOD_RSHIFT,
        LCtrl = KMOD_LCTRL,
        RCtrl = KMOD_RCTRL,
        LAlt = KMOD_LALT,
        RAlt = KMOD_RALT,
        LGui = KMOD_LGUI,
        RGui = KMOD_RGUI,
        Num = KMOD_NUM,
        Caps = KMOD_CAPS,
        Mode = KMOD_MODE, AltGr = Mode,
        // Or'd left and right keys
        Ctrl = KMOD_CTRL,
        Shift = KMOD_SHIFT,
        Alt = KMOD_ALT,
        Gui = KMOD_GUI,
    }
    
    SDL_Keymod mod;
    alias mod this;
    
    this(T)(T mod) if(isIntegral!T){
        this.mod = cast(SDL_Keymod) mod;
    }
    
    /// Determine whether no modifier keys are being pressed.
    @property bool none(){
        return this.mod == 0;
    }
    
    private template PropertyMixin(Code code){
        @property bool PropertyMixin() const{
            return (this.mod & code) != 0;
        }
        @property void PropertyMixin(bool active){
            if(active) this.mod |= code;
            else this.mod &= ~code;
        }
    }
    
    /// Shift modifier
    alias shift = PropertyMixin!(Code.Shift);
    alias lshift = PropertyMixin!(Code.LShift);
    alias rshift = PropertyMixin!(Code.RShift);
    /// Control modifier
    alias ctrl = PropertyMixin!(Code.Ctrl);
    alias lctrl = PropertyMixin!(Code.LCtrl);
    alias rctrl = PropertyMixin!(Code.RCtrl);
    /// Alt modifier
    alias alt = PropertyMixin!(Code.Alt);
    alias lalt = PropertyMixin!(Code.LAlt);
    alias ralt = PropertyMixin!(Code.RAlt);
    /// Windows/Cmd/Meta modifier
    alias gui = PropertyMixin!(Code.Gui);
    alias lgui = PropertyMixin!(Code.LGui);
    alias rgui = PropertyMixin!(Code.RGui);
    /// NumLock
    alias num = PropertyMixin!(Code.Num);
    alias numlock = num;
    /// CapsLock
    alias caps = PropertyMixin!(Code.Caps);
    alias capslock = caps;
    /// AltGr
    alias mode = PropertyMixin!(Code.Mode);
    alias altgr = mode;
}
