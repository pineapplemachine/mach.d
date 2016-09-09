module mach.sdl.input.keyboard;

private:

import derelict.sdl2.sdl;
import mach.sdl.window : Window;
import mach.sdl.input.keycode;

public:



struct Keyboard{
    /// Get the window which currently has keyboard focus.
    /// https://wiki.libsdl.org/SDL_GetKeyboardFocus
    Window focus(){
        return Window.byptr(SDL_GetKeyboardFocus());
    }
    
    /// Determine whether the device supports an on-screen keyboard.
    /// https://wiki.libsdl.org/SDL_HasScreenKeyboardSupport
    bool screensupport(){
        return cast(bool) SDL_HasScreenKeyboardSupport();
    }
    /// Determine whether the device's on-screen keyboard is currently shown.
    /// https://wiki.libsdl.org/SDL_IsScreenKeyboardShown
    bool screenshown(Window window){
        return cast(bool) SDL_IsScreenKeyboardShown(window.window);
    }

    /// Represents the state of keys on the keyboard.
    struct State{
        alias Keys = ubyte*;
        alias Length = int;
        
        Keys keys;
        Length length;
        
        /// Get an object representing the current state of the keyboard.
        /// Beware, keys pressed and released in between queue pumps will not be
        /// detected by repeatedly checking this data; only by actually polling
        /// and handling those events.
        /// https://wiki.libsdl.org/SDL_GetKeyboardState
        static typeof(this) current(){
            typeof(this) state;
            state.keys = SDL_GetKeyboardState(&state.length);
            return state;
        }
        
        bool ispressed(KeyCode code) const{
            return this.ispressed(code.scancode);
        }
        bool ispressed(ScanCode code) const{
            return cast(bool) this.keys[code];
        }
        void setpressed(KeyCode code, bool pressed){
            this.setpressed(code.scancode, pressed);
        }
        void setpressed(ScanCode code, bool pressed){
            this.keys[code] = cast(ubyte) pressed;
        }
        
        bool opIndex(T)(T code) if(is(T == KeyCode) || is(T == ScanCode)){
            return this.ispressed(code);
        }
        bool opIndexAssign(T)(bool pressed, T code) if(is(T == KeyCode) || is(T == ScanCode)){
            return this.setpressed(code, pressed);
        }
        
        int opApply(in int delegate(in size_t scancode, in bool pressed) apply) const{
            for(size_t i; i < this.length; i++){
                if(auto result = apply(i, cast(bool) this.keys[i])) return result;
            }
            return 0;
        }
    }
}
