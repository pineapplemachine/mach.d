module mach.sdl.init;

private:

import derelict.sdl2.sdl;
//import derelict.opengl3.gl3;
import derelict.opengl3.gl;
import derelict.sdl2.ttf;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.util.exception : SharedLibLoadException;

import std.conv : to;
import std.format : format;
import std.traits : EnumMembers;
import std.string : fromStringz, join, split, stripRight;
import std.algorithm : canFind, map, isPermutation;

import mach.sdl.glenum : BlendFactor;
import mach.sdl.error : GraphicsError, SDLError, GLError;


import mach.io.log;

public:

bool initializedSDL = false;
bool initializedGL = false;

struct DerelictLoaderWrapper{
    
    static DerelictLoaderWrapper[] Loaders;
    static DerelictLoaderWrapper Core;
    static DerelictLoaderWrapper Image;
    static DerelictLoaderWrapper TTF;
    static DerelictLoaderWrapper Mixer;
    static DerelictLoaderWrapper GL;
    
    static init(){
        Core = DerelictLoaderWrapper(DerelictSDL2, {
            if(SDL_WasInit(SDL_INIT_JOYSTICK) != 0){
                SDL_QuitSubSystem(SDL_INIT_JOYSTICK);
            }
            if(SDL_WasInit(SDL_INIT_GAMECONTROLLER) != 0){
                SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER);
            }
            SDL_Quit();
        });
        Image = DerelictLoaderWrapper(DerelictSDL2Image, {IMG_Quit();}),
        TTF = DerelictLoaderWrapper(DerelictSDL2ttf, {TTF_Quit();}),
        Mixer = DerelictLoaderWrapper(DerelictSDL2Mixer, {
            Mix_ReserveChannels(0);
            Mix_CloseAudio();
            Mix_Quit();
        }),
        GL = DerelictLoaderWrapper(DerelictGL); // TODO: DerelictGL3?
        Loaders = [Core, Image, TTF, Mixer, GL];
    }
    
    SharedLibLoader loader;
    void function() quitfunc;
    
    this(SharedLibLoader loader, void function() quitfunc = {}){
        this.loader = loader;
        this.quitfunc = quitfunc;
    }
    
    void load(){
        if(!this.loader.isLoaded) this.loader.load();
    }
    void quit(){
        if(this.loader.isLoaded) this.quitfunc();
    }
    void unload(){
        if(this.loader.isLoaded) this.loader.unload();
    }
    
    static loadall(){
        foreach(loader; Loaders) loader.load();
    }
    static unloadall(){
        foreach_reverse(loader; Loaders) loader.quit();
        foreach_reverse(loader; Loaders) loader.unload();
    }
}

void enforceSDL(size_t line = __LINE__, string file = __FILE__){
    if(!initializedSDL) throw new SDLError("SDL must be initialized.", null, line, file);
}

shared static this(){
    DerelictLoaderWrapper.init();
}
shared static ~this(){
    DerelictLoaderWrapper.unloadall();
}

struct SDLSupport{
    
    static SDLSupport Default = SDLSupport(
        Option.JOYSTICK, Option.GAMECONTROLLER,
        Option.TTF, Option.PNG, Option.OGG
    );
    static SDLSupport NoAudio = SDLSupport(
        Option.JOYSTICK, Option.GAMECONTROLLER,
        Option.TTF, Option.PNG
    );
    static SDLSupport All = SDLSupport(
        Option.JOYSTICK, Option.GAMECONTROLLER,
        Option.TTF,
        Option.JPG, Option.PNG, Option.TIF, Option.WEBP,
        Option.OGG, Option.MP3, Option.FLAC, Option.MOD,
        Option.MODPLUG, Option.FLUIDSYNTH
    );
    static SDLSupport AlreadyInitialized = SDLSupport("Already initialized.");
    static immutable int DEFAULT_CHANNELS = 256;
    
    /// Defines a flag and type to associate with members of the Option enum.
    struct OptionFlag{
        enum Type{
            CORE, TTF, IMG, MIX
        }
        int flag;
        Type type;
        string name;
        
        static Option[] parse(in string optionstring){
            string[] optionnames = split(optionstring, "|"); //
            Option[] options = new Option[optionnames.length];
            foreach(i; 0 .. optionnames.length){
                foreach(immutable flag; [EnumMembers!Option]){
                    if(flag.name == optionnames[i]){
                        options[i] = flag; break;
                    }
                }
            }
            return options;
        }
    }
    alias OptionType = OptionFlag.Type;
    
    /// Various options for SDL things that can be enabled.
    enum Option : const(OptionFlag){
        JOYSTICK = OptionFlag(0, OptionType.CORE, "joystick"),
        GAMECONTROLLER = OptionFlag(0, OptionType.CORE, "controller"),
        
        TTF = OptionFlag(0, OptionType.TTF, "ttf"),
        
        JPG = OptionFlag(0x01, OptionType.IMG, "jpg"),
        PNG = OptionFlag(0x02, OptionType.IMG, "png"),
        TIF = OptionFlag(0x04, OptionType.IMG, "tif"),
        WEBP = OptionFlag(0x08, OptionType.IMG, "webp"),
        
        FLAC = OptionFlag(0x01, OptionType.MIX, "flac"),
        MOD = OptionFlag(0x02, OptionType.MIX, "mod"),
        MODPLUG = OptionFlag(0x04, OptionType.MIX, "modplug"),
        MP3 = OptionFlag(0x08, OptionType.MIX, "mp3"),
        OGG = OptionFlag(0x10, OptionType.MIX, "ogg"),
        FLUIDSYNTH = OptionFlag(0x20, OptionType.MIX, "fluidsynth"),
    }
    
    // https://www.libsdl.org/projects/SDL_mixer/docs/SDL_mixer_11.html
    enum MixChannels : int {
        Default = MIX_DEFAULT_CHANNELS,
        Mono = 1,
        Stereo = 2
    }
    enum AudioFormat : ushort {
        Default = MIX_DEFAULT_FORMAT,
        U8 = AUDIO_U8, /// Unsigned 8-bit samples
        S8 = AUDIO_S8, /// Signed 8-bit samples
        U16LSB = AUDIO_U16LSB, /// Unsigned 16-bit samples, in little-endian byte order
        S16LSB = AUDIO_S16LSB, /// Signed 16-bit samples, in little-endian byte order
        U16MSB = AUDIO_U16MSB, /// Unsigned 16-bit samples, in big-endian byte order
        S16MSB = AUDIO_S16MSB, /// Signed 16-bit samples, in big-endian byte order
        U16 = AUDIO_U16, /// same as AUDIO_U16LSB (for backwards compatability probably)
        S16 = AUDIO_S16, /// same as AUDIO_S16LSB (for backwards compatability probably)
        U16SYS = AUDIO_U16SYS, /// Unsigned 16-bit samples, in system byte order
        S16SYS = AUDIO_S16SYS, /// Signed 16-bit samples, in system byte order
    }
    
    Throwable[] errors;
    Option[] options;
    int mixchannels = DEFAULT_CHANNELS;
    int mixfrequency = MIX_DEFAULT_FREQUENCY;
    AudioFormat mixformat = AudioFormat.Default;
    MixChannels outchannels = MixChannels.Default;
    
    this(Throwable error){
        this.errors = [error];
    }
    this(string error){
        this(new GraphicsError(error));
    }
    this(Option[] options ...){
        this(options, DEFAULT_CHANNELS);
    }
    this(Option[] options, int mixchannels){
        this.options = options;
        this.mixchannels = mixchannels;
    }
    /// e.g. SDLSupport("joystick|controller|ttf|png|ogg") == SDLSupport.Default
    this(in string optionstring, int mixchannels = DEFAULT_CHANNELS){
        this(OptionFlag.parse(optionstring), mixchannels);
    }
    
    void error(Throwable error){
        this.errors ~= error;
    }
    void error(string error, size_t line = __LINE__, string file = __FILE__){
        this.error(new SDLError(error, line, file));
    }
    
    bool has(in Option option) const{
        return this.options.canFind(option);
    }
    @property bool hasttf() const{
        return this.has(Option.TTF);
    }
    @property bool hasimage() const{
        return(
            this.has(Option.JPG) || this.has(Option.PNG) ||
            this.has(Option.TIF) || this.has(Option.WEBP)
        );
    }
    @property bool hasmixer() const{
        return(
            this.has(Option.FLAC) || this.has(Option.MOD) ||
            this.has(Option.MODPLUG) || this.has(Option.OGG) ||
            this.has(Option.MP3) || this.has(Option.FLUIDSYNTH)
        );
    }
    
    void add(Option option){
        this.options ~= option;
    }
    void addflags(OptionType type)(in int flags){
        static if(type == OptionType.IMG){
            if((flags & Option.JPG.flag) != 0) this.add(Option.JPG);
            if((flags & Option.PNG.flag) != 0) this.add(Option.PNG);
            if((flags & Option.TIF.flag) != 0) this.add(Option.TIF);
            if((flags & Option.WEBP.flag) != 0) this.add(Option.WEBP);
        }else static if(type == OptionType.MIX){
            if((flags & Option.FLAC.flag) != 0) this.add(Option.FLAC);
            if((flags & Option.MOD.flag) != 0) this.add(Option.MOD);
            if((flags & Option.MODPLUG.flag) != 0) this.add(Option.MODPLUG);
            if((flags & Option.OGG.flag) != 0) this.add(Option.OGG);
            if((flags & Option.MP3.flag) != 0) this.add(Option.MP3);
            if((flags & Option.FLUIDSYNTH.flag) != 0) this.add(Option.FLUIDSYNTH);
        }else{
            assert(false, "Invalid option.");
        }
    }
    
    int flags(in OptionType type) const{
        int result = 0;
        foreach(Option option; this.options){
            if(option.type is type) result |= option.flag;
        }
        return result;
    }
    
    void load() const{
        DerelictLoaderWrapper.Core.load();
        if(this.hasimage()) DerelictLoaderWrapper.Image.load();
        if(this.hasttf()) DerelictLoaderWrapper.TTF.load();
        if(this.hasmixer()) DerelictLoaderWrapper.Mixer.load();
        DerelictLoaderWrapper.GL.load();
    }
    
    /++
        Attempts to initialize SDL with all the given support flags and returns
        an SDLSupport object indicating what was actually initialized.
    +/ 
    SDLSupport init() const{
        
        SDLSupport result = SDLSupport();
        
        try{
            this.load();
        }catch(SharedLibLoadException error){
            result.error(error);
            return result;
        }
        
        if(!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO)){
            result.error("Failed to initialize SDL.");
            //return result; // Critical failure // TODO: ???
        }
        
        // Initialize joystick and gamepad
        if(this.has(Option.JOYSTICK)){
            if(SDL_InitSubSystem(SDL_INIT_JOYSTICK) == 0) result.add(Option.JOYSTICK);
            else result.error("Failed to initialize joystick.");
        }
        if(this.has(Option.GAMECONTROLLER)){
            if(SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) == 0) result.add(Option.GAMECONTROLLER);
            else result.error("Failed to initialize game controller.");
        }
        
        // Initialize image
        if(this.hasimage()){
            auto goalflags = this.flags(SDLSupport.OptionType.IMG);
            auto resultflags = IMG_Init(goalflags);
            result.addflags!(SDLSupport.OptionType.IMG)(resultflags);
            if(resultflags != goalflags) result.error("Failed to initialize image support.");
        }
        
        // Initialize TTF
        if(this.hasttf()){
            if(TTF_Init() == 0) result.add(Option.TTF);
            else result.error("Failed to initialize TTF support.");
        }
        
        // Initialize mixer
        if(this.hasmixer()){
            auto goalflags = this.flags(SDLSupport.OptionType.MIX);
            auto resultflags = Mix_Init(goalflags);
            result.addflags!(SDLSupport.OptionType.MIX)(resultflags);
            if(resultflags != goalflags) result.error("Failed to initialize mix support.");
            if(Mix_OpenAudio(this.mixfrequency, this.mixformat, this.outchannels, 4096) != 0) result.error("Failed to open audio.");
            result.mixchannels = Mix_AllocateChannels(this.mixchannels);
            if(result.mixchannels != this.mixchannels) result.error("Failed to allocate mixing channels.");
            // TODO: ???
            //SDL_ClearError(); // Ignore XAudio2 error: http://redmine.audacious-media-player.org/issues/346
        }
        
        return result;
        
    }
    
    void opOpAssign(string op: "~")(in Option rhs) const{
        this.add(rhs);
    }
    bool opBinaryRight(string op: "in")(in Option lhs) const{
        return this.has(lhs);
    }
    
    bool opEquals(in SDLSupport rhs) const{
        return(
            this.mixchannels == rhs.mixchannels &&
            isPermutation(this.options, rhs.options)
        );
    }
    
    string optionstring() const{
        return (
            this.options.length == 0 ? "none" :
            join(map!((option) => (option.name))(this.options), ", ")
        );
    }
    string errorstring() const{
        return join(map!((error) => (
            error.msg.stripRight() ~ " at " ~ error.file ~ "(" ~ to!string(error.line) ~ ")"
        ))(this.errors), "\n");
    }
    string toString() const{
        string to = "support: " ~ this.optionstring();
        if(this.errors.length > 0) to ~= "\nerrors:\n" ~ this.errorstring();
        return to;
    }
    
}



SDLSupport initSDL(in SDLSupport goal = SDLSupport.Default){
    return initializedSDL ? SDLSupport.AlreadyInitialized : forceinitSDL(goal);
}
SDLSupport forceinitSDL(in SDLSupport goal){
    scope(exit) initializedSDL = true;
    return goal.init();
}



class GLVersionError : GraphicsError{
    this(in GLVersion userversion, in GLVersion requiredversion, in string file = __FILE__, in size_t line = __LINE__){
        super(
            "Incompatible OpenGL version %s. At least %s is required.".format(
                userversion.versionname(), requiredversion.versionname()
            ), null, line, file
        );
    }
}

string versionname(GLVersion glversion){
    return cast(string) ['0' + (glversion / 10), '.', '0' + (glversion % 10)];
}

void initGL(){
    if(!initializedGL) forceinitGL();
}
void forceinitGL(){
    scope(exit) initializedGL = true;
    
    log;
    verifyGLversion();
    
    log;
    glDisable(GL_DITHER);
    glDisable(GL_LIGHTING); // Deprecated?
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_ALPHA_TEST); // Deprecated?

    log;
    glEnable(GL_TEXTURE_2D);
    
    log;
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    log;
    glEnable(GL_CULL_FACE);
    glCullFace(GL_FRONT);

    log;
    glEnable(GL_MULTISAMPLE);
    
    // Deprecated? http://stackoverflow.com/questions/11806823/glenableclientstate-deprecated
    log;
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    log;
    glBlendFunc(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha); // TODO: Works?
    
    log;
    GLError.enforce();
}
void verifyGLversion(){
    // TODO: explore alternative DerelictGL3.reload()
    immutable GLVersion glversion = DerelictGL.reload();
    
    version(OSX){
        enum GLVersion MINIMUM_GL_VERSION = GLVersion.GL21;
    }else{
        enum GLVersion MINIMUM_GL_VERSION = GLVersion.GL30;
    }
    
    if(glversion < MINIMUM_GL_VERSION){
        throw new GLVersionError(glversion, MINIMUM_GL_VERSION);
    }
}

version(unittest) import mach.error.unit;
unittest{
    // TODO: more better tests
    testeq(initSDL(SDLSupport.Default), SDLSupport.Default);
}
