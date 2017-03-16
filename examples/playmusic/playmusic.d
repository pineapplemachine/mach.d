// This program plays music loaded from an external OGG file, which can be
// paused or resumed by clicking the left mouse button.

import mach.sdl;
import mach.math;

class PlayMusic: Application{
    Music* music;
    
    // This happens when the program starts.
    override void initialize(){
        // Create a window,
        window = new Window("PlayMusic", 256, 256);
        // Load the music,
        music = new Music("music.ogg");
        // And play that music with a fade-in lasting 2000 milliseconds.
        music.play(2000);
    }
    
    // This happens when the program quits.
    override void conclude(){
        music.free();
    }
    
    // This is the main loop!
    override void main(){
        // Draw a white triangle when music is playing, and a red square when
        // the music is paused.
        clear();
        if(music.playing){
            Render.color = Color.White;
            Render.triangle(
                Vector2i(window.width - 50, window.height / 2),
                Vector2i(50, window.height - 50),
                Vector2i(50, 50),
            );
        }else{
            Render.color = Color.Red;
            Render.rect(
                Vector2i(75, 75),
                Vector2i(window.width - 75, window.height - 75)
            );
        }
        swap();
        
        // Toggle whether the music is playing or paused when the left mouse
        // button is clicked.
        if(mouse.pressed(Mouse.Button.Left)){
            if(music.playing){
                music.pause();
            }else{
                music.resume();
            }
        }
    }
}

void main(){
    // This is what makes the application start when the program is run.
    new PlayMusic().begin;
}
