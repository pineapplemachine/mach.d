module mach.sdl.application;

private:

import std.traits : isNumeric;
import mach.error : ThrowableMixin;
import mach.sdl.init : SDL, GL;
import mach.sdl.window : Window;
import mach.sdl.graphics : Color;
import mach.sdl.framelimiter : FrameLimiter;
import mach.sdl.input.event : Event, EventQueue;
import mach.sdl.input.helper : KeyHelper, MouseHelper;

public:



class ApplicationError: Error{
    mixin ThrowableMixin!("Encountered application error.");
}



abstract class Application{
    static enum QuitReason: int{
        /// The application hasn't quit.
        None,
        /// Why did the application quit? We simply don't know.
        Unknown,
        /// We don't know because the user didn't tell us.
        Unspecified,
        /// Because of an unhandled thrown error.
        UnhandledError,
        /// Because the window was closed.
        WindowClosed,
        /// Because of a nonspecific quit event.
        QuitEvent,
        /// For some other reason not listed here.
        Other,
    }
    
    /// The application's primary window. (TODO: Support for multiple windows?)
    Window window = null;
    /// Indicates what SDL libraries should be loaded and initialized.
    SDL.Support sdlsupport = SDL.Support.Default;
    /// The application's frame limiter.
    FrameLimiter framelimiter = FrameLimiter(60);
    /// For handling keyboard input.
    KeyHelper!() keys;
    /// For handling mouse input.
    MouseHelper!() mouse;
    
    /// Whether the application should be terminated.
    bool quitting = false;
    /// Whether the application is currently suspended.
    bool suspended = false;
    /// A code indicating the reason for quitting.
    QuitReason quitreason = QuitReason.None;
    
    /// Call this method to indicate that the application should be terminated.
    void quit(QuitReason reason = QuitReason.Unspecified){
        this.quitreason = reason;
        this.quitting = true;
    }
    /// Call this method to indicate that the application's main loop should be
    /// temporarily suspended. Event handling will still occur while the
    /// application is suspended.
    void suspend(){
        this.suspended = true;
    }
    /// Call this method to unsuspend the application.
    void unsuspend(){
        this.suspended = false;
    }
    
    /// Get an estimate of actual application FPS.
    @property auto fps(){
        return this.framelimiter.actualfps;
    }
    /// Clear the application window.
    void clear() in{assert(this.window);} body{
        this.window.clear();
    }
    /// ditto
    void clear(T)(in Color!T color) in{assert(this.window);}body{
        this.window.clear(color);
    }
    /// ditto
    void clear(T)(in T r, in T g, in T b, in T a = 1) if(isNumeric!T) in{
        assert(this.window);
    }body{
        this.window.clear(r, g, b, a);
    }
    /// Swap the application window, displaying graphical changes.
    void swap() in{assert(this.window);} body{
        this.window.swap();
    }
    
    /// Called once when the application is initialized.
    /// Must at least set this.window to a Window instance.
    /// This is a good place to load images, sounds, and other resources.
    abstract void initialize();
    /// Called once as the application is terminated.
    /// This is a good place to free images, sounds, and other resources.
    abstract void conclude();
    /// Called once every loop, if the application is not suspended.
    /// This is the final call in the application's main loop handling; it will
    /// take place after all event callbacks.
    abstract void main();
    
    /// Called once every loop, unconditionally.
    /// By default, does nothing.
    void onloop(){}
    /// Called once for every event that appears in the event queue.
    /// By default, does nothing.
    void onevent(Event event){}
    /// Call this method when the main loop transpires without any events being
    /// present in the queue.
    /// By default, does nothing.
    void onnoevent(){}
    
    /// Call this method when an unhandled error occurs in the application's
    /// main loop.
    /// By default, quits the application.
    void onerror(Throwable error){quit(QuitReason.UnhandledError);}
    /// Call this method when a quit event has been found in the event queue.
    /// By default, quits the application.
    void onquit(Event event){this.quit(QuitReason.QuitEvent);}
    /// Call this method when the window is closed.
    /// By default, quits the application.
    void onclose(Event event){this.quit(QuitReason.WindowClosed);}
    /// Call this method when the window is minimized.
    /// By default, suspends the application.
    void onminimize(Event event){this.suspend;}
    /// Call this method when the window is restored.
    /// By default, unsuspends the application.
    void onrestore(Event event){this.unsuspend;}
    
    /// Call this method when the window is shown.
    void onshown(Event event){}
    /// Call this method when the window is hidden.
    void onhidden(Event event){}
    /// Call this method when the window is exposed.
    void onexposed(Event event){}
    /// Call this method when the window is moved.
    void onmove(Event event){}
    /// Call this method when the window is resized.
    void onresize(Event event){}
    /// Call this method when the window size is changed.
    void onsizechange(Event event){}
    /// Call this method when the window is maximized.
    void onmaximize(Event event){}
    /// Call this method when the mouse enters the window.
    void onmouseenter(Event event){}
    /// Call this method when the mouse leaves the window.
    void onmouseleave(Event event){}
    /// Call this method when focus is gained.
    void onfocusgained(Event event){}
    /// Call this method when focus is lost.
    void onfocuslost(Event event){}
    /// Call this method when a key is pressed.
    void onkeypressed(Event event){}
    /// Call this method when a key is released.
    void onkeyreleased(Event event){}
    /// Call this method when a mouse button is pressed.
    void onmousepressed(Event event){}
    /// Call this method when a mouse button is released.
    void onmousereleased(Event event){}
    /// Call this method when the mouse wheel is moved.
    void onmousescroll(Event event){}
    /// Call this method when a file is dropped on the window.
    void ondropfile(Event event){}
    
    /// Entry point for the application.
    /// Returns the reason for having quit.
    auto begin(){
        this.metainitialize();
        while(!this.quitting) this.metamain();
        this.metaconclude();
        return this.quitreason;
    }
    
    /// Loads and initializes SDL and OpenGL, and makes a window.
    /// Also calls the subclass' initialize method.
    void metainitialize(){
        GL.load();
        SDL.load();
        this.sdlsupport.initialize();
        this.initialize();
        if(this.window is null){
            throw new ApplicationError("Application must have a window.");
        }
        this.window.raise();
        GL.initialize();
    }
    /// Quits and unloads SDL and OpenGL.
    /// Also calls the subclass' conclude method.
    void metaconclude(){
        this.conclude();
        if(this.window !is null) this.window.free();
        SDL.quit();
        SDL.unload();
        GL.unload();
    }
    /// The application's internal main loop.
    /// Also calls the class' main method.
    void metamain(){
        try{
            if(EventQueue.empty){
                this.metaevent();
            }else{
                foreach(event; EventQueue.events){
                    this.metaevent(event);
                    event.conclude();
                }
            }
            this.onloop();
            if(!this.quitting){
                if(!this.suspended){
                    this.window.use();
                    this.main();
                }
                this.framelimiter.update();
            }
        }catch(Throwable error){
            this.onerror(error);
        }
    }
    /// The application's internal event handling.
    /// Also calls the class' onevent method, and then various event callbacks.
    void metaevent(Event event){
        this.keys.update(event);
        this.mouse.update(event);
        this.onevent(event);
        if(event.type is event.Type.Quit){
            this.onquit(event);
        }else if(event.type is event.type.KeyUp){
            this.onkeyreleased(event);
        }else if(event.type is event.type.KeyDown){
            this.onkeypressed(event);
        }else if(event.type is event.type.MouseButtonUp){
            this.onmousereleased(event);
        }else if(event.type is event.type.MouseButtonDown){
            this.onmousepressed(event);
        }else if(event.type is event.type.MouseWheel){
            this.onmousescroll(event);
        }else if(event.type is event.type.DropFile){
            this.ondropfile(event);
        }else if(event.type is event.Type.Window){
            final switch(event.win.type){
                case event.win.Type.None: break;
                case event.win.Type.Shown: this.onshown(event); break;
                case event.win.Type.Hidden: this.onhidden(event); break;
                case event.win.Type.Exposed: this.onexposed(event); break;
                case event.win.Type.Moved: this.onmove(event); break;
                case event.win.Type.Resized: this.onresize(event); break;
                case event.win.Type.SizeChanged: this.onsizechange(event); break;
                case event.win.Type.Minimized: this.onminimize(event); break;
                case event.win.Type.Maximized: this.onmaximize(event); break;
                case event.win.Type.Restored: this.onrestore(event); break;
                case event.win.Type.MouseEntered: this.onmouseenter(event); break;
                case event.win.Type.MouseLeft: this.onmouseleave(event); break;
                case event.win.Type.FocusGained: this.onfocusgained(event); break;
                case event.win.Type.FocusLost: this.onfocuslost(event); break;
                case event.win.Type.Closed: this.onclose(event); break;
            }
        }
    }
    /// The application's internal event handling, for when there was no event.
    /// Also calls the class' onnoevent method.
    void metaevent(){
        this.keys.update();
        this.mouse.update();
        this.onnoevent();
    }
}
