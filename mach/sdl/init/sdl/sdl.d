module mach.sdl.init.sdl.sdl;

private:

import derelict.util.exception;

import mach.sdl.error : SDLError;
import mach.sdl.init.sdl.core;
import mach.sdl.init.sdl.image;
import mach.sdl.init.sdl.mixer;
import mach.sdl.init.sdl.ttf;
import mach.sdl.init.sdl.net;

import mach.io.log;

public:



struct SDL{
    alias Core = .Core;
    alias Image = .Image;
    alias Mixer = .Mixer;
    alias TTF = .TTF;
    alias Net = .Net;
    
    static struct Loaded{
        /// Whether each component has been loaded.
        bool core = false;
        bool image = false;
        bool mixer = false;
        bool ttf = false;
        bool net = false;
        /// Store errors encountered while loading.
        DerelictException coreerror = null;
        DerelictException imageerror = null;
        DerelictException mixererror = null;
        DerelictException ttferror = null;
        DerelictException neterror = null;
        /// Determine whether anything has been loaded.
        @property bool anyloaded() const{
            return this.core | this.image | this.mixer | this.ttf | this.net;
        }
        /// Unload everything that has been loaded.
        void unload() const{
            if(this.core) Core.unload();
            if(this.image) Image.unload();
            if(this.mixer) Mixer.unload();
            if(this.ttf) TTF.unload();
            if(this.net) Net.unload();
        }
        /// Throw any errors that were encountered while loading.
        void enforce() const{
            if(this.coreerror !is null) throw this.coreerror;
            if(this.imageerror !is null) throw this.imageerror;
            if(this.mixererror !is null) throw this.mixererror;
            if(this.ttferror !is null) throw this.ttferror;
            if(this.neterror !is null) throw this.neterror;
        }
    }
    
    /// Represents which derelict bindings have been successfully loaded
    static Loaded loaded;
    /// Load bindings.
    static auto load(
        bool core = true, bool image = true, bool mixer = true,
        bool ttf = true, bool net = true
    )in{
        assert(!loaded.anyloaded, "Unload before attempting to load again.");
    }body{
        loaded = Loaded.init;
        if(core){
            try{
                Core.load();
            }catch(DerelictException exception){
                loaded.coreerror = exception;
            }
            loaded.core = loaded.coreerror is null;
        }
        if(image){
            try{
                Image.load();
            }catch(DerelictException exception){
                loaded.imageerror = exception;
            }
            loaded.image = loaded.imageerror is null;
        }
        if(mixer){
            try{
                Mixer.load();
            }catch(DerelictException exception){
                loaded.mixererror = exception;
            }
            loaded.mixer = loaded.mixererror is null;
        }
        if(ttf){
            try{
                TTF.load();
            }catch(DerelictException exception){
                loaded.ttferror = exception;
            }
            loaded.ttf = loaded.ttferror is null;
        }
        if(net){
            try{
                Net.load();
            }catch(DerelictException exception){
                loaded.neterror = exception;
            }
            loaded.net = loaded.neterror is null;
        }
        return loaded;
    }
    static void unload(){
        this.loaded.unload();
    }
    
    /// Attempt to initialize SDL with the given options. Returns a list of
    /// errors that occurred, if any.
    static auto initialize(){
        return support.initialize();
    }
    /// Quit SDL things.
    static void quit(){
        support.quit();
    }

    static Support support = Support.All;
    static struct Support{
        static enum Enable{
            Yes, No, Auto
        }
        static bool enabledbool(Enable enabled, bool loaded){
            return enabled is Enable.Yes || (enabled is Enable.Auto && loaded);
        }
        
        static enum Support All = {
            image: Enable.Auto,
            mixer: Enable.Auto,
            ttf: Enable.Auto,
            net: Enable.Auto,
            coresystems: Core.Systems.Default,
            imageformats: Image.Formats.Default,
            mixerformats: Mixer.Formats.Default,
        };
        alias Default = All;
        
        Enable image; /// Whether the image library should be initialized.
        Enable mixer; /// Whether the mixer library should be initialized.
        Enable ttf; /// Whether the TTF library should be initialized.
        Enable net; /// Whether the network library should be initalized.
        Core.Systems coresystems; /// Core systems that should be initialized.
        Image.Formats imageformats; /// Image libraries that should be loaded.
        Mixer.Formats mixerformats; /// Mixer libraries that should be loaded.
        Mixer.Audio audiosettings; /// Settings with which mixer audio should be opened.

        /// Attempt to initialize SDL with the given options.
        void initialize() const{
            if(enabledbool(Enable.Yes, loaded.core)){
                if(!loaded.core) throw new SDLError("Can't init unloaded core.");
                Core.initialize(this.coresystems);
            }
            if(enabledbool(this.image, loaded.image)){
                if(!loaded.image) throw new SDLError("Can't init unloaded image library.");
                Image.initialize(this.imageformats);
            }
            if(enabledbool(this.mixer, loaded.mixer)){
                if(!loaded.mixer) throw new SDLError("Can't init unloaded mixer library.");
                Mixer.initialize(this.mixerformats);
                this.audiosettings.open();
            }
            if(enabledbool(this.ttf, loaded.ttf)){
                if(!loaded.ttf) throw new SDLError("Can't init unloaded TTF library.");
                TTF.initialize();
            }
            if(enabledbool(this.net, loaded.net)){
                if(!loaded.net) throw new SDLError("Can't init unloaded net library.");
                Net.initialize();
            }
        }
        /// Quit SDL things.
        void quit() const{
            if(loaded.core) Core.quit();
            if(this.image && loaded.image) Image.quit();
            if(this.mixer && loaded.mixer){Mixer.Audio.close(); Mixer.quit();}
            if(this.ttf && loaded.ttf) TTF.quit();
            if(this.net && loaded.net) Net.quit();
        }
    }
}
