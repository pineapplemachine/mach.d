module mach.sdl.window;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import std.traits : isNumeric;
import std.string : toStringz, fromStringz;
import core.sync.mutex : Mutex;
import mach.range : filter, asarray;

import mach.sdl.error : SDLError, GLError;
import mach.sdl.init : GLSettings;
import mach.sdl.glenum : PixelsFormat, PixelsType, ColorBufferMode;
import mach.sdl.graphics.color : Color;
import mach.sdl.graphics.mask : Mask;
import mach.sdl.graphics.displaymode : DisplayMode;
import mach.sdl.graphics.surface : Surface;
import mach.math.box : Box;
import mach.math.vector2 : Vector2;
import mach.math.matrix4 : Matrix4;

import mach.io.log;

public:



class Window{
    static enum string DefaultTitle = "D Application";
    
    alias ID = uint;
    alias Style = uint;
    static enum Style DEFAULT_STYLE = StyleFlag.Shown;
    static enum Style FULLSCREEN_STYLES = StyleFlag.Fullscreen | StyleFlag.Desktop;
    
    static enum StyleFlag : uint {
        Default = Shown, /// Default is Shown
        Fullscreen = SDL_WINDOW_FULLSCREEN, /// Window is fullscreen
        Desktop = SDL_WINDOW_FULLSCREEN_DESKTOP,    /// Window has Desktop Fullscreen
        Shown = SDL_WINDOW_SHOWN,   /// Show the Window immediately
        Hidden = SDL_WINDOW_HIDDEN, /// Hide the Window immediately
        Borderless = SDL_WINDOW_BORDERLESS, /// The Window has no border
        Resizeable = SDL_WINDOW_RESIZABLE,  /// Window is resizeable
        Maximized = SDL_WINDOW_MAXIMIZED,   /// Maximize the Window immediately
        Minimized = SDL_WINDOW_MINIMIZED,   /// Minimize the Window immediately
        InputGrabbed = SDL_WINDOW_INPUT_GRABBED,    /// Grab the input inside the window
        InputFocus = SDL_WINDOW_INPUT_FOCUS,    /// The Window has input (keyboard) focus
        MouseFocus = SDL_WINDOW_MOUSE_FOCUS,    /// The Window has mouse focus
        MouseCapture = SDL_WINDOW_MOUSE_CAPTURE, /// window has mouse captured (unrelated to InputGrabbed)
        AllowHighDPI = SDL_WINDOW_ALLOW_HIGHDPI, /// Window should be created in high-DPI mode if supported
    }
    
    static enum VSync : byte {
        Enabled = 1,
        Disabled = 0,
        LateSwapTearing = -1
    }
    
    static typeof(this.window) currentwindow = null; // Currently active window
    
    // Please don't hate me
    static Window[] instances;
    void register() in{
        // Disallow duplicates in registry
        foreach(instance; instances) assert(this !is instance);
    }body{
        this.instances ~= this;
    }
    void unregister(){
        log("unregistering");
        if(this.window !is null){
            this.instances = this.instances.filter!(e => e !is this).asarray;
        }
    }
    @property ID id(){
        return SDL_GetWindowID(this.window);
    }
    static typeof(this) byid(in ID id){
        foreach(window; typeof(this).instances){
            if(window.id == id) return window;
        }
        return null;
    }
    static typeof(this) byptr(in SDL_Window* ptr){
        foreach(window; typeof(this).instances){
            if(window.window is ptr) return window;
        }
        return null;
    }
    
    SDL_Window* window;
    SDL_GLContext context;
    
    // TODO: Center window when no explicit x, y was provided
    // http://stackoverflow.com/a/15575920/3478907
    this(
        in int width, in int height,
        in Style style = DEFAULT_STYLE,
        in VSync vsync = VSync.Disabled,
        in GLSettings settings = GLSettings.Default
    ){
        this(DefaultTitle, Box!int(width, height), style, vsync);
    }
    this(
        in string title, in int width, in int height,
        in Style style = DEFAULT_STYLE,
        in VSync vsync = VSync.Disabled,
        in GLSettings settings = GLSettings.Default
    ){
        this(title, Box!int(width, height), style, vsync);
    }
    this(
        in string title, in Box!int view,
        in Style style = DEFAULT_STYLE,
        in VSync vsync = VSync.Disabled,
        in GLSettings settings = GLSettings.Default
    ){
        // Actually create the window
        //this.window = SDL_CreateWindow(
        //    toStringz(title),
        //    view.x, view.y, view.width, view.height,
        //    style | SDL_WINDOW_OPENGL
        //);
        //if(!window) throw new SDLError("Failed to create SDL_Window.");
        
        //this.context = SDL_GL_CreateContext(window);
        //if(!this.context) throw new SDLError("Failed to create SDL_GLContext.");
        
        //this.glsettings(settings);        
        //this.projection(Box!int(view.width, view.height));
        //this.clearcolor(0, 0, 0, 1);
        //this.vsync(vsync);
        //this.register();
    }
    
    this(SDL_Window* window, SDL_GLContext context){
        this.window = window;
        this.context = context;
        if(!this.window) throw new SDLError("Invalid window.");
        if(!this.context) throw new SDLError("Invalid GL context.");
        if(SDL_GL_MakeCurrent(this.window, this.context) != 0){
            throw new SDLError("Failed to set GLContext for rending to window.");
        }
        this.project();
        this.clearcolor(0, 0, 0, 1);
        this.register();
    }
    
    ~this(){
        log("destructor");
        this.free();
        this.unregister();
    }
    
    void free(){
        log("freeing");
        this.freecontext();
        this.freewindow();
        log("finished freeing");
    }
    void freecontext(){
        if(this.context !is null){
            SDL_GL_DeleteContext(this.context);
            this.context = null;
        }
    }
    void freewindow(){
        if(this.window !is null){
            SDL_DestroyWindow(this.window);
            this.window = null;
        }
    }
    
    @property void projection(N)(in Vector2!N size){
        this.projection(Box!N(size));
    }
    @property void projection(N)(in Box!N screen){
        glViewport(screen.x, screen.y, screen.width, screen.height);
        this.projection(Matrix4!float.identity.orthographic(screen));
    }
    @property void projection(in Matrix4!float matrix){
        glMatrixMode(GL_PROJECTION);
        glLoadMatrixf(matrix.aligned.ptr); // TODO: see matrix4.aligned
        glMatrixMode(GL_MODELVIEW);
        // Alternative: Works on Win7 but not OSX:
        //glLoadIdentity();
        //glOrtho(0, this.width, this.height, 0, -1f, 1f);
        //glTranslatef(this.x, this.y, 0f);
    }
    void project(){
        this.projection = this.size;
    }
    
    @property void vsync(VSync sync){
        if(SDL_GL_SetSwapInterval(sync) != 0){
            throw new SDLError("Failed to set swap interval.");
        }
    }
    @property VSync vsync() const{
        return cast(VSync) SDL_GL_GetSwapInterval();
    }
    
    void clear(){
        glClear(GL_COLOR_BUFFER_BIT);
    }
    void clear(T)(in T color){
        this.clearcolor(color);
        this.clear();
    }
    void clear(N)(in N r, in N g, in N b, in N a = 1) if(isNumeric!N){
        this.clearcolor(r, g, b, a);
        this.clear();
    }
    
    @property void clearcolor(in Color!float color){
        this.clearcolor(color.r, color.g, color.b, color.a);
    }
    @property void clearcolor(in SDL_Color color){
        this.clearcolor(color.r / 255f, color.g / 255f, color.b / 255f, color.a / 255f);
    }
    @property void clearcolor(N)(in N[4] rgba) if(isNumeric!N){
        this.clearcolor(rgba[0], rgba[1], rgba[2], rgba[3]);
    }
    void clearcolor(N)(in N r, in N g, in N b, in N a = 1) if(isNumeric!N){
        glClearColor(cast(float) r, cast(float) g, cast(float) b, cast(float) a);
    }
    
    @property bool current(){
        return this.currentwindow !is null && this.window == this.currentwindow;
    }
    
    /// Swap buffers and make changes visible
    void swap(){
        this.use();
        SDL_GL_SwapWindow(this.window);
    }
    
    /// Set OpenGL context settings.
    @property void glsettings(GLSettings settings){
        this.use();
        settings.apply();
    }
    
    void use(){
        if(!this.current){
            if(SDL_GL_MakeCurrent(this.window, this.context) == 0){
                this.currentwindow = this.window;
            }else{
                throw new SDLError("Failed to make window context current.");
            }
        }
    }
    
    @property string title(){
        return cast(string) fromStringz(SDL_GetWindowTitle(this.window)).dup;
    }
    @property void title(string title){
        // TODO: Make sure the string returned by toStringz doesn't get eaten
        // by the GC and cause an error
        SDL_SetWindowTitle(this.window, toStringz(title));
    }
    
    @property void icon(Surface icon){
        this.icon(icon.surface);
    }
    @property void icon(SDL_Surface* icon){
        SDL_SetWindowIcon(this.window, icon);
    }
    
    // TODO: ??? Is this even usable in combination with gl rendering?
    @property SDL_Surface* sdlsurface(){
        SDL_Surface* surface = SDL_GetWindowSurface(this.window);
        if(!surface) throw new SDLError("Failed to get window surface.");
        return surface;
    }
    @property Surface surface(){
        return Surface(this.sdlsurface());
    }
    
    /// Get window graphics data as a surface
    Surface capture(
        in PixelsFormat format = PixelsFormat.BGRA,
        in int depth = Surface.DEFAULT_DEPTH
    ){
        Vector2!int size = this.size();
        Surface capture = Surface(size.x, size.y, depth, Mask.Zero);
        glReadBuffer(ColorBufferMode.Front);
        glReadPixels(
            0, 0, size.x, size.y, format,
            PixelsType.Ubyte, capture.surface.pixels
        );
        GLError.enforce();
        //capture.flip(); // TODO: Why does Dgame do a horizontal flip here?
        return capture;
    }
    
    /// Restore to original size and position from minimization or maximization
    void restore(){
        SDL_RestoreWindow(this.window);
    }
    /// Raise the window to top and set focus
    void raise(){
        SDL_RaiseWindow(this.window);
    }
    /// Maximize the window
    void maximize(){
        SDL_MaximizeWindow(this.window);
    }
    /// Minimize the window
    void minimize(){
        SDL_MinimizeWindow(this.window);
    }
    
    @property bool keyfocus() const{
        return SDL_GetKeyboardFocus() == this.window;
    }
    @property bool mousefocus() const{
        return SDL_GetMouseFocus() == this.window;
    }
    
    @property Style style(){
        return cast(Style) SDL_GetWindowFlags(this.window);
    }
    
    
    /// Set border state of the window
    @property void border(bool enabled){
        SDL_SetWindowBordered(this.window, enabled ? SDL_TRUE : SDL_FALSE);
    }
    
    static string VectorPropertyMixin(string name, string SDLgetter, string SDLsetter){
        return `
            @property Vector2!int ` ~ name ~ `(){
                int x, y;
                ` ~ SDLgetter ~ `(this.window, &x, &y);
                return Vector2!int(x, y);
            }
            @property void ` ~ name ~ `(in Vector2!int vector){
                this.set` ~ name ~ `(vector.x, vector.y);
            }
            void set` ~ name ~ `(in int x, in int y){
                ` ~ SDLsetter ~ `(this.window, x, y);
            }
        `;
    }
    
    mixin(VectorPropertyMixin(
        "size", "SDL_GetWindowSize", "SDL_SetWindowSize"
    ));
    mixin(VectorPropertyMixin(
        "minsize", "SDL_GetWindowMinimumSize", "SDL_SetWindowMinimumSize"
    ));
    mixin(VectorPropertyMixin(
        "maxsize", "SDL_GetWindowMaximumSize", "SDL_SetWindowMaximumSize"
    ));
    mixin(VectorPropertyMixin(
        "position", "SDL_GetWindowPosition", "SDL_SetWindowPosition"
    ));
    
    @property int width(){
        int width;
        SDL_GetWindowSize(this.window, &width, cast(int*) null);
        return width;
    }
    @property int height(){
        int height;
        SDL_GetWindowSize(this.window, cast(int*) null, &height);
        return height;
    }
    
    @property int x(){
        int x;
        SDL_GetWindowPosition(this.window, &x, cast(int*) null);
        return x;
    }
    @property int y(){
        int y;
        SDL_GetWindowPosition(this.window, cast(int*) null, &y);
        return y;
    }
    
    @property void dimensions(in Box!int box){
        this.position(box.topleft);
        this.size(box.size);
    }
    @property Box!int dimensions(){
        auto offset = this.position;
        return Box!int(offset, offset + this.size);
    }
    
    /// Index of the display containing the center of the window. Returns a negative value if something went wrong.
    @property int displayindex(){
        return SDL_GetWindowDisplayIndex(this.window);
    }
    
    @property void displaymode(in DisplayMode mode){
        this.displaymode(cast(SDL_DisplayMode) mode);
    }
    @property void displaymode(in SDL_DisplayMode mode){
        if(!SDL_SetWindowDisplayMode(this.window, &mode)){
            throw new SDLError("Failed to set display mode.");
        }
    }
    @property DisplayMode displaymode(){
        return DisplayMode(this.SDLdisplaymode);
    }
    SDL_DisplayMode SDLdisplaymode(){
        SDL_DisplayMode mode;
        if(!SDL_GetWindowDisplayMode(this.window, &mode)){
            throw new SDLError("Failed to get display mode.");
        }
        return mode;
    }
    
    bool setfullscreen(bool project = true)(in Style style){
        if(style & this.style) return true;
        if(style & FULLSCREEN_STYLES){
            if(!SDL_SetWindowFullscreen(this.window, style)){
                throw new SDLError("Failed to set fullscreen.");
            }
            static if(project) this.project();
            return true;
        }
        return false;
    }
    void togglefullscreen(bool project = true)(){
        if(this.style & FULLSCREEN_STLYES){
            this.setfullscreen!(project)(0);
        }else{
            this.setfullscreen!(project)(Style.Fullscreen);
        }
    }
    @property void fullscreen(in Style style){
        this.setfullscreen(style);
    }
    @property void fullscreen(in bool fullscreen){
        this.setfullscreen(fullscreen ? StyleFlag.Fullscreen : 0);
    }
    @property bool fullscreen(){
        return (this.style & FULLSCREEN_STYLES) != 0;
    }
    
}
