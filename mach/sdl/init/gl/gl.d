module mach.sdl.init.gl.gl;

private:

import derelict.opengl3.gl;

import mach.sdl.error : GLException;
import mach.sdl.init.gl.settings;
import mach.sdl.init.gl.versions;

import mach.io : log;

public:



struct GL{
    static load(){DerelictGL.load();}
    static unload(){DerelictGL.unload();}
    
    alias Settings = GLSettings;
    alias Version = GLVersions;
    
    static void initialize(){
        log("Reloading bindings");
        Version.reload();
        
        log("Setting OpenGL flags and options");
        
        //glDisable(GL_DITHER);
        //glDisable(GL_LIGHTING); // Deprecated
        //glDisable(GL_DEPTH_TEST);
        //glDisable(GL_ALPHA_TEST); // Deprecated
        GLException.enforce();
        
        //glEnable(GL_TEXTURE_2D);
        GLException.enforce();
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // TODO: Does this work?
        GLException.enforce();
        
        glEnable(GL_CULL_FACE);
        glCullFace(GL_FRONT);
        GLException.enforce();
        
        glEnable(GL_MULTISAMPLE);
        GLException.enforce();
        // http://stackoverflow.com/questions/11806823/glenableclientstate-deprecated
        //glEnableClientState(GL_VERTEX_ARRAY);
        //glEnableClientState(GL_COLOR_ARRAY);
        //glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
        GLException.enforce();
    }
}
