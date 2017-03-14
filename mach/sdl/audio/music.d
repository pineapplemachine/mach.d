module mach.sdl.audio.music;

private:

import derelict.sdl2.mixer;
import derelict.sdl2.types;

import mach.math.clamp : clamp;
import mach.text.cstring : tocstring, fromcstring;
import mach.sdl.error : SDLException;
import mach.sdl.audio.fading : AudioFading;

/++ Docs

This module wraps SDL_mixer functions that pertain to music playback.
Music can be loaded from a variety of different file formats, provided
a decoder is available, including WAV, MOD, MIDI, OGG, and MP3.

For example, `auto music = Music("mymusic.ogg"); music.play();` would first
load music from an OGG file and then begin playing it.

+/

public:



/// Load and play music audio files.
/// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_52.html#SEC52
struct Music{
    alias Fading = AudioFading;
    static enum Type: Mix_MusicType{
        None = MUS_NONE, /// Indicates that music was not loaded, or wasn't playing.
        CMD = MUS_CMD, /// Music is played via an external command.
        WAV = MUS_WAV, /// Music was loaded from a wav file.
        MOD = MUS_MOD, /// Music was loaded from a mod file.
        MIDI = MUS_MID, /// Music was loaded from a midi file.
        OGG = MUS_OGG, /// Music was loaded from an ogg file.
        MP3 = MUS_MP3, /// Music was loaded from an mp3 file.
        MP3MAD = MUS_MP3_MAD, /// TODO: What is this?
        FLAC = MUS_FLAC, /// Music was loaded from a flac file.
        MODPlug = MUS_MODPLUG, /// Music was loaded from a MODPlug file.
    }
    
    alias HookCallback = extern(C) void function();
    
    @disable this(this);
    
    Mix_Music* music;
    
    /// Create an instance given a pointer to some Mix_Music data.
    this(Mix_Music* music){
        this.music = music;
    }
    /// Load audio from a file path.
    /// Supports WAV, MOD, MIDI, OGG, MP3, and FLAC audio files.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_55.html#SEC55
    this(in string path){
        this.music = Mix_LoadMUS(path.tocstring);
        if(this.music is null) throw new SDLException(
            "Failed to load music from path \"" ~ path ~ "\"."
        );
    }
    
    ~this(){
        if(this.music !is null) this.free();
    }
    
    /// Free memory used for music.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_56.html#SEC56
    void free(){
        Mix_FreeMusic(this.music);
        this.music = null;
    }
    
    /// Play the audio, looping the given number of times.
    /// (Or looping indefinitely, if no such number is provided.)
    /// Accepts an optional number of milliseconds to have a fade-in effect;
    /// defaults to zero milliseconds.
    /// May throw an SDLException if the audio failed to start.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_58.html#SEC58
    auto play(in int fadems = 0, in int repeat = -1){
        assert(this.music !is null);
        auto result = Mix_FadeInMusic(this.music, repeat, fadems);
        if(result == -1) throw new SDLException("Failed to play music.");
    }
    
    /// Get the volume that music is currently playing at as a value ranging
    /// from 0 (lowest volume) to 1 (highest volume).
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_61.html#SEC61
    static @property double volume(){
        return Mix_VolumeMusic(-1) / cast(double) MIX_MAX_VOLUME;
    }
    /// Set the volume that music is currently playing at as a value ranging
    /// from 0 to 1.
    /// May fail if music is currently fading in, or if an external
    /// music player is being used.
    /// If it's important to detect and handle such an error, check whether the
    /// result of `SDLException.errortext` is non-null after a call to this.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_61.html#SEC61
    static @property void volume(in double volume){
        Mix_VolumeMusic(cast(int)(clamp(volume, 0, 1) * MIX_MAX_VOLUME));
    }
    
    /// Get the encoding type of some loaded music.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_70.html#SEC70
    @property auto type() const{
        if(this.music is null) return Type.None;
        else return cast(Type) Mix_GetMusicType(this.music);
    }
    /// Get the encoding type of the music that is currently being played.
    /// Returns `Music.Type.None` if no music was playing.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_70.html#SEC70
    static @property auto currenttype(){
        return cast(Type) Mix_GetMusicType(null);
    }
    
    /// Pause the currently-playing music; can be resumed later.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_62.html#SEC62
    static void pause(){
        Mix_PauseMusic();
    }
    /// Resume the currently-paused music.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_63.html#SEC63
    static void resume(){
        Mix_ResumeMusic();
    }
    /// Rewind the currently-playing music to the beginning.
    /// Only works for MOD, OGG, MP3, and native MIDI output!
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_64.html#SEC64
    static void rewind(){
        Mix_RewindMusic();
    }
    
    /// Get whether music is currently playing. (Returns true even when paused!)
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_71.html#SEC71
    static @property bool active(){
        return cast(bool) Mix_PlayingMusic();
    }
    /// Get whether music has been paused.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_72.html#SEC72
    static @property bool paused(){
        return cast(bool) Mix_PausedMusic();
    }
    /// Get whether music is currently audible, i.e. active and not paused.
    static @property bool playing(){
        return typeof(this).active && !typeof(this).paused;
    }
    
    /// Get whether music is currently fading in, out, or not fading at all.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_73.html#SEC73
    static @property Fading fading(){
        return cast(Fading) Mix_FadingMusic();
    }
    
    /// Immediately halt the currently-playing music.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_67.html#SEC67
    static void stop(){
        Mix_HaltMusic();
    }
    /// Fade out the currently-playing music, becoming silent and stopping
    /// some given number of milliseconds from the call.
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_68.html#SEC68
    static void fadeout(in int fadems){
        auto result = Mix_FadeOutMusic(fadems);
        if(result == 0) throw new SDLException("Failed to fade out music.");
    }
    
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_69.html#SEC69
    static @property void onfinished(HookCallback callback){
        Mix_HookMusicFinished(callback);
    }
    /// https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_74.html#SEC74
    static @property auto onfinished(){
        return cast(HookCallback) Mix_GetMusicHookData();
    }
}
