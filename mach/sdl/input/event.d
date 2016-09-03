module mach.sdl.input.event;

private:

import derelict.sdl2.sdl;

import std.traits : isNumeric;
import std.string : fromStringz;
import mach.sdl.window : Window;
import mach.sdl.input.common;
import mach.sdl.input.controller;
import mach.sdl.input.keycode;
import mach.sdl.input.keymod;
import mach.sdl.input.joystick;
import mach.sdl.input.mouse;

public:



struct Event{
    /// Timestamps measure the number of milliseconds since the SDL library
    /// was initialized.
    /// Timestamps of events represent when SDL_PumpEvents was last called and
    /// not necessarily exactly when those events actually occurred.
    /// References:
    /// https://forums.libsdl.org/viewtopic.php?p=38148&sid=316e65d429d7668b40c879b105fa0b93
    /// https://github.com/ioquake/ioq3/issues/215
    alias Timestamp = uint;
    
    /// https://wiki.libsdl.org/SDL_Event
    enum Type: uint{
        FirstEvent = SDL_FIRSTEVENT,
        
        /// Normal stuff
        WindowEvent = SDL_WINDOWEVENT,
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
        UserEvent = SDL_USEREVENT,
        SysWindowManagerEvent = SDL_SYSWMEVENT,
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
        
        LastEvent = SDL_LASTEVENT,
    }
    
    SDL_Event event;
    
    /// Get the type of the event.
    @property Type type() const{
        return cast(Type) this.event.type;
    }
    /// Set the type of the event.
    @property void type(Type type){
        this.event.type = type;
    }
    /// Get the timestamp for when this event was detected. Measured in
    /// millisecs since SDL initialization.
    @property Timestamp timestamp() const{
        return cast(Timestamp) this.event.common.timestamp;
    }
    /// Set the timestamp for when this event was detected. Measured in
    /// millisecs since SDL initialization.
    @property void timestamp(Timestamp timestamp){
        this.event.common.timestamp = timestamp;
    }
    
    /// Some events possess resources which must be explicitly deallocated.
    /// Best practice would be to always call this when you're done with an
    /// event, but practically speaking it's only necessary for file drop
    /// events.
    void conclude(){
        if(this.type is Type.DropFile) this.dropfile.conclude();
    }
    
    @property auto window(){return WindowEvent(this.event);}
    @property auto key(){return KeyboardEvent(this.event);}
    @property auto textedit(){return TextEditingEvent(this.event);}
    @property auto textinput(){return TextInputEvent(this.event);}
    @property auto mousemotion(){return MouseMotionEvent(this.event);}
    @property auto mousebutton(){return MouseButtonEvent(this.event);}
    @property auto mousewheel(){return MouseWheelEvent(this.event);}
    @property auto joyaxis(){return JoyAxisEvent(this.event);}
    @property auto joybutton(){return JoyButtonEvent(this.event);}
    @property auto joyhat(){return JoyHatEvent(this.event);}
    @property auto joyball(){return JoyBallEvent(this.event);}
    @property auto joydevice(){return JoyDeviceEvent(this.event);}
    @property auto ctrlaxis(){return ControllerAxisEvent(this.event);}
    @property auto ctrlbutton(){return ControllerButtonEvent(this.event);}
    @property auto ctrldevice(){return ControllerDeviceEvent(this.event);}
    @property auto audiodevice(){return AudioDeviceEvent(this.event);}
    @property auto quit(){return QuitEvent(this.event);}
    @property auto user(){return UserEvent(this.event);}
    @property auto syswm(){return SysWindowManagerEvent(this.event);}
    @property auto touchfinger(){return TouchFingerEvent(this.event);}
    @property auto multigesture(){return MultiGestureEvent(this.event);}
    @property auto dollargesture(){return DollarGestureEvent(this.event);}
    @property auto dropfile(){return DropFileEvent(this.event);}
}



private template EventMixinAttribute(T){
    static if(is(T == SDL_CommonEvent)) enum EventMixinAttribute = `common`;
    else static if(is(T == SDL_WindowEvent)) enum EventMixinAttribute = `window`;
    else static if(is(T == SDL_KeyboardEvent)) enum EventMixinAttribute = `key`;
    else static if(is(T == SDL_TextEditingEvent)) enum EventMixinAttribute = `edit`;
    else static if(is(T == SDL_TextInputEvent)) enum EventMixinAttribute = `text`;
    else static if(is(T == SDL_MouseMotionEvent)) enum EventMixinAttribute = `motion`;
    else static if(is(T == SDL_MouseButtonEvent)) enum EventMixinAttribute = `button`;
    else static if(is(T == SDL_MouseWheelEvent)) enum EventMixinAttribute = `wheel`;
    else static if(is(T == SDL_JoyAxisEvent)) enum EventMixinAttribute = `jaxis`;
    else static if(is(T == SDL_JoyBallEvent)) enum EventMixinAttribute = `jball`;
    else static if(is(T == SDL_JoyHatEvent)) enum EventMixinAttribute = `jhat`;
    else static if(is(T == SDL_JoyButtonEvent)) enum EventMixinAttribute = `jbutton`;
    else static if(is(T == SDL_JoyDeviceEvent)) enum EventMixinAttribute = `jdevice`;
    else static if(is(T == SDL_ControllerAxisEvent)) enum EventMixinAttribute = `caxis`;
    else static if(is(T == SDL_ControllerButtonEvent)) enum EventMixinAttribute = `cbutton`;
    else static if(is(T == SDL_ControllerDeviceEvent)) enum EventMixinAttribute = `cdevice`;
    else static if(is(T == SDL_AudioDeviceEvent)) enum EventMixinAttribute = `adevice`;
    else static if(is(T == SDL_QuitEvent)) enum EventMixinAttribute = `quit`;
    else static if(is(T == SDL_UserEvent)) enum EventMixinAttribute = `user`;
    else static if(is(T == SDL_SysWMEvent)) enum EventMixinAttribute = `syswm`;
    else static if(is(T == SDL_TouchFingerEvent)) enum EventMixinAttribute = `tfinger`;
    else static if(is(T == SDL_MultiGestureEvent)) enum EventMixinAttribute = `mgesture`;
    else static if(is(T == SDL_DollarGestureEvent)) enum EventMixinAttribute = `dgesture`;
    else static if(is(T == SDL_DropEvent)) enum EventMixinAttribute = `drop`;
    else static assert(false, "Unrecognized SDL_Event type.");
}
private template EventMixin(T){
    mixin EventMixin!(T, EventMixinAttribute!T);
}
private template EventMixin(T, string attribute){
    SDL_Event event;
    @property auto eventdata() const{
        mixin(`return cast(T) this.event.` ~ attribute ~ `;`);
    }
}



/// For events including the focused window.
private template WindowEventMixin(){
    /// Get the ID of the window for which this event was generated.
    @property Window.ID windowid() const{
        return cast(Window.ID) this.eventdata.windowID;
    }
    /// Set the ID of the window for which this event was generated.
    @property void windowid(Window.ID windowid){
        this.eventdata.windowID = windowid;
    }
    /// Get the window object for which this event was generated.
    @property Window window(){
        return Window.byid(this.windowid);
    }
    /// Set the window for which this event was generated.
    @property void window(Window window){
        this.windowid = window.id;
    }
}

/// For events including the state of a button.
private template ButtonStateEventMixin(){
    /// Get whether the button was pressed or released.
    @property ButtonState state() const{
        return cast(ButtonState) this.eventdata.state;
    }
    /// Set whether the button was pressed or released.
    @property void state(ButtonState state){
        this.eventdata.state = cast(ubyte) state;
    }
    /// Get whether the button was pressed.
    @property bool pressed(){
        return this.state is ButtonState.Pressed;
    }
    /// Get whether the button was released.
    @property bool released(){
        return this.state is ButtonState.Released;
    }
}

/// For events including both the state of a button and a single identifier
/// representing the button that was pressed or released.
private template ButtonEventMixin(ButtonType){
    mixin ButtonStateEventMixin;
    alias Button = ButtonType;
    /// Get the button associated with the event.
    @property Button button() const{
        return cast(Button) this.eventdata.button;
    }
    /// Set the button associated with the event.
    @property void button(Button button) const{
        this.eventdata.button = cast(ubyte) button;
    }
}

/// For events including a mouse ID.
private template MouseEventMixin(){
    /// Indicate the window with mouse focus, if any.
    mixin WindowEventMixin;
    /// Get ID of the device which generated this event.
    @property MouseID mouseid() const{
        return cast(MouseID) this.eventdata.which;
    }
    /// Set ID of the device generating this event.
    @property void mouseid(MouseID mouseid){
        this.eventdata.which = mouseid;
    }
    /// Determine whether the event was generated by a touch input device rather
    /// than by an actual mouse.
    @property bool istouch() const{
        return this.mouseid == TouchMouseID;
    }
}

/// For events including x, y position data.
private template PositionEventMixin(string xattr = `x`, string yattr = `y`){
    /// Get the x position associated with the event.
    @property auto x() const{
        mixin(`return this.eventdata.` ~ xattr ~ `;`);
    }
    /// Set the x position associated with the event.
    @property void x(typeof(this.x()) x){
        mixin(`this.eventdata.` ~ xattr ~ ` = x;`);
    }
    /// Get the y position associated with the event.
    @property auto y() const{
        mixin(`return this.eventdata.` ~ yattr ~ `;`);
    }
    /// Set the y position associated with the event.
    @property void y(typeof(this.y()) y){
        mixin(`this.eventdata.` ~ yattr ~ ` = y;`);
    }
}

/// For events including change in x, y data.
private template RelativePositionEventMixin(string xattr = `dx`, string yattr = `dy`){
    /// Get the change in x associated with the event.
    @property auto dx() const{
        mixin(`return this.eventdata.` ~ xattr ~ `;`);
    }
    /// Set the change in x associated with the event.
    @property void dx(typeof(this.dx()) dx){
        mixin(`this.eventdata.` ~ xattr ~ ` = dx;`);
    }
    /// Get the change in y associated with the event.
    @property auto dy() const{
        mixin(`return this.eventdata.` ~ yattr ~ `;`);
    }
    /// Set the change in y associated with the event.
    @property void dy(typeof(this.dy()) dy){
        mixin(`this.eventdata.` ~ yattr ~ ` = dy;`);
    }
}

/// For events including text data.
private template TextEventMixin(){
    /// All text events also include window data.
    mixin WindowEventMixin;
    /// The size limit of event text.
    static enum TextSize = typeof(this.eventdata).text.length;
    /// Get the text associated with the event.
    @property string text() const{
        return cast(string) fromStringz(this.eventdata.text.ptr);
    }
    /// Set the text associated with the event.
    @property void text(string text) in{assert(text.length < TextSize);} body{
        for(size_t i = 0; i <= text.length; i++){
            this.eventdata.text[i] = cast(char) (text.ptr)[i];
        }
    }
}

/// For events including joystick data.
private template JoyEventMixin(){
    /// Get ID of the joystick which generated the event.
    @property Joystick.ID joystickid() const{
        return cast(Joystick.ID) this.eventdata.which;
    }
    /// Set ID of the joystick which generated the event.
    @property void joystickid(Joystick.ID joystickid){
        this.eventdata.which = joystickid;
    }
    /// Get a Joystick object representing the device which generated the event.
    @property Joystick joystick(){
        return Joystick.byid(this.joystickid);
    }
    /// Set the Joystick object which generated the event.
    @property void joystick(Joystick joystick){
        this.joystickid = joystick.id;
    }
}

/// For events including controller data.
private template ControllerEventMixin(){
    /// All events with controller data also include joystick data.
    mixin JoyEventMixin;
    /// Get a Controller object for the device which generated the event.
    @property Controller controller(){
        return Controller.byid(this.joystickid);
    }
    /// Set the Controller which generated the event.
    @property void controller(Controller controller){
        this.joystickid = controller.id;
    }
}

/// For events including joystick or controller axis data.
private template JoyAxisEventMixin(AxisType){
    alias Axis = AxisType;
    /// Get the identifier for the axis associated with the event.
    @property Axis axis() const{
        return cast(Axis) this.eventdata.axis;
    }
    /// Set the identifier for the axis associated with the event.
    @property void axis(Axis axis){
        this.eventdata.axis = cast(ubyte) axis;
    }
    /// Get the position on the axis, represented by a signed short.
    @property short positionraw() const{
        return this.eventdata.value;
    }
    /// Set the position on the axis, represented by a signed short.
    @property void positionraw(short value){
        this.eventdata.value = value;
    }
    /// Get the position on the axis, normalized to a floating point value
    /// from -1.0 to 1.0.
    @property real position() const{
        return normalizejoyaxis(this.positionraw);
    }
    /// Set the position on the axis, normalized to a floating point value
    /// from -1.0 to 1.0.
    @property void position(real value){
        this.positionraw = denormalizejoyaxis(value);
    }
}

/// For events including touch data.
template TouchEventMixin(){
    alias TouchID = SDL_TouchID;
    /// Get ID of the touch device which generated the event.
    @property TouchID touchid() const{
        return this.eventdata.touchId;
    }
    /// Set ID of the touch device which generated the event.
    @property void touchid(TouchID touchid){
        this.eventdata.touchId = touchid;
    }
}

/// For events including gesture data.
template GestureEventMixin(){
    /// All events with gesture data also include touch and position data.
    mixin TouchEventMixin;
    mixin PositionEventMixin!(`x`, `y`);
    /// Get the number of fingers used to express the gesture.
    @property auto fingers() const{
        return this.eventdata.numFingers;
    }
    /// Set the number of fingers used to express the gesture.
    @property void fingers(typeof(this.fingers()) count){
        this.eventdata.numFingers = count;
    }
}




/// https://wiki.libsdl.org/SDL_WindowEvent
struct WindowEvent{
    mixin EventMixin!SDL_WindowEvent;
    mixin WindowEventMixin;
    /// The various types of window events.
    enum Type: ubyte{
        None = SDL_WINDOWEVENT_NONE,
        Shown = SDL_WINDOWEVENT_SHOWN,
        Hidden = SDL_WINDOWEVENT_HIDDEN,
        Exposed = SDL_WINDOWEVENT_EXPOSED,
        Moved = SDL_WINDOWEVENT_MOVED,
        Resized = SDL_WINDOWEVENT_RESIZED,
        SizeChanged = SDL_WINDOWEVENT_SIZE_CHANGED,
        Minimized = SDL_WINDOWEVENT_MINIMIZED,
        Maximized = SDL_WINDOWEVENT_MAXIMIZED,
        Restored = SDL_WINDOWEVENT_RESTORED,
        Enter = SDL_WINDOWEVENT_ENTER, MouseEntered = Enter,
        Leave = SDL_WINDOWEVENT_LEAVE, MouseLeft = Leave,
        FocusGained = SDL_WINDOWEVENT_FOCUS_GAINED,
        FocusLost = SDL_WINDOWEVENT_FOCUS_LOST,
        Close = SDL_WINDOWEVENT_CLOSE, Closed = Close,
    }
    /// Get the type of the window event.
    @property Type type() const{
        return cast(Type) this.eventdata.event;
    }
    /// Set the type of the window event.
    @property void type(Type type){
        this.eventdata.event = type;
    }
    /// Get x for events having position data, width for event having size data.
    @property int data1() const{
        return this.eventdata.data1;
    }
    /// Set x for events having position data, width for event having size data.
    @property void data1(int data){
        this.eventdata.data1 = data;
    }
    /// Get y for events having position data, height for events having size data.
    @property int data2() const{
        return this.eventdata.data2;
    }
    /// Set y for events having position data, height for events having size data.
    @property void data2(int data){
        this.eventdata.data2 = data;
    }
    alias x = data1;
    alias y = data2;
    alias width = data1;
    alias height = data2;
}



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



/// https://wiki.libsdl.org/SDL_TextEditingEvent
/// https://wiki.libsdl.org/Tutorials/TextInput
struct TextEditingEvent{
    mixin EventMixin!SDL_TextEditingEvent;
    mixin TextEventMixin;
    @property int start() const{
        return this.eventdata.start;
    }
    @property void start(int start){
        this.eventdata.start = start;
    }
    @property int length() const{
        return this.eventdata.length;
    }
    @property void length(int length){
        this.eventdata.length = length;
    }
}

/// https://wiki.libsdl.org/SDL_TextInputEvent
struct TextInputEvent{
    mixin EventMixin!SDL_TextInputEvent;
    mixin TextEventMixin;
}





/// https://wiki.libsdl.org/SDL_MouseMotionEvent
struct MouseMotionEvent{
    mixin EventMixin!SDL_MouseMotionEvent;
    mixin MouseEventMixin;
    mixin PositionEventMixin!(`x`, `y`);
    mixin RelativePositionEventMixin!(`xrel`, `yrel`);
    /// Get a bitfield representing the state of mouse buttons.
    @property MouseState.Buttons buttons() const{
        return cast(MouseState.Buttons) this.eventdata.state;
    }
    /// Set the bitfield representing the state of mouse buttons.
    @property void buttons(MouseState.Buttons buttons){
        this.eventdata.state = buttons;
    }
    /// Get a MouseState object representing mouse position and button state.
    @property MouseState state() const{
        return MouseState(this.buttons, this.x, this.y);
    }
    /// Set the mouse position and button state via a MouseState object.
    @property void state(MouseState state){
        this.eventdata.state = state.buttons;
        this.eventdata.x = state.x;
        this.eventdata.y = state.y;
    }
    /// Get the state of the left mouse button associated with this event.
    @property bool left() const{return this.state.left;}
    /// Get the state of the right mouse button associated with this event.
    @property bool right() const{return this.state.right;}
    /// Get the state of the middle mouse button associated with this event.
    @property bool middle() const{return this.state.middle;}
    /// Get the state of the X1 mouse button associated with this event.
    @property bool X1() const{return this.state.X1;}
    /// Get the state of the X2 mouse button associated with this event.
    @property bool X2() const{return this.state.X2;}
}

/// https://wiki.libsdl.org/SDL_MouseButtonEvent
struct MouseButtonEvent{
    mixin EventMixin!SDL_MouseButtonEvent;
    mixin MouseEventMixin;
    mixin ButtonEventMixin!MouseButton;
    mixin PositionEventMixin!(`x`, `y`);
    /// Get the number of clicks associated with the event. 1 for single-click,
    /// 2 for double-click, etc.
    @property ubyte clicks() const{
        return this.eventdata.clicks;
    }
    /// Set the number of clicks associated with the event. 1 for single-click,
    /// 2 for double-click, etc.
    @property void clicks(ubyte clicks){
        this.eventdata.clicks = clicks;
    }
}

/// https://wiki.libsdl.org/SDL_MouseWheelEvent
struct MouseWheelEvent{
    mixin EventMixin!SDL_MouseWheelEvent;
    mixin MouseEventMixin;
    /// Get the amount scrolled horizontally.
    @property auto x() const{
        return this.xraw * this.dirmultiplier;
    }
    /// Set the amount scrolled horizontally.
    @property void x(in int x){
        this.xraw = x * this.dirmultiplier;
    }
    /// Get the amount scrolled vertically.
    @property auto y() const{
        return this.yraw * this.dirmultiplier;
    }
    /// Set the amount scrolled vertically.
    @property void y(in int y){
        this.yraw = y * this.dirmultiplier;
    }
    /// Get amount scrolled horizontally. Positive to the right, negative to the left.
    @property int xraw() const{
        return this.eventdata.x;
    }
    /// Set amount scrolled horizontally. Positive to the right, negative to the left.
    @property void xraw(int x){
        this.eventdata.x = x;
    }
    /// Get amount scrolled vertically. Positive away from the user, negative toward.
    @property int yraw() const{
        return this.eventdata.y;
    }
    /// Set amount scrolled vertically. Positive away from the user, negative toward.
    @property void yraw(int y){
        this.eventdata.y = y;
    }
    /// Get whether raw x, y are in fact inverted.
    @property MouseWheelDirection direction() const{
        return cast(MouseWheelDirection) this.eventdata.direction;
    }
    /// Set whether raw x, y are in fact inverted.
    @property void direction(MouseWheelDirection dir) const{
        this.eventdata.direction = dir;
    }
    /// Return 1 when direction is normal, -1 when flipped.
    /// Multiply xraw, yraw fields by this to get actual x, y.
    @property int dirmultiplier() const{
        return this.direction is MouseWheelDirection.Flipped ? -1 : 1;
    }
}



/// https://wiki.libsdl.org/SDL_JoyAxisEvent
struct JoyAxisEvent{
    mixin EventMixin!SDL_JoyAxisEvent;
    mixin JoyEventMixin;
    mixin JoyAxisEventMixin!ubyte;
}

/// https://wiki.libsdl.org/SDL_JoyButtonEvent
struct JoyButtonEvent{
    mixin EventMixin!SDL_JoyButtonEvent;
    mixin JoyEventMixin;
    mixin ButtonEventMixin!ubyte;
}

/// https://wiki.libsdl.org/SDL_JoyHatEvent
struct JoyHatEvent{
    mixin EventMixin!SDL_JoyHatEvent;
    mixin JoyEventMixin;
    /// Get the index of the hat switch associated with the event.
    @property Joystick.Hat.Index index() const{
        return cast(Joystick.Hat.Index) this.eventdata.hat;
    }
    /// Set the index of the hat switch associated with the event.
    @property void index(Joystick.Hat.Index index){
        this.eventdata.hat = index;
    }
    /// Get the directional state of the hat switch associated with the event.
    @property Joystick.Hat.State state() const{
        return cast(Joystick.Hat.State) this.eventdata.value;
    }
    /// Set the directional state of the hat switch associated with the event.
    @property void state(Joystick.Hat.State state){
        this.eventdata.value = state;
    }
    /// Get as a Joystick.Hat object the hat associated with the event.
    @property Joystick.Hat hat() const{
        return Joystick.Hat(this.index, this.state);
    }
    /// Set as a Joystick.Hat object the hat associated with the event.
    @property void hat(Joystick.Hat hat){
        this.index = hat.index;
        this.state = hat.state;
    }
}

/// https://wiki.libsdl.org/SDL_JoyBallEvent
struct JoyBallEvent{
    mixin EventMixin!SDL_JoyBallEvent;
    mixin JoyEventMixin;
    mixin RelativePositionEventMixin!(`xrel`, `yrel`);
    /// Get the index of the trackball associated with the event.
    @property Joystick.Ball.Index index() const{
        return cast(Joystick.Ball.Index) this.eventdata.ball;
    }
    /// Set the index of the trackball associated with the event.
    @property void index(Joystick.Ball.Index index){
        this.eventdata.ball = index;
    }
    /// Get as a Joystick.Ball object the ball associated with the event.
    @property Joystick.Ball ball() const{
        return Joystick.Ball(this.index, this.dx, this.dy);
    }
    /// Set as a Joystick.Ball object the ball associated with the event.
    @property void ball(Joystick.Ball ball){
        this.index = ball.index;
        this.dx = cast(typeof(this.dx())) ball.dx;
        this.dy = cast(typeof(this.dy())) ball.dy;
    }
}

/// https://wiki.libsdl.org/SDL_JoyDeviceEvent
struct JoyDeviceEvent{
    mixin EventMixin!SDL_JoyDeviceEvent;
    /// Assuming this is a device added event, get the device index of the
    /// added joystick.
    @property Joystick.DeviceIndex added() const{
        return cast(Joystick.DeviceIndex) this.eventdata.which;
    }
    /// Set the device index of the added joystick.
    @property void added(Joystick.DeviceIndex index){
        this.eventdata.type = Event.Type.JoyDeviceAdded;
        this.eventdata.which = index;
    }
    /// Assuming this is a device removed event, get a Joystick object
    /// representing the removed joystick.
    @property Joystick removed() const{
        return Joystick.byid(this.removedid);
    }
    /// Set the Joystick object representing the removed joystick.
    @property void removed(Joystick joystick){
        this.removedid = joystick.id;
    }
    /// Assuming this is a device removed event, get the instance id of the
    /// removed joystick.
    @property Joystick.ID removedid() const{
        return cast(Joystick.ID) this.eventdata.which;
    }
    /// Set the instance id of the removed joystick.
    @property void removedid(Joystick.ID joystickid){
        this.eventdata.type = Event.Type.JoyDeviceRemoved;
        this.eventdata.which = joystickid;
    }
}



/// https://wiki.libsdl.org/SDL_ControllerAxisEvent
struct ControllerAxisEvent{
    mixin EventMixin!SDL_ControllerAxisEvent;
    mixin ControllerEventMixin;
    mixin JoyAxisEventMixin!(Controller.Axis);
}

/// https://wiki.libsdl.org/SDL_ControllerButtonEvent
struct ControllerButtonEvent{
    mixin EventMixin!SDL_ControllerButtonEvent;
    mixin ControllerEventMixin;
    mixin ButtonEventMixin!(Controller.Button);
}

/// https://wiki.libsdl.org/SDL_ControllerDeviceEvent
struct ControllerDeviceEvent{
    mixin EventMixin!SDL_ControllerDeviceEvent;
    /// Assuming this is a device added event, get the device index of the
    /// added controller.
    @property Controller.DeviceIndex added() const{
        return cast(Controller.DeviceIndex) this.eventdata.which;
    }
    /// Set the device index of the added controller.
    @property void added(Controller.DeviceIndex index){
        this.eventdata.type = Event.Type.ControllerDeviceAdded;
        this.eventdata.which = index;
    }
    /// Assuming this is a device removed event, get a Controller object
    /// representing the removed controller.
    @property Controller removed() const{
        return Controller.byid(this.removedid);
    }
    /// Set the Controller object representing the removed controller.
    @property void removed(Controller controller){
        this.removedid = controller.id;
    }
    /// Assuming this is a device remapped event, get a Controller object
    /// representing the remapped controller.
    @property Controller remapped() const{
        return Controller.byid(this.remappedid);
    }
    /// Set the Controller object representing the remapped controller.
    @property void remapped(Controller controller){
        this.remappedid = controller.id;
    }
    /// Assuming this is a device removed event, get the instance id of the
    /// removed controller.
    @property Controller.ID removedid() const{
        return cast(Controller.ID) this.eventdata.which;
    }
    /// Set the instance id of the removed controller.
    @property void removedid(Controller.ID controllerid){
        this.eventdata.type = Event.Type.ControllerDeviceRemoved;
        this.eventdata.which = controllerid;
    }
    /// Assuming this is a device remapped event, get the instance id of the
    /// remapped controller.
    @property Controller.ID remappedid() const{
        return cast(Controller.ID) this.eventdata.which;
    }
    /// Set the instance id of the remapped controller.
    @property void remappedid(Controller.ID controllerid){
        this.eventdata.type = Event.Type.ControllerDeviceRemapped;
        this.eventdata.which = controllerid;
    }
}



/// https://wiki.libsdl.org/SDL_AudioDeviceEvent
struct AudioDeviceEvent{
    mixin EventMixin!SDL_AudioDeviceEvent;
    // TODO: There's probably a better place to put these definitions
    alias DeviceID = SDL_AudioDeviceID;
    alias DeviceIndex = int;
    /// Get whether the device is an audio capture device.
    @property bool iscapture() const{
        return this.eventdata.iscapture != 0;
    }
    /// Set whether the device is an audio capture device.
    @property void iscapture(bool capture){
        this.eventdata.iscapture = capture;
    }
    /// Assuming this is a device added event, get the device index of the
    /// added audio device.
    @property DeviceIndex added() const{
        return cast(DeviceIndex) this.eventdata.which;
    }
    /// Set the device index of the added audio device.
    @property void added(DeviceIndex index){
        this.eventdata.type = Event.Type.AudioDeviceAdded;
        this.eventdata.which = index;
    }
    /// Assuming this is a device removed event, get the instance id of the
    /// removed audio device.
    @property DeviceID removedid() const{
        return cast(DeviceID) this.eventdata.which;
    }
    /// Set the instance id of the removed audio device.
    @property void removedid(DeviceID audioid){
        this.eventdata.type = Event.Type.AudioDeviceRemoved;
        this.eventdata.which = audioid;
    }
}



/// https://wiki.libsdl.org/SDL_DropEvent
struct DropFileEvent{
    mixin EventMixin!SDL_DropEvent;
    /// The original SDL event's char* needs to be destroyed using SDL_free.
    /// If using drop events, make sure to call Event.conclude at some point
    /// (which goes on to call this method) in order to avoid memory leaks.
    void conclude(){
        SDL_free(this.eventdata.file);
    }
    /// Get the path to the file dropped.
    @property string path() const{
        return cast(string) fromStringz(this.eventdata.file);
    }
    /// TODO: What's the best way to allocate and assign a file path?
}

/// https://wiki.libsdl.org/SDL_QuitEvent
/// https://wiki.libsdl.org/SDL_EventType#SDL_QUIT
struct QuitEvent{
    mixin EventMixin!SDL_QuitEvent;
}

/// https://wiki.libsdl.org/SDL_UserEvent
struct UserEvent{
    mixin EventMixin!SDL_UserEvent;
    mixin WindowEventMixin;
    @property int code() const{
        return this.eventdata.code;
    }
    @property void code(int code){
        this.eventdata.code = code;
    }
    @property void* data1() const{
        return this.eventdata.data1;
    }
    @property void data1(void* data){
        this.eventdata.data1 = data;
    }
    @property void* data2() const{
        return this.eventdata.data2;
    }
    @property void data2(void* data){
        this.eventdata.data2 = data;
    }
}

/// https://wiki.libsdl.org/SDL_SysWindowManagerEvent
struct SysWindowManagerEvent{
    mixin EventMixin!SDL_SysWMEvent;
    @property SDL_SysWMmsg* message() const{
        return this.eventdata.msg;
    }
    @property void message(SDL_SysWMmsg* message){
        this.eventdata.msg = message;
    }
}


/// https://wiki.libsdl.org/SDL_TouchFingerEvent
struct TouchFingerEvent{
    mixin EventMixin!SDL_TouchFingerEvent;
    mixin TouchEventMixin;
    mixin PositionEventMixin!(`x`, `y`);
    mixin RelativePositionEventMixin!(`dx`, `dy`);
    alias FingerID = SDL_FingerID;
    /// Get the finger index associated with the event.
    @property FingerID fingerid() const{
        return cast(FingerID) this.eventdata.fingerId;
    }
    /// Set the finger index associated with the event.
    @property void fingerid(FingerID fingerid){
        this.eventdata.fingerId = fingerid;
    }
    /// Get the touch pressure associated with the event.
    @property float pressure() const{
        return this.eventdata.pressure;
    }
    /// Set the touch pressure associated with the event.
    @property void pressure(float pressure){
        this.eventdata.pressure = pressure;
    }
}

/// https://wiki.libsdl.org/SDL_MultiGestureEvent
struct MultiGestureEvent{
    mixin EventMixin!SDL_MultiGestureEvent;
    mixin GestureEventMixin;
    /// Get the amount of finger rotation associated with the event.
    @property float rotation() const{
        return this.eventdata.dTheta;
    }
    /// Set the amount of finger rotation associated with the event.
    @property void rotation(float rotation){
        this.eventdata.dTheta = rotation;
    }
    /// Get the amount of finger pinching associated with the event.
    @property float pinch() const{
        return this.eventdata.dDist;
    }
    /// Set the amount of finger pinching associated with the event.
    @property void pinch(float pinch){
        this.eventdata.dDist = pinch;
    }
}

/// https://wiki.libsdl.org/SDL_DollarGestureEvent
/// http://hg.libsdl.org/SDL/file/default/docs/README-gesture.md
struct DollarGestureEvent{
    mixin EventMixin!SDL_DollarGestureEvent;
    mixin GestureEventMixin;
    // TODO: There's probably a better place to define this
    alias GestureID = SDL_GestureID;
    /// Get the ID of the gesture most closely fitting the performed stroke.
    @property GestureID gestureid() const{
        return cast(GestureID) this.eventdata.gestureId;
    }
    /// Set the ID of the gesture most closely fitting the performed stroke.
    @property void gestureid(GestureID gestureid){
        this.eventdata.gestureId = gestureid;
    }
    /// Get a quantification of the difference between the gesture template and
    /// the actual performed gesture. (Lower error indicates a better match.)
    @property float error() const{
        return this.eventdata.error;
    }
    /// Set the amount of difference between the gesture template and the actual
    /// performed gesture.
    @property void error(float error){
        this.eventdata.error = error;
    }
}
