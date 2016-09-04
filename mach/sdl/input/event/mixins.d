module mach.sdl.input.event.mixins;

/// This module defines mixin templates used by the various event types.

private:

//

public:



template EventMixinAttribute(T){
    import derelict.sdl2.types;
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
template EventMixin(T){
    mixin EventMixin!(T, EventMixinAttribute!T);
}
template EventMixin(T, string attribute){
    SDL_Event* event;
    @property auto eventdata() const{
        mixin(`return cast(T) this.event.` ~ attribute ~ `;`);
    }
}



/// For events including the focused window.
template WindowEventMixin(){
    import mach.sdl.window : Window;
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
template ButtonStateEventMixin(){
    import mach.sdl.input.common : ButtonState;
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
template ButtonEventMixin(ButtonType){
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
template MouseEventMixin(){
    import mach.sdl.input.mouse : MouseID, TouchMouseID;
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
template PositionEventMixin(string xattr = `x`, string yattr = `y`){
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
template RelativePositionEventMixin(string xattr = `dx`, string yattr = `dy`){
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
template TextEventMixin(){
    import std.string : fromStringz;
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
template JoyEventMixin(){
    import mach.sdl.input.joystick : Joystick;
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
template ControllerEventMixin(){
    import mach.sdl.input.controller : Controller;
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
template JoyAxisEventMixin(AxisType){
    import mach.sdl.input.joystick : Joystick;
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
        return Joystick.normalizeaxis(this.positionraw);
    }
    /// Set the position on the axis, normalized to a floating point value
    /// from -1.0 to 1.0.
    @property void position(real value){
        this.positionraw = Joystick.denormalizeaxis(value);
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
