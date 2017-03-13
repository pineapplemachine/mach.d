module mach.sdl.haptic.haptic;

private:

import derelict.sdl2.sdl;

import mach.text.cstring : fromcstring;
import mach.sdl.error : SDLException;
import mach.sdl.input.joystick;
import mach.sdl.input.controller;
import mach.sdl.haptic.effect;

public:



struct Haptic{
    alias Effect = HapticEffect;
    alias EffectID = int;
    alias DeviceIndex = Joystick.DeviceIndex;
    alias Hap = SDL_Haptic*; /// In fact a pointer to an empty struct
    
    Hap hap;
    
    this(Hap hap){
        this.hap = hap;
    }
    
    static auto open(Controller controller){
        return typeof(this).open(controller.joystick);
    }
    static auto open(Joystick joystick){
        return typeof(this).open(joystick.joy);
    }
    static auto open(Controller.Ctrl ctrl){
        return typeof(this).open(Controller.ctrljoy(ctrl));
    }
    /// https://wiki.libsdl.org/SDL_HapticOpenFromJoystick
    static auto open(Joystick.Joy joy){
        auto hap = SDL_HapticOpenFromJoystick(joy);
        if(hap is null) throw new SDLException("Failed to open haptic device.");
        return typeof(this)(hap);
    }
    /// https://wiki.libsdl.org/SDL_HapticOpen
    static auto open(DeviceIndex index){
        auto hap = SDL_HapticOpen(index);
        if(hap is null) throw new SDLException("Failed to open haptic device.");
        return typeof(this)(hap);
    }
    /// https://wiki.libsdl.org/SDL_HapticOpenFromMouse
    static auto openmouse(){
        auto hap = SDL_HapticOpenFromMouse();
        if(hap is null) throw new SDLException("Failed to open haptic device.");
        return typeof(this)(hap);
    }
    /// https://wiki.libsdl.org/SDL_HapticOpened
    @property bool isopen(){
        return this.deviceisopen(this.deviceindex);
    }
    /// https://wiki.libsdl.org/SDL_HapticOpened
    static bool deviceisopen(DeviceIndex index){
        return cast(bool) SDL_HapticOpened(index);
    }
    /// https://wiki.libsdl.org/SDL_HapticClose
    void close(){
        SDL_HapticClose(this.hap);
    }
    
    /// https://wiki.libsdl.org/SDL_HapticIndex
    @property int deviceindex(){
        auto result = SDL_HapticIndex(this.hap);
        if(result < 0) throw new SDLException("Failed to get index of haptic device.");
        return result;
    }
    
    /// Get the name of a haptic device.
    /// https://wiki.libsdl.org/SDL_HapticName
    string devicename(DeviceIndex index){
        auto result = SDL_HapticName(index);
        if(result is null) throw new SDLException("Failed to get haptic device name.");
        return result.fromcstring;
    }
    /// ditto
    @property string name(){
        return this.devicename(this.deviceindex);
    }
    
    /// Get the number of haptic axes the device has.
    /// https://wiki.libsdl.org/SDL_HapticNumAxes
    @property int axes(){
        auto result = SDL_HapticNumAxes(this.hap);
        if(result < 0) throw new SDLException("Failed to get number of haptic axes.");
        return result;
    }
    
    /// Registers a new effect with the haptic device.
    /// Returns an ID which is used to later run, update, or remove that effect.
    /// https://wiki.libsdl.org/SDL_HapticNewEffect
    EffectID addeffect(Effect effect){
        return this.addeffect(&effect.effect);
    }
    /// ditto
    EffectID addeffect(SDL_HapticEffect* effect){
        auto result = SDL_HapticNewEffect(this.hap, effect);
        if(result < 0) throw new SDLException("Failed to add new haptic effect.");
        return result;
    }
    /// Will stop the effect if it's running.
    /// Effects are automatically destroyed when the haptic device is closed.
    /// https://wiki.libsdl.org/SDL_HapticDestroyEffect
    void removeeffect(EffectID effectid){
        SDL_HapticDestroyEffect(this.hap, effectid);
    }
    /// Update the data for a previously added effect.
    /// https://wiki.libsdl.org/SDL_HapticUpdateEffect
    void updateeffect(EffectID effectid, Effect effect){
        this.updateeffect(effectid, &effect.effect);
    }
    /// ditto
    void updateeffect(EffectID effectid, SDL_HapticEffect* effect){
        auto result = SDL_HapticUpdateEffect(this.hap, effectid, effect);
        if(result != 0) throw new SDLException("Failed to update haptic effect.");
    }
    /// Runs an effect which has been registered with the device.
    /// https://wiki.libsdl.org/SDL_HapticRunEffect
    void runeffect(EffectID effectid, uint iterations = 1){
        auto result = SDL_HapticRunEffect(this.hap, effectid, iterations);
        if(result != 0) throw new SDLException("Failed to run haptic effect.");
    }
    /// Get the maximum number of effects the haptic device is able to store.
    /// On some platforms this isn't fully supported but is an approximation.
    /// https://wiki.libsdl.org/SDL_HapticNumEffects
    int maxeffects(){
        auto result = SDL_HapticNumEffects(this.hap);
        if(result < 0) throw new SDLException("Failed to get haptic supported effect count.");
        return result;
    }
    /// Get the maximum number of effects the device is able to play at the
    /// same time. Not guaranteed to be accurate on all platforms.
    int maxplayingeffects(){
        auto result = SDL_HapticNumEffectsPlaying(this.hap);
        if(result < 0) throw new SDLException("Failed to get haptic playing effect count.");
        return result;
    }
    /// https://wiki.libsdl.org/SDL_HapticNumEffectsPlaying
    /// Determine whether an effect is supported by the haptic device.
    /// https://wiki.libsdl.org/SDL_HapticEffectSupported
    bool supportseffect(Effect effect){
        return this.supportseffect(&effect.effect);
    }
    /// ditto
    bool supportseffect(SDL_HapticEffect* effect){
        auto result = SDL_HapticEffectSupported(this.hap, effect);
        if(result < 0) throw new SDLException("Failed to check haptic effect support.");
        return cast(bool) result;
    }
    /// Get whether the given effect is currently playing.
    /// https://wiki.libsdl.org/SDL_HapticGetEffectStatus
    bool playingeffect(EffectID effectid){
        auto result = SDL_HapticGetEffectStatus(this.hap, effectid);
        if(result < 0) throw new SDLException("Failed to get haptic effect status.");
        return cast(bool) result;
    }
    
    /// Get whether the haptic device supports simple rumble playback.
    /// SDL_HapticRumbleSupported
    @property bool supportsrumble(){
        auto result = SDL_HapticRumbleSupported(this.hap);
        if(result < 0) throw new SDLException("Failed to get haptic rumble support.");
        return cast(bool) result;
    }
    /// Initialize simple rumble playback.
    /// Must be called before playrumble.
    /// https://wiki.libsdl.org/SDL_HapticRumbleInit
    void initrumble(){
        auto result = SDL_HapticRumbleInit(this.hap);
        if(result != 0) throw new SDLException("Failed to initialize haptic device rumble.");
    }
    /// Run a simple rumble effect with the given strength and duration, the
    /// latter measured in milliseconds.
    /// https://wiki.libsdl.org/SDL_HapticRumblePlay
    void playrumble(float strength, uint length){
        auto result = SDL_HapticRumblePlay(this.hap, strength, length);
        if(result != 0) throw new SDLException("Failed to play haptic device rumble.");
    }
    /// Stop a running rumble effect.
    /// https://wiki.libsdl.org/SDL_HapticRumbleStop
    void stoprumble(){
        auto result = SDL_HapticRumbleStop(this.hap);
        if(result != 0) throw new SDLException("Failed to stop haptic device rumble.");
    }
    
    /// Adding or modifying effects while the device is paused may cause errors.
    /// https://wiki.libsdl.org/SDL_HapticPause
    void pause(){
        auto result = SDL_HapticPause(this.hap);
        if(result != 0) throw new SDLException("Failed to pause haptic device.");
    }
    /// https://wiki.libsdl.org/SDL_HapticUnpause
    void unpause(){
        auto result = SDL_HapticUnpause(this.hap);
        if(result != 0) throw new SDLException("Failed to unpause haptic device.");
    }
}



