module mach.sdl.input.event.type;

private:

import derelict.sdl2.types;

public:



/// https://wiki.libsdl.org/SDL_Event
enum EventType: uint{
    First = SDL_FIRSTEVENT, FirstEvent = First,
    
    /// Normal stuff
    Window = SDL_WINDOWEVENT, WindowEvent = Window,
    KeyDown = SDL_KEYDOWN,
    KeyUp = SDL_KEYUP,
    TextEditing = SDL_TEXTEDITING,
    TextInput = SDL_TEXTINPUT,
    MouseMotion = SDL_MOUSEMOTION,
    MouseButtonDown = SDL_MOUSEBUTTONDOWN,
    MouseButtonUp = SDL_MOUSEBUTTONUP,
    MouseWheel = SDL_MOUSEWHEEL,
    JoyAxisMotion = SDL_JOYAXISMOTION,
    JoyBallMotion = SDL_JOYBALLMOTION,
    JoyHatMotion = SDL_JOYHATMOTION,
    JoyButtonDown = SDL_JOYBUTTONDOWN,
    JoyButtonUp = SDL_JOYBUTTONUP,
    JoyDeviceAdded = SDL_JOYDEVICEADDED,
    JoyDeviceRemoved = SDL_JOYDEVICEREMOVED,
    ControllerAxisMotion = SDL_CONTROLLERAXISMOTION,
    ControllerButtonDown = SDL_CONTROLLERBUTTONDOWN,
    ControllerButtonUp = SDL_CONTROLLERBUTTONUP,
    ControllerDeviceAdded = SDL_CONTROLLERDEVICEADDED,
    ControllerDeviceRemoved = SDL_CONTROLLERDEVICEREMOVED,
    ControllerDeviceRemapped = SDL_CONTROLLERDEVICEREMAPPED,
    AudioDeviceAdded = SDL_AUDIODEVICEADDED,
    AudioDeviceRemoved = SDL_AUDIODEVICEREMOVED,
    Quit = SDL_QUIT,
    User = SDL_USEREVENT, UserEvent = User,
    SysWindowManager = SDL_SYSWMEVENT, SysWindowManagerEvent = SysWindowManager,
    FingerDown = SDL_FINGERDOWN,
    FingerUp = SDL_FINGERUP,
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
