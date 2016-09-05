module mach.sdl.init.gl.versions;

private:

import derelict.opengl3.gl : DerelictGL, DerelictGLVersion = GLVersion;

import mach.text : text;
import mach.sdl.error : GLError;

import mach.io.log;

public:



class GLVersionError: GLError{
    this(
        in GLVersions.Version userversion, in GLVersions.Version requiredversion,
        in string file = __FILE__, in size_t line = __LINE__
    ){
        super(
            text(
                "Incompatible OpenGL version ", GLVersions.name(userversion), ". ",
                "At least ", GLVersions.name(requiredversion), " is required."
            ), line, file
        );
    }
}



/// So named as to not conflict with derelict's GLVersion.
struct GLVersions{
    alias Version = DerelictGLVersion;
    
    /// The currently loaded OpenGL version.
    static Version current = Version.None;
    
    /// Determine default OpenGL version.
    /// TODO: Why these versions, and why the difference between platforms?
    version(OSX){
        static enum Version MinimumVersion = Version.GL21;
        static enum Version DefaultVersion = Version.GL21;
    }else{
        static enum Version MinimumVersion = Version.GL30;
        static enum Version DefaultVersion = Version.GL30;
    }
    
    /// Given a gl version number, get the major version.
    static int major(in Version glversion){
        return glversion / 10;
    }
    /// Given a gl version number, get the minor version.
    static int minor(in Version glversion){
        return glversion % 10;
    }
    /// Given a gl version number, get a nice string representation.
    static string name(in Version glversion){
        return cast(string) ['0' + major(glversion), '.', '0' + minor(glversion)];
    }
    
    static void reload(){
        typeof(this).current = DerelictGL.reload();
    }
    
    /// Verify that the currently-loaded version is at least a minimum version.
    /// Throws a GLVersionError if the check fails.
    static void verify(Version minimum = MinimumVersion){
        immutable auto glversion = typeof(this).current;
        if(glversion < minimum) throw new GLVersionError(glversion, minimum);
        log("OpenGL version ", glversion);
    }
}




