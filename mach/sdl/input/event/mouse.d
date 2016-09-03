module mach.sdl.input.event.mouse;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;
import mach.sdl.input.mouse : MouseState, MouseButton, MouseWheelDirection;

public:



/// Event triggered by mouse movement.
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

/// Event triggered by mouse button presses.
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

/// Event triggered by mouse wheel input.
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
