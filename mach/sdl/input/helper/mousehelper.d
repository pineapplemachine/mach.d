module mach.sdl.input.helper.mousehelper;

private:

import derelict.sdl2.sdl;

import mach.math : Vector2;
import mach.sdl.input.event.event;
import mach.sdl.input.mouse : Mouse;
import mach.sdl.input.helper.history;

public:



/// Processes polled events to generate a data structure convenient for checking
/// mouse input.
struct MouseHelper(size_t historylength = 3){
    alias Button = Mouse.Button;
    
    alias History = EventHistoryAggregation!(Button, historylength, int, false);
    
    History history; /// For tracking button press and release history.
    int x; /// The most recent x position of the mouse.
    int y; /// The most recent y position of the mouse.
    int scrollx; /// How much the mouse wheel has been scroller on the x axis.
    int scrolly; /// How much the mouse wheel has been scroller on the y axis.
    
    /// Get mouse position as a vector.
    @property auto position() const{
        return Vector2!int(this.x, this.y);
    }
    /// Set position as a vector.
    /// Position is relative to the window.
    @property void position(Vector2!int vector){
        this.x = vector.x;
        this.y = vector.y;
        Mouse.warp(vector.x, vector.y);
    }
    
    /// Get mouse wheel scroll as a vector.
    @property auto scroll() const{
        return Vector2!int(this.scrollx, this.scrolly);
    }
    
    /// Update state when there were no polled events.
    void update(){
        this.history.update(SDL_GetTicks());
        this.updatemod();
    }
    /// Update state according to a polled event.
    /// Events should always be received in chronological order.
    void update(Event event){
        if(event.type is event.Type.MouseButtonDown){
            this.history.update(
                event.timestamp, event.button, History.State.Pressed
            );
            this.x = event.mousex;
            this.y = event.mousey;
        }else if(event.type is event.Type.MouseButtonUp){
            this.history.update(
                event.timestamp, event.button, History.State.Released
            );
            this.x = event.mousex;
            this.y = event.mousey;
        }else if(event.type is event.Type.MouseMotion){
            this.x = event.mousex;
            this.y = event.mousey;
        }else if(event.type is event.Type.MouseWheel){
            this.scrollx = event.mousewheel.x;
            this.scrolly = event.mousewheel.y;
        }
        this.updatemod();
    }
    /// Update given a mouse state. Clears all prior history.
    /// Really only intended for running at initialization.
    void update(in Mouse.State state){
        this.history.clear();
        this.position = state.position;
        foreach(button; [Button.Left, Button.Right, Button.Middle, Button.X1, Button.X2]){
            if(state.pressed(button)) this.history.add(button, History.State.Pressed, state.position);
        }
    }
    
    /// Get whether a button is currently being held down.
    bool down(in Button button) const{return this.history.down(button);}
    /// Get whether a button is not currently being held down.
    bool up(in Button button) const{return this.history.up(button);}
    /// Get whether a button was just pressed.
    auto pressed(in Button button) const{return this.pressed(button);}
    /// Get whether a button was just released.
    auto released(in Button button) const{return this.released(button);}
    /// Get the number of milliseconds since a button was last pressed.
    auto pressedtime(in Button button) const{return this.pressedtime(button);}
    /// Get the number of milliseconds since a button was last released.
    auto releasedtime(in Button button) const{return this.releasedtime(button);}
    /// Get the most recently pressed button.
    auto lastpressed(in Button button) const{return this.history.lastpressed(button);}
    /// Get the most recently released button.
    auto lastreleased(in Button button) const{return this.history.lastreleased(button);}
    /// Get whether a button was just double-pressed, triple-pressed, etc. as
    /// determined by the count. Accepts a maxmimum number of milliseconds
    /// between presses.
    auto npressed(in Button button, size_t count, in Timestamp time = History.DefaultTapInterval){
        return this.history.npressed(button, count, interval);
    }
    /// Get whether a button was just double-pressed.
    auto doublepressed(in Button button, in Timestamp time = History.DefaultTapInterval){
        return this.history.doublepressed(button, interval);
    }
    /// Get whether a button was just triple-pressed.
    auto triplepressed(in Button button, in Timestamp interval = History.DefaultTapInterval){
        return this.history.triplepressed(button, interval);
    }
    /// Get whether a button was just pressed and then released, with the whole
    /// enterprise taking no more than the provided number of milliseconds.
    auto tapped(in Button button, in Timestamp time = History.DefaultTapInterval){
        return this.history.tapped(button, interval);
    }
}
