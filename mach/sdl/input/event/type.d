module mach.sdl.input.event.type;

private:

import derelict.sdl2.sdl;
import mach.sdl.input.common : EventState;

public:



/// Get whether events of a given type are enabled.
bool enabled(EventType type){
    return cast(bool) SDL_GetEventState(type);
}
/// Get whether events of a given type are disabled.
bool disabled(EventType type){
    return !enabled(type);
}

/// Enable events of a given type.
void enable(EventType type){
    SDL_EventState(type, EventState.Enable);
}
/// Disable events of a given type.
void disable(EventType type){
    SDL_EventState(type, EventState.Disable);
}

    
    
/// https://wiki.libsdl.org/SDL_Event
enum EventType: uint{
    First = SDL_FIRSTEVENT, FirstEvent = First,
    
    /// Normal stuff
    Window = SDL_WINDOWEVENT, WindowEvent = Window,
    KeyUp = SDL_KEYUP,
    KeyDown = SDL_KEYDOWN,
    TextEditing = SDL_TEXTEDITING,
    TextInput = SDL_TEXTINPUT,
    MouseMotion = SDL_MOUSEMOTION,
    MouseButtonUp = SDL_MOUSEBUTTONUP,
    MouseButtonDown = SDL_MOUSEBUTTONDOWN,
    MouseWheel = SDL_MOUSEWHEEL,
    JoyAxisMotion = SDL_JOYAXISMOTION,
    JoyBallMotion = SDL_JOYBALLMOTION,
    JoyHatMotion = SDL_JOYHATMOTION,
    JoyButtonUp = SDL_JOYBUTTONUP,
    JoyButtonDown = SDL_JOYBUTTONDOWN,
    JoyDeviceAdded = SDL_JOYDEVICEADDED,
    JoyDeviceRemoved = SDL_JOYDEVICEREMOVED,
    ControllerAxisMotion = SDL_CONTROLLERAXISMOTION,
    ControllerButtonUp = SDL_CONTROLLERBUTTONUP,
    ControllerButtonDown = SDL_CONTROLLERBUTTONDOWN,
    ControllerDeviceAdded = SDL_CONTROLLERDEVICEADDED,
    ControllerDeviceRemoved = SDL_CONTROLLERDEVICEREMOVED,
    ControllerDeviceRemapped = SDL_CONTROLLERDEVICEREMAPPED,
    AudioDeviceAdded = SDL_AUDIODEVICEADDED,
    AudioDeviceRemoved = SDL_AUDIODEVICEREMOVED,
    Quit = SDL_QUIT,
    User = SDL_USEREVENT, UserEvent = User,
    SysWindowManager = SDL_SYSWMEVENT, SysWindowManagerEvent = SysWindowManager,
    FingerUp = SDL_FINGERUP,
    FingerDown = SDL_FINGERDOWN,
    FingerMotion = SDL_FINGERMOTION,
    MultiGesture = SDL_MULTIGESTURE,
    DollarGesture = SDL_DOLLARGESTURE,
    DollarRecord = SDL_DOLLARRECORD,
    DropFile = SDL_DROPFILE,
    
    KeymapChanged = SDL_KEYMAPCHANGED,
    ClipboardUpdate = SDL_CLIPBOARDUPDATE,
    RenderTargetsReset = SDL_RENDER_TARGETS_RESET,
    RenderDeviceReset = SDL_RENDER_DEVICE_RESET,
    
    // Specific to mobile and embedded devices
    AppTerminating = SDL_APP_TERMINATING,
    AppLowMemory = SDL_APP_LOWMEMORY,
    AppWillEnterBackground = SDL_APP_WILLENTERBACKGROUND,
    AppDidEnterBackground = SDL_APP_DIDENTERBACKGROUND,
    AppWillEnterForeground = SDL_APP_WILLENTERFOREGROUND,
    AppDidEnterForeground = SDL_APP_DIDENTERFOREGROUND,
    
    Last = SDL_LASTEVENT, LastEvent = Last,
}
