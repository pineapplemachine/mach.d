// This program is an example of handling window resize events when extending
// the Application class from `mach.sdl.application`. It draws as text the
// resolution of the window, updating as the window is resized.
// It uses the Tuffy font: https://www.fontsquirrel.com/fonts/tuffy

import mach.sdl;
import mach.math;
import mach.text;

class Resize: Application{
    Font* font;
    Texture* sizetext;
    
    // This happens when the program starts.
    override void initialize(){
        // Create a window that is immediately visible and that can be resized.
        window = new Window("Resize Me!", 400, 400,
            Window.StyleFlag.Shown | Window.StyleFlag.Resizable
        );
        // Load a TTF from an external file. This will be used to render text.
        font = new Font("Tuffy_Bold.ttf", 24);
    }
    
    // This happens after the application has been fully otherwise initialized.
    // If the `refreshsize` call were placed in the `initialize` method, before
    // the window and rendering context had been fully prepared, nothing would
    // happen!
    override void postinitialize(){
        refreshsize();
    }
    
    // This method is run when the application exits.
    override void conclude(){
        font.free();
        sizetext.free();
    }
    
    // This is the main application loop.
    override void main(){
        // Nothing to see here!
    }
    
    // This method is called when a resize event is spawned, i.e. once the
    // window has been resized and the mouse button has been released.
    override void onresize(Event event){
        // Call the Application class's default implementation, which updates
        // how things are rendered to the window to account for the new resolution.
        super.onresize(event);
        // Draw the new window resolution as text in the center of the window.
        refreshsize();
    }
    
    // This method updates the window's contents.
    void refreshsize(){
        // Build the string to be drawn to the window.
        auto restext = text(window.width, " x ", window.height);
        // Render text to pixel data in RAM.
        auto surface = font.rendersolid(Color.White, restext);
        // Load it to VRAM, courtesy of OpenGL.
        sizetext = new Texture(surface);
        // Clear the previous contents of the window,
        clear();
        // Draw the text that was just rendered,
        sizetext.draw((window.size - sizetext.size) / 2);
        // And finally show it on the screen.
        swap();
    }
}

void main(){
    // This is what makes the application start when the program is run.
    new Resize().begin;
}
