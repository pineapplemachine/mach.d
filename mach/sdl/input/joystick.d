module mach.sdl.input.joystick;

private:

import derelict.sdl2.sdl;

import std.traits : isSigned, isIntegral, isNumeric;
import std.string : fromStringz;
import mach.math : normalize, denormalize;
import mach.sdl.error : SDLError;
import mach.sdl.input.common : EventState;

public:



struct Joystick{
    /// Various levels of power or battery charge.
    static enum Power{
        Unknown = SDL_JOYSTICK_POWER_UNKNOWN,
        Empty = SDL_JOYSTICK_POWER_EMPTY,
        Low = SDL_JOYSTICK_POWER_LOW,
        Medium = SDL_JOYSTICK_POWER_MEDIUM,
        Full = SDL_JOYSTICK_POWER_FULL,
        Wired = SDL_JOYSTICK_POWER_WIRED,
        Max = SDL_JOYSTICK_POWER_MAX,
    }
    
    /// Indicates the state of a trackball on a joystick.
    /// https://wiki.libsdl.org/SDL_JoystickGetBall
    static struct Ball{
        alias Index = ubyte;
        Index index; /// The index of the trackball.
        int dx; /// Change in x relative to last update.
        int dy; /// Change in y relative to last update.
    }
    
    /// https://wiki.libsdl.org/SDL_JoystickGetHat
    static struct Hat{
        alias Index = ubyte;
        alias State = typeof(SDL_HAT_CENTERED);
        
        static enum Mask{
            Centered = SDL_HAT_CENTERED,
            Left = SDL_HAT_LEFT,
            Right = SDL_HAT_RIGHT,
            Up = SDL_HAT_UP,
            Down = SDL_HAT_DOWN,
        }
        
        Index index; /// The index of the hat switch.
        State state; /// The raw state of the hat switch.
        
        this(X, Y)(X index, Y state){
            this.index = cast(Index) index;
            this.state = cast(State) state;
        }
        
        private template StatePropertyMixin(Mask mask){
            @property bool ButtonMaskPropertyMixin() const{
                return (this.state & mask) != 0;
            }
            @property void ButtonMaskPropertyMixin(bool active){
                if(active) this.state |= mask;
                else this.state &= ~mask;
            }
        }
        
        /// Whether the hat is centered.
        alias centered = StatePropertyMixin!(Mask.Centered);
        /// Whether the hat is tilted left.
        alias left = StatePropertyMixin!(Mask.Left);
        /// Whether the hat is tilted right.
        alias right = StatePropertyMixin!(Mask.Right);
        /// Whether the hat is tilted up.
        alias up = StatePropertyMixin!(Mask.Up);
        /// Whether the hat is tilted down.
        alias down = StatePropertyMixin!(Mask.Down);
    }
    
    alias ID = SDL_JoystickID;
    alias DeviceIndex = int;
    alias GUID = SDL_JoystickGUID;
    alias Joy = SDL_Joystick*; /// In fact a pointer to an empty struct
    
    Joy joy;
    
    this(Joy joy){
        this.joy = joy;
    }
    
    /// Joystick and controller axis positions are represented by signed shorts.
    /// This function can be used to normalize these values to a floating point
    /// from -1.0 to 1.0.
    static real normalizeaxis(short value) pure @safe @nogc nothrow{
        return normalize!real(value);
    }
    static short denormalizeaxis(real value) pure @safe @nogc nothrow{
        return denormalize!short(value);
    }
    
    /// Get the number of attached joystick devices.
    static auto count(){
        auto count = SDL_NumJoysticks();
        if(count < 0) throw new SDLError("Failed to get number of joysticks.");
        return count;
    }
    
    /// Set whether joystick event polling is enabled or disabled. If events are
    /// disabled then Joystick.update must be called in order to update joystick
    /// state information.
    @property static void events(EventState state){
        auto result = SDL_JoystickEventState(state);
        if(result < 0) throw new SDLError("Failed to set joystick event state.");
    }
    /// Update state information for open joysticks. If event polling is enabled
    /// for joysticks then it is not necessary to call this function.
    static void update(){
        SDL_JoystickUpdate();
    }
    
    /// Get the name of a joystick given its device index.
    static string name(DeviceIndex index){
        auto name = SDL_JoystickNameForIndex(index);
        if(name is null) throw new SDLError("Failed to get joystick name.");
        return cast(string) fromStringz(name).dup;
    }
    /// Get the name of an opened joystick.
    string name(){
        auto name = SDL_JoystickName(this.joy);
        if(name is null) throw new SDLError("Failed to get joystick name.");
        return cast(string) fromStringz(name).dup;
    }
    
    /// Get the GUID of a joystick given its device index.
    /// https://wiki.libsdl.org/SDL_JoystickGetDeviceGUID
    static GUID guid(DeviceIndex index){
        return cast(GUID) SDL_JoystickGetDeviceGUID(index);
    }
    /// Get the GUID of an opened joystick.
    GUID guid(){
        return cast(GUID) SDL_JoystickGetGUID(this.joy);
    }
    
    /// Get the instance ID of an open joystick.
    @property ID id(){
        auto id = SDL_JoystickInstanceID(this.joy);
        if(id < 0) throw new SDLError("Failed to get joystick instance id.");
        return id;
    }
    /// Get a joystick by its instance ID.
    static typeof(this) byid(ID id){
        auto joy = SDL_JoystickFromInstanceID(id);
        if(joy is null) throw new SDLError("Failed to get joystick from instance id.");
        return typeof(this)(joy);
    }
    
    /// Open a joystick for use given its device index.
    static auto open(DeviceIndex index){
        auto joy = SDL_JoystickOpen(index);
        if(joy is null) throw new SDLError("Failed to open joystick.");
        return typeof(this)(joy);
    }
    /// Whether the joystick is open.
    @property bool isopen(){
        return cast(bool) SDL_JoystickGetAttached(this.joy);
    }
    /// Close a previously opened joystick.
    void close(){
        SDL_JoystickClose(this.joy);
    }
    
    /// Get the power or battery level of an opened joystick.
    @property Power power(){
        return cast(Power) SDL_JoystickCurrentPowerLevel(this.joy);
    }
    
    /// Get the number of axes on a joystick.
    @property int axes(){
        auto axes = SDL_JoystickNumAxes(this.joy);
        if(axes < 0) throw new SDLError("Failed to get number of joystick axes.");
        return axes;
    }
    /// Get the number of buttons on a joystick.
    @property int buttons(){
        auto buttons = SDL_JoystickNumButtons(this.joy);
        if(buttons < 0) throw new SDLError("Failed to get number of joystick buttons.");
        return buttons;
    }
    /// Get the number of hats on a joystick.
    @property int hats(){
        auto hats = SDL_JoystickNumHats(this.joy);
        if(hats < 0) throw new SDLError("Failed to get number of joystick hats.");
        return hats;
    }
    /// Get the number of trackballs on a joystick.
    @property int balls(){
        auto balls = SDL_JoystickNumBalls(this.joy);
        if(balls < 0) throw new SDLError("Failed to get number of joystick balls.");
        return balls;
    }
    
    /// Get the current position of an axis, from -1.0 to 1.0. For most
    /// joysticks, index 0 is x and index 1 is y. Many joysticks offer still
    /// more axes.
    /// https://wiki.libsdl.org/SDL_JoystickGetAxis
    @property auto axis(int index){
        return this.normalizeaxis(this.axisraw(index));
    }
    /// Get axis position as a signed short.
    @property auto axisraw(int index){
        return SDL_JoystickGetAxis(this.joy, index);
    }
    /// Get whether a button is currently pressed.
    @property bool button(int index){
        return SDL_JoystickGetButton(this.joy, index) == 1;
    }
    /// Get the current state of a POV hat on a joystick.
    /// https://wiki.libsdl.org/SDL_JoystickGetHat
    @property Hat hat(int index){
        return Hat(index, SDL_JoystickGetHat(this.joy, index));
    }
    /// Get the relative motion of a trackball since the last call.
    /// https://wiki.libsdl.org/SDL_JoystickGetBall
    @property Ball ball(int index){
        Ball ball;
        auto result = SDL_JoystickGetBall(this.joy, index, &ball.dx, &ball.dy);
        if(result != 0) throw new SDLError("Failed to get joystick trackball change.");
        ball.index = cast(ball.Index) index;
        return ball;
    }
}
