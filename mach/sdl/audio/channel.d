module mach.sdl.audio.channel;

private:

import derelict.sdl2.mixer;
import derelict.sdl2.types;

import mach.math.clamp : clamp;
import mach.text.cstring : tocstring, fromcstring;
import mach.sdl.error : SDLException;
import mach.sdl.audio.fading : AudioFading;
import mach.sdl.audio.sample : MixSample;

public:



/// Samples are played on Channels. Each Channel may play one sample at a time.
/// Channels must be allocated ahead of time using e.g. `Channel.count = 16;`.
/// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_25.html#SEC25
struct MixChannel{
    alias Fading = AudioFading;
    alias FinishedCallback = extern(C) void function(int channel);
    
    int channel;
    
    this(in int channel){
        assert(channel >= 0);
        this.channel = channel;
    }
    
    static typeof(this) opIndex(in int channel){
        return typeof(this)(channel);
    }
    
    /// Set the number of mixing channels.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_26.html#SEC26
    static @property void count(in int count){
        Mix_AllocateChannels(count);
    }
    /// Get the number of currently-allocated mixing channels.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_26.html#SEC26
    static @property int count(){
        return Mix_AllocateChannels(-1);
    }
    
    /// Get the volume that the channel will play samples at, in the range [0, 1].
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_27.html#SEC27
    @property double volume(){
        return Mix_Volume(this.channel, -1) / cast(double) MIX_MAX_VOLUME;
    }
    /// Set the volume that the channel will play samples at. Should be a value
    /// in the range [0, 1].
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_27.html#SEC27
    @property void volume(in double volume){
        Mix_Volume(this.channel, cast(int)(clamp(volume, 0, 1) * MIX_MAX_VOLUME));
    }
    
    /// Set the volume that all channels will play samples at. Should be a value
    /// in the range [0, 1].
    /// Affects only channels that have currently been allocated; does not set
    /// a default value for channels allocated after this call.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_27.html#SEC27
    static @property void allvolume(in double volume){
        Mix_Volume(-1, cast(int)(clamp(volume, 0, 1) * MIX_MAX_VOLUME));
    }
    
    /// Play an audio sample on this channel.
    /// May throw an SDLException if the audio failed to start.
    /// Accepts an optional number of milliseconds for a fade-in effect,
    /// an optional number of times to repeat the sample (0 means play once),
    /// and an optional cutoff milliseconds.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_31.html#SEC31
    auto play(Mix_Chunk* sample, in int fadeinms = 0, in int repeat = 0, in int timeoutms = -1){
        auto result = Mix_FadeInChannelTimed(this.channel, sample, repeat, fadeinms, timeoutms);
        if(result == -1) throw new SDLException("Failed to play audio sample.");
    }
    /// Ditto
    auto play(MixSample sample, in int fadeinms = 0, in int repeat = 0, in int timeoutms = -1){
        this.play(sample.sample, fadeinms, repeat, timeoutms);
    }
    
    /// Pause the channel.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_32.html#SEC32
    void pause() const{
        Mix_Pause(this.channel);
    }
    /// Pause all channels.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_32.html#SEC32
    static void pauseall(){
        Mix_Pause(-1);
    }
    
    /// Resume the channel.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_33.html#SEC33
    void resume() const{
        Mix_Resume(this.channel);
    }
    /// Resume all channels.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_33.html#SEC33
    static void resumeall(){
        Mix_Resume(-1);
    }
    
    /// Get whether the channel is playing, without consideration for whether
    /// it's been paused.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_38.html#SEC38
    @property bool active() const{
        return cast(bool) Mix_Playing(this.channel);
    }
    /// Get whether the channel has been paused.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_39.html#SEC39
    @property bool paused() const{
        return cast(bool) Mix_Paused(this.channel);
    }
    /// Get whether the channel is audible, i.e. active and not paused.
    @property bool playing() const{
        return this.active && !this.paused;
    }
    
    /// Get whether the channel is currently fading in, out, or not fading at all.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_40.html#SEC40
    @property Fading fading(){
        // Docs: "-1 is not valid, and will probably crash the program."
        assert(this.channel > 0);
        return cast(Fading) Mix_FadingChannel(this.channel);
    }
    
    /// Immediately halt the channel.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_34.html#SEC34
    void stop() const{
        Mix_HaltChannel(this.channel);
    }
    /// Halt the channel after some number of milliseconds.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_35.html#SEC35
    void stop(in int waitms) const{
        Mix_ExpireChannel(this.channel, waitms);
    }
    /// Immediately halt all channels.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_34.html#SEC34
    static void stopall(){
        Mix_HaltChannel(-1);
    }
    
    /// Fade out audio on this channel over a given period of milliseconds.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_36.html#SEC36
    void fadeout(in int fadems) const{
        Mix_FadeOutChannel(this.channel, fadems);
    }
    /// Fade out audio on all channels over a given period of milliseconds.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_36.html#SEC36
    static void fadeoutall(in int fadems){
        Mix_FadeOutChannel(-1, fadems);
    }
    
    /// Get the sample that was most recently played on this channel.
    /// Will return null if the channel hasn't been allocated, or if the
    /// channel has not yet played any samples.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_41.html#SEC41
    @property MixSample lastplayed() const{
        return MixSample(Mix_GetChunk(this.channel));
    }
    
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_37.html#SEC37
    static @property void onfinished(FinishedCallback callback){
        Mix_ChannelFinished(callback);
    }
}
