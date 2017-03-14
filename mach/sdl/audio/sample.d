module mach.sdl.audio.sample;

private:

import derelict.sdl2.mixer;
import derelict.sdl2.types;

import mach.math.clamp : clamp;
import mach.text.cstring : tocstring, fromcstring;
import mach.sdl.error : SDLException;
import mach.sdl.audio.fading : AudioFading;

public:



/// Samples are played on Channels. Each Channel may play one sample at a time.
/// Samples may be loaded from external audio files.
/// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_16.html#SEC16
struct Sample{
    @disable this(this);
    
    Mix_Chunk* sample;
    
    this(Mix_Chunk* sample){
        this.sample = sample;
    }
    /// Load a sample from a WAVE, AIFF, RIFF, OGG, or VOC audio file.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_19.html#SEC19
    this(in string path){
        this.sample = Mix_LoadWAV(path.tocstring);
        if(this.sample is null) throw new SDLException(
            "Failed to load audio sample from path \"" ~ path ~ "\"."
        );
    }
    /// Load a sample from memory.
    /// TODO: How should this data be formatted, exactly?
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_22.html#SEC22
    this(in ubyte[] data){
        this.sample = Mix_QuickLoad_RAW(
            cast(Uint8*) data.ptr, cast(Uint32) data.length
        );
        if(this.sample is null) throw new SDLException(
            "Failed to load audio sample from memory."
        );
    }
    
    /// Audio data is freed from memory upon destruction of the Sample object.
    ~this(){
        if(this.sample !is null) this.free();
    }
    
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_24.html#SEC24
    void free(){
        Mix_FreeChunk(this.sample);
    }

    /// Get the volume that the sample will be played at, in the range [0, 1].
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_23.html#SEC23
    @property double volume(){
        assert(this.sample !is null);
        return Mix_VolumeChunk(this.sample, -1) / cast(double) MIX_MAX_VOLUME;
    }
    /// Set the volume that the sample will be played at. Should be a value
    /// in the range [0, 1].
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_23.html#SEC23
    @property void volume(in double volume){
        assert(this.sample !is null);
        Mix_VolumeChunk(this.sample, cast(int)(clamp(volume, 0, 1) * MIX_MAX_VOLUME));
    }
    
    /// Play this audio sample on the first free unreserved channel.
    /// May throw an SDLException if the audio failed to start.
    /// Accepts an optional number of milliseconds for a fade-in effect,
    /// an optional number of times to repeat the sample (0 means play once),
    /// and an optional cutoff milliseconds.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_31.html#SEC31
    auto play(in int fadems = 0, in int repeat = 0, in int timeoutms = -1){
        auto result = Mix_FadeInChannelTimed(-1, this.sample, repeat, fadems, timeoutms);
        if(result == -1) throw new SDLException("Failed to play audio sample.");
    }
}