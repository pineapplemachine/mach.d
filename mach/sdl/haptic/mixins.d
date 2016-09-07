module mach.sdl.haptic.mixins;

private:

import derelict.sdl2.sdl;

public:



template HapticEffectMixinAttribute(T){
    import derelict.sdl2.types;
    static if(is(T == SDL_HapticConstant)) enum HapticEffectMixinAttribute = `constant`;
    else static if(is(T == SDL_HapticPeriodic)) enum HapticEffectMixinAttribute = `periodic`;
    else static if(is(T == SDL_HapticCondition)) enum HapticEffectMixinAttribute = `condition`;
    else static if(is(T == SDL_HapticRamp)) enum HapticEffectMixinAttribute = `ramp`;
    else static if(is(T == SDL_HapticLeftRight)) enum HapticEffectMixinAttribute = `leftright`;
    else static if(is(T == SDL_HapticCustom)) enum HapticEffectMixinAttribute = `custom`;
    else static assert(false, "Unrecognized SDL_HapticEffect type.");
}
template HapticEffectMixin(T){
    mixin HapticEffectMixin!(T, HapticEffectMixinAttribute!T);
}
template HapticEffectMixin(T, string attribute){
    import derelict.sdl2.types;
    import mach.sdl.haptic.effecttype : HapticEffectType;
    
    alias Button = ushort;
    alias Interval = ushort;
    alias Length = uint;
    static enum Length Infinite = SDL_HAPTIC_INFINITY;
    static enum Length MaxLength = 32767;
    
    SDL_HapticEffect effect;
    @property auto effectdata() const{
        mixin(`return cast(T) this.effect.` ~ attribute ~ `;`);
    }
    
    /// Get the duration of the effect in milliseconds.
    @property Length length() const{
        return this.effectdata.length;
    }
    /// Set the duration of the effect in milliseconds.
    @property void length(Length length) in{
        // https://wiki.libsdl.org/SDL_HapticEffect#Remarks
        assert(
            (
                // Must either be infinite, or less than or equal to 32767
                (length >= 0 && length <= MaxLength) ||
                // Ramp effects don't support infinite duration
                (length == Infinite && this.effectdata.type !is HapticEffectType.Ramp)
            ),
            "Invalid length for this effect type."
        );
    }body{
        this.effectdata.length = length;
    }
}

/// For every effect but SDL_HapticLeftRight, inexplicably.
template CommonHapticEffectMixin(){
    /// Get the delay before starting the effect in milliseconds.
    @property auto delay() const{
        return this.effectdata.delay;
    }
    /// Set the delay before starting the effect in milliseconds.
    @property void delay(typeof(this.delay()) delay){
        this.effectdata.delay = delay;
    }
    /// Get the button which triggers the effect.
    /// Button triggers may not be supported on all devices.
    /// It is advised not to use them if possible.
    /// Buttons start at index 1 instead of index 0 like the joystick.
    /// https://wiki.libsdl.org/SDL_HapticEffect#Remarks
    @property Button button() const{
        return this.effectdata.button;
    }
    /// Set the button which triggers the effect.
    @property void button(Button button){
        this.effectdata.button = button;
    }
    /// Get the minimum number of milliseconds between consecutive triggerings
    /// of this effect.
    @property Interval interval() const{
        return this.effectdata.interval;
    }
    /// Set the minimum number of milliseconds between consecutive triggerings
    /// of this effect.
    @property void interval(Interval interval){
        this.effectdata.interval = interval;
    }
}

/// For effects with envelope information.
template EnvelopeHapticEffectMixin(){
    alias AttackLength = ushort;
    alias AttackLevel = ushort;
    alias FadeLength = ushort;
    alias FadeLevel = ushort;
    /// Get duration of the fade in, in milliseconds.
    @property AttackLength attacklength() const{
        return this.effectdata.attack_length;
    }
    /// Set duration of the fade in, in milliseconds.
    @property void attacklength(AttackLength attacklength){
        this.effectdata.attack_length = attacklength;
    }
    /// Get the level at the start of the fade-in.
    @property AttackLevel attacklevel() const{
        return this.effectdata.attack_level;
    }
    /// Set the level at the start of the fade-in.
    @property void attacklevel(AttackLevel attacklevel){
        this.effectdata.attack_level = attacklevel;
    }
    /// Get the duration of the fade out, in milliseconds.
    @property FadeLength fadelength() const{
        return this.effectdata.fade_length;
    }
    /// Set the duration of the fade out, in milliseconds.
    @property void fadelength(FadeLength fadelength){
        this.effectdata.fade_length = fadelength;
    }
    /// Get the level at the end of the fade-out.
    @property FadeLevel fadelevel() const{
        return this.effectdata.fade_level;
    }
    /// Set the level at the end of the fade-out.
    @property void fadelevel(FadeLevel fadelevel){
        this.effectdata.fade_level = fadelevel;
    }
}

/// For effects with direction information.
template DirectionHapticEffectMixin(){
    import mach.sdl.haptic.direction : HapticDirection;
    @property HapticDirection direction() const{
        return HapticDirection(this.effectdata.direction);
    }
    @property void direction(HapticDirection direction){
        this.direction(direction.dir);
    }
    @property void direction(SDL_HapticDirection direction){
        this.effectdata.direction = direction;
    }
}



string NormalizedHapticPropertyMixin(string property)(){
    return NormalizedHapticPropertyMixin!(property, property)();
}
string NormalizedHapticPropertyMixin(string property, string attribute)(){
    return `
        @property auto ` ~ property ~ `raw() const{
            return this.effectdata.` ~ attribute ~ `;
        }
        @property void ` ~ property ~ `raw(typeof(this.` ~ property ~ `raw()) value){
            this.effectdata.` ~ attribute ~ ` = value;
        }
        @property real ` ~ property ~ `() const{
            return this.` ~ property ~ `raw.normalize;
        }
        @property void ` ~ property ~ `(real value){
            this.` ~ property ~ `raw = value.denormalize!(
                typeof(this.` ~ property ~ `raw())
            );
        }
    `;
}



string AngularHapticPropertyMixin(string property)(){
    return AngularHapticPropertyMixin!(property, property)();
}
string AngularHapticPropertyMixin(string property, string attribute)(){
    return `
        import mach.sdl.haptic.hdegrees;
        @property auto ` ~ property ~ `raw() const{
            return this.effectdata.` ~ attribute ~ `;
        }
        @property void ` ~ property ~ `raw(typeof(this.` ~ property ~ `raw()) value){
            this.effectdata.` ~ attribute ~ ` = value;
        }
        @property real ` ~ property ~ `deg() const{
            return this.` ~ property ~ `raw.hdegtodeg;
        }
        @property void ` ~ property ~ `deg(real degrees){
            this.` ~ property ~ `raw = degrees.degtohdeg!(
                typeof(this.` ~ property ~ `raw())
            );
        }
        @property real ` ~ property ~ `rad() const{
            return this.` ~ property ~ `raw.hdegtorad;
        }
        @property void ` ~ property ~ `rad(real radians){
            this.` ~ property ~ `raw = radians.radtohdeg!(
                typeof(this.` ~ property ~ `raw())
            );
        }
    `;
}


