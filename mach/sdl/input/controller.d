module mach.sdl.input.controller;

private:

import derelict.sdl2.sdl;

import std.string : fromStringz, toStringz;
import mach.sdl.error : SDLError;
import mach.sdl.input.common : EventState;
import mach.sdl.input.joystick;

public:



struct Controller{
    /// Enumeration of the axes recognized on a controller.
    /// https://wiki.libsdl.org/SDL_GameControllerAxis
    enum Axis: SDL_GameControllerAxis{
        Invalid = SDL_CONTROLLER_AXIS_INVALID,
        LeftX = SDL_CONTROLLER_AXIS_LEFTX, LX = LeftX,
        LeftY = SDL_CONTROLLER_AXIS_LEFTY, LY = LeftY,
        RightX = SDL_CONTROLLER_AXIS_RIGHTX, RX = RightX,
        RightY = SDL_CONTROLLER_AXIS_RIGHTY, RY = RightY,
        TriggerLeft = SDL_CONTROLLER_AXIS_TRIGGERLEFT, LeftTrigger = TriggerLeft, LTrigger = TriggerLeft,
        TriggerRight = SDL_CONTROLLER_AXIS_TRIGGERRIGHT, RightTrigger = TriggerRight, RTrigger = TriggerRight,
        Max = SDL_CONTROLLER_AXIS_MAX,
    }
    /// Enumeration of the buttons recognized on a controller.
    /// https://wiki.libsdl.org/SDL_GameControllerButton
    enum Button: SDL_GameControllerButton{
        Invalid = SDL_CONTROLLER_BUTTON_INVALID,
        A = SDL_CONTROLLER_BUTTON_A,
        B = SDL_CONTROLLER_BUTTON_B,
        X = SDL_CONTROLLER_BUTTON_X,
        Y = SDL_CONTROLLER_BUTTON_Y,
        Back = SDL_CONTROLLER_BUTTON_BACK,
        Guide = SDL_CONTROLLER_BUTTON_GUIDE,
        Start = SDL_CONTROLLER_BUTTON_START,
        LeftStick = SDL_CONTROLLER_BUTTON_LEFTSTICK, LStick = LeftStick,
        RightStick = SDL_CONTROLLER_BUTTON_RIGHTSTICK, RStick = RightStick,
        LeftShoulder = SDL_CONTROLLER_BUTTON_LEFTSHOULDER, LShoulder = LeftShoulder,
        RightShoulder = SDL_CONTROLLER_BUTTON_RIGHTSHOULDER, RShoulder = RightShoulder,
        DpadUp = SDL_CONTROLLER_BUTTON_DPAD_UP, Up = DpadUp,
        DpadDown = SDL_CONTROLLER_BUTTON_DPAD_DOWN, Down = DpadDown,
        DpadLeft = SDL_CONTROLLER_BUTTON_DPAD_LEFT, Left = DpadLeft,
        DpadRight = SDL_CONTROLLER_BUTTON_DPAD_RIGHT, Right = DpadRight,
        Max = SDL_CONTROLLER_BUTTON_MAX,
    }
    
    alias ID = Joystick.ID;
    alias DeviceIndex = Joystick.DeviceIndex;
    alias Ctrl = SDL_GameController*; /// In fact a pointer to an empty struct
    
    Ctrl ctrl;
    
    this(Ctrl ctrl){
        this.ctrl = ctrl;
    }
    
    /// Get the number of attached joystick devices.
    static auto count(){
        return Joystick.count();
    }
    
    /// Get whether a joystick is supported by the game controller interface by
    /// its device index.
    /// https://wiki.libsdl.org/SDL_IsGameController
    @property bool supported(DeviceIndex index){
        return cast(bool) SDL_IsGameController(index);
    }
    
    /// https://wiki.libsdl.org/SDL_GameControllerAddMapping
    auto addmapping(string mapping){
        auto result = SDL_GameControllerAddMapping(toStringz(mapping));
        if(result == -1) throw new SDLError("Failed to add controller mapping.");
        return result;
    }
    /// https://wiki.libsdl.org/SDL_GameControllerAddMappingsFromFile
    auto addmappings(string path){
        auto result = SDL_GameControllerAddMappingsFromFile(toStringz(path));
        if(result == -1) throw new SDLError("Failed to add controller mappings.");
        return result;
    }
    
    /// Set whether controller event polling is enabled or disabled. If events are
    /// disabled then Controller.update must be called in order to update controller
    /// state information.
    @property static void events(EventState state){
        auto result = SDL_GameControllerEventState(state);
        if(result < 0) throw new SDLError("Failed to set controller event state.");
    }
    /// Update state information for open controllers. If event polling is enabled
    /// for controllers then it is not necessary to call this function.
    static void update(){
        SDL_GameControllerUpdate();
    }
    
    /// Get the name of a controller given its device index.
    static string name(DeviceIndex index){
        auto name = SDL_GameControllerNameForIndex(index);
        if(name is null) throw new SDLError("Failed to get controller name.");
        return cast(string) fromStringz(name).dup;
    }
    /// Get the name of an opened controller.
    string name(){
        auto name = SDL_GameControllerName(this.ctrl);
        if(name is null) throw new SDLError("Failed to get controller name.");
        return cast(string) fromStringz(name).dup;
    }
    
    /// Get the joystick instance ID of an open controller.
    @property ID id(){
        return this.joystick.id;
    }
    /// Get a controller by its joystick instance ID.
    static typeof(this) byid(ID id){
        auto ctrl = SDL_GameControllerFromInstanceID(id);
        if(ctrl is null) throw new SDLError("Failed to get controller from instance id.");
        return typeof(this)(ctrl);
    }
    
    /// Get the joystick corresponding to an opened controller.
    static auto ctrljoy(Ctrl ctrl){
        auto joy = SDL_GameControllerGetJoystick(ctrl);
        if(joy is null) throw new SDLError("Failed to get controller joystick.");
        return joy;
    }
    /// ditto
    @property auto joystick(){
        return Joystick(this.ctrljoy(this.ctrl));
    }
    
    /// Open a controller for use given its device index.
    /// https://wiki.libsdl.org/SDL_GameControllerOpen
    static auto open(DeviceIndex index){
        auto ctrl = SDL_GameControllerOpen(index);
        if(ctrl is null) throw new SDLError("Failed to open controller.");
        return typeof(this)(ctrl);
    }
    /// Whether the controller is open.
    /// https://wiki.libsdl.org/SDL_GameControllerGetAttached
    @property bool isopen(){
        return cast(bool) SDL_GameControllerGetAttached(this.ctrl);
    }
    /// Close a previously opened controller.
    /// https://wiki.libsdl.org/SDL_GameControllerClose
    void close(){
        SDL_GameControllerClose(this.ctrl);
    }
    
    /// Get the current position of an axis, from -1.0 to 1.0.
    /// https://wiki.libsdl.org/SDL_GameControllerGetAxis
    @property auto axis(Axis axis){
        return Joystick.normalizeaxis(this.axisraw(axis));
    }
    /// Get axis position as a signed short.
    @property auto axisraw(Axis axis){
        return SDL_GameControllerGetAxis(this.ctrl, axis);;
    }
    /// Get whether a button is currently pressed.
    @property bool button(Button button){
        return SDL_GameControllerGetButton(this.ctrl, button) == 1;
    }
}
