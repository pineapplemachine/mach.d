module mach.sdl.window;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import mach.traits : isNumeric;
import mach.range : filter, asarray;
import mach.text.cstring : tocstring, fromcstring;
import mach.sdl.error : SDLException, GLException;
import mach.sdl.init : GLSettings;
import mach.sdl.glenum : PixelsFormat, PixelsType, ColorBufferMode;
import mach.sdl.graphics.color : Color;
import mach.sdl.graphics.mask : Mask;
import mach.sdl.graphics.displaymode : DisplayMode;
import mach.sdl.graphics.surface : Surface;
import mach.math.box : Box;
import mach.math.vector : Vector, Vector2;
import mach.math.matrix : Matrix4;

import mach.io.log;

public:



class Window{
    static enum string DefaultTitle = "D Application";
    
    alias ID = uint;
    alias Style = uint;
    static enum Style DefaultStyle = StyleFlag.Shown;
    static enum Style FullscreenStyles = StyleFlag.Fullscreen | StyleFlag.Desktop;
    
    static enum StyleFlag : uint {
        /// Default is Shown
        Default = Shown,
        /// Window is fullscreen
        Fullscreen = SDL_WINDOW_FULLSCREEN,
        /// Window has Desktop Fullscreen
        Desktop = SDL_WINDOW_FULLSCREEN_DESKTOP,
        /// Show the Window immediately
        Shown = SDL_WINDOW_SHOWN,
        /// Hide the Window immediately
        Hidden = SDL_WINDOW_HIDDEN,
        /// The Window has no border
        Borderless = SDL_WINDOW_BORDERLESS,
        /// Window is resizable
        Resizable = SDL_WINDOW_RESIZABLE,
        /// Maximize the Window immediately
        Maximized = SDL_WINDOW_MAXIMIZED,
        /// Minimize the Window immediately
        Minimized = SDL_WINDOW_MINIMIZED,
        /// Grab the input inside the window
        InputGrabbed = SDL_WINDOW_INPUT_GRABBED,
        /// The Window has input (keyboard) focus
        InputFocus = SDL_WINDOW_INPUT_FOCUS,
        /// The Window has mouse focus
        MouseFocus = SDL_WINDOW_MOUSE_FOCUS,
        /// window has mouse captured (unrelated to InputGrabbed)
        MouseCapture = SDL_WINDOW_MOUSE_CAPTURE,
        /// Window should be created in high-DPI mode if supported
        AllowHighDPI = SDL_WINDOW_ALLOW_HIGHDPI,
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
        if(this.window !is null){
            Window[] newinstances;
            newinstances.reserve(this.instances.length - 1);
            foreach(instance; instances){
                if(instance !is this) newinstances ~= instances;
            }
            this.instances = newinstances;
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
    
    private static auto centeredbox(in int width, in int height){
        immutable position = (DisplayMode.desktop.size - Vector2!int(width, height)) / 2;
        return Box!int(width, height) + position;
    }
    
    this(
        in int width, in int height,
        in Style style = DefaultStyle,
        in VSync vsync = VSync.Disabled,
        in GLSettings settings = GLSettings.Default
    ){
        this(DefaultTitle, width, height, style, vsync);
    }
    this(
        in string title, in int width, in int height,
        in Style style = DefaultStyle,
        in VSync vsync = VSync.Disabled,
        in GLSettings settings = GLSettings.Default
    ){
        this(title, this.centeredbox(width, height), style, vsync);
    }
    this(
        in string title, in Vector2!int size,
        in Style style = DefaultStyle,
        in VSync vsync = VSync.Disabled,
        in GLSettings settings = GLSettings.Default
    ){
        this(title, size.x, size.y, style, vsync);
    }
    this(
        in string title, in Box!int view,
        in Style style = DefaultStyle,
        in VSync vsync = VSync.Disabled,
        in GLSettings settings = GLSettings.Default
    ){
        // Actually create the window
        this.window = SDL_CreateWindow(
            title.tocstring,
            view.x, view.y, view.width, view.height,
            style | SDL_WINDOW_OPENGL
        );
        if(!window) throw new SDLException("Failed to create SDL_Window.");
        
        this.context = SDL_GL_CreateContext(window);
        if(!this.context) throw new SDLException("Failed to create SDL_GLContext.");
        
        this.glsettings(settings);        
        this.projection(Box!int(view.width, view.height));
        this.clearcolor(0, 0, 0, 1);
        this.vsync(vsync);
        this.register();
    }
    
    this(SDL_Window* window, SDL_GLContext context){
        this.window = window;
        this.context = context;
        if(!this.window) throw new SDLException("Invalid window.");
        if(!this.context) throw new SDLException("Invalid GL context.");
        if(SDL_GL_MakeCurrent(this.window, this.context) != 0){
            throw new SDLException("Failed to set GLContext for rending to window.");
        }
        this.project();
        this.clearcolor(0, 0, 0, 1);
        this.register();
    }
    
    ~this(){
        this.free();
        this.unregister();
    }
    
    void free(){
        this.freecontext();
        this.freewindow();
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
    
    @property void projection(N)(in Vector!(2, N) size){
        this.projection(Box!N(size));
    }
    @property void projection(N)(in Box!N screen){
        glViewport(screen.x, screen.y, screen.width, screen.height);
        this.projection(Matrix4!float.glortho(
            screen.minx, screen.maxx, screen.miny, screen.maxy
        ));
    }
    @property void projection(in Matrix4!float matrix){
        glMatrixMode(GL_PROJECTION);
        glLoadMatrixf(cast(const(float*)) &matrix);
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
            throw new SDLException("Failed to set swap interval.");
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
    
    @property void clearcolor(T)(in Color!T color){
        this.clearcolor(color.r!float, color.g!float, color.b!float, color.a!float);
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
                throw new SDLException("Failed to make window context current.");
            }
        }
    }
    
    @property string title(){
        return SDL_GetWindowTitle(this.window).fromcstring;
    }
    @property void title(string title){
        // TODO: Make sure the string returned by tocstring doesn't get eaten
        // by the GC and cause an error
        SDL_SetWindowTitle(this.window, title.tocstring);
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
        if(!surface) throw new SDLException("Failed to get window surface.");
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
        GLException.enforce();
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
    
    @property auto position(){
        int x, y;
        SDL_GetWindowPosition(this.window, &x, &y);
        return Vector2!int(x, y);
    }
    @property void position(T)(in Vector!(2, T) position){
        SDL_SetWindowPosition(this.window, cast(int) position.x, cast(int) position.y);
    }
    
    @property auto size(){
        int x, y;
        SDL_GetWindowSize(this.window, &x, &y);
        return Vector2!int(x, y);
    }
    @property void size(T)(in Vector!(2, T) size){
        SDL_SetWindowSize(this.window, cast(int) size.x, cast(int) size.y);
        this.projection(Box!int(size.x, size.y));
    }
    
    @property auto minsize(){
        int x, y;
        SDL_GetWindowMinimumSize(this.window, &x, &y);
        return Vector2!int(x, y);
    }
    @property void minsize(T)(in Vector!(2, T) size){
        SDL_SetWindowMinimumSize(this.window, cast(int) size.x, cast(int) size.y);
    }
   @property auto maxsize(){
        int x, y;
        SDL_GetWindowMaximumSize(this.window, &x, &y);
        return Vector2!int(x, y);
    }
    @property void maxsize(T)(in Vector!(2, T) size){
        SDL_SetWindowMaximumSize(this.window, cast(int) size.x, cast(int) size.y);
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
            throw new SDLException("Failed to set display mode.");
        }
    }
    @property DisplayMode displaymode(){
        return DisplayMode(this.SDLdisplaymode);
    }
    SDL_DisplayMode SDLdisplaymode(){
        SDL_DisplayMode mode;
        if(!SDL_GetWindowDisplayMode(this.window, &mode)){
            throw new SDLException("Failed to get display mode.");
        }
        return mode;
    }
    
    bool setfullscreen(bool project = true)(in Style style){
        if(style & this.style) return true;
        if(style & FullscreenStyles){
            if(!SDL_SetWindowFullscreen(this.window, style)){
                throw new SDLException("Failed to set fullscreen.");
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
        return (this.style & FullscreenStyles) != 0;
    }
    
}
