module mach.sdl.input.event.touch;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;

public:



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
