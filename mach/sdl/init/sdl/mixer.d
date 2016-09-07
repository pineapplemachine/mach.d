module mach.sdl.init.sdl.mixer;

private:

import derelict.sdl2.types;
import derelict.sdl2.mixer;
import mach.sdl.error : SDLError;
import mach.sdl.flags;

public:



/// TODO: I can probably get better functionality with OpenAL
/// https://www.libsdl.org/projects/SDL_mixer/
struct Mixer{
    static load(){DerelictSDL2Mixer.load();}
    static unload(){DerelictSDL2Mixer.unload();}
    
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_9.html
    static enum Format: int{
        None = 0,
        FLAC = MIX_INIT_FLAC,
        MOD = MIX_INIT_MOD,
        MODPlug = MIX_INIT_MODPLUG,
        MP3 = MIX_INIT_MP3,
        OGG = MIX_INIT_OGG,
        FluidSynth = MIX_INIT_FLUIDSYNTH,
        All = FLAC | MOD | MODPlug | MP3 | OGG | FluidSynth,
        Default = MP3 | OGG,
    }
    
    /// Wraps a bitmask of audio format options with helpful methods.
    alias Formats = BitFlagAggregate!(int, Format);
    
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_9.html
    static void initialize(Formats formats){
        int result = Mix_Init(formats.flags);
        if((result & formats.flags) != formats.flags){
            throw new SDLError("Failed to initialize mixer library.");
        }
    }
    /// Get which formats have so far been successfully initialized.
    static Formats initialized(){
        return Formats(Mix_Init(0));
    }
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_10.html
    static void quit(){
        while(Mix_Init(0)) Mix_Quit();
    }
    
    static struct Audio{
        /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_11.html
        static enum Channels : int {
            Default = MIX_DEFAULT_CHANNELS,
            Mono = 1,
            Stereo = 2
        }
        /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_11.html
        static enum Format : ushort {
            Default = MIX_DEFAULT_FORMAT,
            U8 = AUDIO_U8,
            S8 = AUDIO_S8,
            U16LSB = AUDIO_U16LSB,
            S16LSB = AUDIO_S16LSB,
            U16MSB = AUDIO_U16MSB,
            S16MSB = AUDIO_S16MSB,
            U16 = AUDIO_U16,
            S16 = AUDIO_S16,
            U16SYS = AUDIO_U16SYS,
            S16SYS = AUDIO_S16SYS,
        }
        alias Frequency = int;
        alias ChunkSize = int;
        static enum Frequency DefaultFrequency = MIX_DEFAULT_FREQUENCY;
        static enum ChunkSize DefaultChunkSize = 256;
        
        Frequency frequency = DefaultFrequency;
        Format format = Format.Default;
        Channels channels = Channels.Default;
        ChunkSize chunksize = DefaultChunkSize;
        
        /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_11.html
        void open() const{
            auto result = Mix_OpenAudio(this.frequency, this.format, this.channels, this.chunksize);
            if(result != 0) throw new SDLError("Failed to open audio.");
        }
        /// Get the number of times that open has been called.
        static int countopen(){
            int a; ushort b; int c;
            return Mix_QuerySpec(&a, &b, &c);
        }
        /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_15.html
        static typeof(this) query(){
            typeof(this) audio;
            auto result = Mix_QuerySpec(
                cast(int*) &audio.frequency,
                cast(ushort*) &audio.format,
                cast(int*) &audio.channels
            );
            if(result == 0) throw new SDLError("Failed to get audio information.");
            return audio;
        }
        /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_12.html
        static void close(){
            auto count = typeof(this).countopen;
            if(count){
                Mix_ReserveChannels(0); // Un-reserve all channels
                foreach(i; 0 .. count) Mix_CloseAudio();
            }
        }
    }
}
