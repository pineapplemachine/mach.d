module mach.sdl.haptic.effect;

private:

import derelict.sdl2.sdl;
import mach.math : normalize, denormalize;
import mach.sdl.haptic.effecttype;
import mach.sdl.haptic.mixins;
import mach.sdl.haptic.direction;

public:



/// https://wiki.libsdl.org/SDL_HapticEffect
struct HapticEffect{
    alias Direction = HapticDirection;
    alias Type = HapticEffectType;
    
    SDL_HapticEffect effect;
    
    alias Constant = HapticConstantEffect;
    alias Periodic = HapticPeriodicEffect;
    alias Condition = HapticConditionEffect;
    alias Ramp = HapticRampEffect;
    alias LeftRight = HapticLeftRightEffect;
    alias Custom = HapticCustomEffect;
    
    @property auto constant() const{return HapticConstantEffect(cast(SDL_HapticEffect) this.effect);}
    @property auto periodic() const{return HapticPeriodicEffect(cast(SDL_HapticEffect) this.effect);}
    @property auto condition() const{return HapticConditionEffect(cast(SDL_HapticEffect) this.effect);}
    @property auto ramp() const{return HapticRampEffect(cast(SDL_HapticEffect) this.effect);}
    @property auto leftright() const{return HapticLeftRightEffect(cast(SDL_HapticEffect) this.effect);}
    @property auto custom() const{return HapticCustomEffect(cast(SDL_HapticEffect) this.effect);}
}



/// Applies a constant force to the joystick in a specified direction.
/// https://wiki.libsdl.org/SDL_HapticConstant
struct HapticConstantEffect{
    mixin HapticEffectMixin!SDL_HapticConstant;
    mixin CommonHapticEffectMixin;
    mixin EnvelopeHapticEffectMixin;
    mixin DirectionHapticEffectMixin;
    /// Get the strength of the effect.
    @property short levelraw() const{
        return this.effectdata.level;
    }
    /// Set the strength of the effect.
    @property void levelraw(short level){
        this.effectdata.level = level;
    }
    /// Get the strength of the effect as a floating point number
    /// from -1.0 to 1.0.
    @property real level() const{
        return this.levelraw.normalize;
    }
    /// Set the strength of the effect as a floating point number
    /// from -1.0 to 1.0.
    @property void level(real level){
        this.levelraw = level.denormalize!short;
    }
}



/// https://wiki.libsdl.org/SDL_HapticPeriodic
struct HapticPeriodicEffect{
    mixin HapticEffectMixin!SDL_HapticPeriodic;
    mixin CommonHapticEffectMixin;
    mixin EnvelopeHapticEffectMixin;
    mixin DirectionHapticEffectMixin;
    /// Get the period of the wave, in milliseconds.
    @property ushort period() const{
        return this.effectdata.period;
    }
    /// Set the period of the wave, in milliseconds.
    @property void period(ushort period){
        this.effectdata.period = period;
    }
    /// Get/set the peak strength of the wave.
    mixin(NormalizedHapticPropertyMixin!(`magnitude`));
    /// Get/set the mean strength of the wave.
    mixin(NormalizedHapticPropertyMixin!(`offset`));
    /// Get/set the phase shift of the wave.
    mixin(AngularHapticPropertyMixin!(`phase`));
}



/// TODO: What the fuck is this struct even
/// https://wiki.libsdl.org/SDL_HapticCondition
struct HapticConditionEffect{
    mixin HapticEffectMixin!SDL_HapticCondition;
    mixin CommonHapticEffectMixin;
    
    // The effect has a direction attribute, but it is unused.
    // https://wiki.libsdl.org/SDL_HapticCondition#direction
    //mixin DirectionHapticEffectMixin;
}



/// https://wiki.libsdl.org/SDL_HapticRamp
struct HapticRampEffect{
    mixin HapticEffectMixin!SDL_HapticRamp;
    mixin CommonHapticEffectMixin;
    mixin EnvelopeHapticEffectMixin;
    mixin DirectionHapticEffectMixin;
    /// Get/set the starting strength of the feedback.
    mixin(NormalizedHapticPropertyMixin!(`start`));
    /// Get/set the ending strength of the feedback.
    mixin(AngularHapticPropertyMixin!(`end`));
}



/// https://wiki.libsdl.org/SDL_HapticLeftRight
struct HapticLeftRightEffect{
    mixin HapticEffectMixin!SDL_HapticLeftRight;
    /// Get/set the feedback strength of the haptic device's larger motor.
    mixin(NormalizedHapticPropertyMixin!(`large`, `large_magnitude`));
    /// Get/set the feedback strength of the haptic device's smaller motor.
    mixin(AngularHapticPropertyMixin!(`small`, `small_magnitude`));
}



/// https://wiki.libsdl.org/SDL_HapticCustom
struct HapticCustomEffect{
    mixin HapticEffectMixin!SDL_HapticCustom;
    mixin CommonHapticEffectMixin;
    mixin EnvelopeHapticEffectMixin;
    mixin DirectionHapticEffectMixin;
    /// Get the number of axes for which there are samples.
    @property ubyte axes() const{
        return this.effectdata.channels;
    }
    /// Get the number of axes for which there are samples.
    @property void axes(ubyte axes){
        this.effectdata.channels = axes;
    }
    /// Get the period of each sample, in milliseconds.
    @property ushort period() const{
        return this.effectdata.period;
    }
    /// Set the period of each sample, in milliseconds.
    @property void period(ushort period){
        this.effectdata.period = period;
    }
    /// Get the number of samples per axis.
    @property ushort samples() const{
        return this.effectdata.samples;
    }
    /// Get the number of samples per axis.
    @property void samples(ushort samples){
        this.effectdata.samples = samples;
    }
    /// Get the sample data, which should be an array of length axes * samples.
    @property auto data() const{
        return this.effectdata.data;
    }
    /// Get the sample data, which should be an array of length axes * samples.
    @property void data(ushort* data){
        this.effectdata.data = data;
    }
    /// ditto
    @property void data(ushort[] data){
        this.effectdata.data = data.ptr;
    }
}
