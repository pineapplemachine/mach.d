module mach.sdl.glsettings;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import std.string : fromStringz;

public:

class GLAttributeError : Error{
    this(string message, string file = __FILE__, size_t line = __LINE__){
        super("Failed to set OpenGL attribute: " ~ message, file, line, null);
    }
}

struct GLSettings {

    static immutable GLSettings DEFAULT_SETTINGS = GLSettings(DEFAULT_GLVERSION);

    enum Profile : ubyte {
        /// Depends on platform
        Default,
        /// Deprecated functions are allowed
        Compatibility,
        /// Deprecated functions disabled
        Core,
        /// Only a subset of base functionality is available
        ES
    }
    
    enum Antialias : ubyte {
        None = 0,
        X2 = 2,
        X4 = 4,
        X8 = 8,
        X16 = 16
    }
    
    alias Version = GLVersion;
    
    version(OSX){
        enum Version DEFAULT_GLVERSION = Version.GL21;
    }else{
        enum Version DEFAULT_GLVERSION = Version.GL30;
    }
    
    static int majorversion(in Version glversion){
        return glversion / 10;
    }
    static int minorversion(in Version glversion){
        return glversion % 10;
    }
    
    Version glversion;
    Antialias antialias;
    Profile profile;
    
    this(
        Version glversion,
        Antialias antialias = Antialias.None,
        Profile profile = Profile.Compatibility
    ){
        this.antialias = antialias;
        this.glversion = glversion;
        this.profile = profile;
    }
    
    static void setattribute(int attribute, int value){
        if(SDL_GL_SetAttribute(attribute, value) != 0){
            throw new GLAttributeError(cast(string) fromStringz(SDL_GetError()));
        }
    }
    void setattributes() const{
        int major = majorversion(this.glversion);
        int minor = minorversion(this.glversion);
        
        if(major != 0){
            setattribute(SDL_GL_CONTEXT_MAJOR_VERSION, major);
            setattribute(SDL_GL_CONTEXT_MINOR_VERSION, minor);
        }
        
        final switch(this.profile){
            case Profile.Core:
                setattribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
                setattribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
                break;
            case Profile.Compatibility:
                setattribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
                break;
            case Profile.ES:
                setattribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
                break;
            case Profile.Default:
                break;
        }
        
        if(this.antialias > 0){
            setattribute(SDL_GL_MULTISAMPLEBUFFERS, 1);
            setattribute(SDL_GL_MULTISAMPLESAMPLES, antialias);
        }
        
        setattribute(SDL_GL_DOUBLEBUFFER, 1);
        setattribute(SDL_GL_ACCELERATED_VISUAL, 1);
    }
    
}
