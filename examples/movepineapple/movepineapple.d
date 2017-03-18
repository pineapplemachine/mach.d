// This program displays a pineapple graphic loaded from an external image
// file, and the graphic can be moved using the WASD keys.

import mach.sdl;
import mach.math;

class Pineapple: Application{
    // This is a texture; textures are things we draw onto the screen.
    Texture pineapple;
    // And this a vector to be used to determine where to draw that texture.
    Vector2!int pos;
    
    // This happens when the program starts.
    override void initialize(){
        // Make a window on the screen such that its upper-left corner is at
        // (300, 300) and its lower-right corner is at (600, 600).
        window = new Window("Pineapple!", Box!int(300, 300, 600, 600));
        // Load a texture to draw onto the window,
        pineapple = Texture("pineapple.png");
        // And initialize its position at the center.
        pos = (window.size - pineapple.size) / 2;
    }
    
    // This happens when the program quits.
    override void conclude(){
        // Free the texture from memory, now that it's no longer needed.
        pineapple.free();
    }
    
    // This is the main loop!
    override void main(){
        // First clear the screen to black,
        clear();
        // Then draw the texture,
        pineapple.draw(pos);
        // And update the window to show what was just drawn.
        swap();
        // Finally, update the position of the texture depending on what
        // keys are being pressed.
        pos.x += keys.down(KeyCode.D) - keys.down(KeyCode.A);
        pos.y += keys.down(KeyCode.S) - keys.down(KeyCode.W);
    }
}

void main(){
    // This is what makes the application start when the program is run.
    new Pineapple().begin;
}
