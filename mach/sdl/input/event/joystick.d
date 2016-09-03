module mach.sdl.input.event.joystick;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;
import mach.sdl.input.event.type : EventType;
import mach.sdl.input.joystick : Joystick;

public:



/// Event triggered by joystick axis movement.
/// https://wiki.libsdl.org/SDL_JoyAxisEvent
struct JoyAxisEvent{
    mixin EventMixin!SDL_JoyAxisEvent;
    mixin JoyEventMixin;
    mixin JoyAxisEventMixin!ubyte;
}

/// Event triggered by joystick button presses.
/// https://wiki.libsdl.org/SDL_JoyButtonEvent
struct JoyButtonEvent{
    mixin EventMixin!SDL_JoyButtonEvent;
    mixin JoyEventMixin;
    mixin ButtonEventMixin!ubyte;
}

/// Event triggered by joystick hat switch movement.
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

/// Event triggered by joystick trackball movement.
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

/// Event related to joystick device changes.
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
        this.eventdata.type = EventType.JoyDeviceAdded;
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
        this.eventdata.type = EventType.JoyDeviceRemoved;
        this.eventdata.which = joystickid;
    }
}
