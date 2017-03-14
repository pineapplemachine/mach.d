// This program plays audio samples loaded from external WAV files when the
// left or right mouse buttons are clicked.

import mach.sdl;
import mach.math;

class PlaySamples: Application{
    Sample* pulse;
    Sample* whap;
    
    // This happens when the program starts.
    override void initialize(){
        // Create a window.
        window = new Window("PlaySamples", 256, 256);
        // Load the audio samples.
        pulse = new Sample("pulse.wav");
        whap = new Sample("whap.wav");
    }
    
    // This happens when the program quits.
    override void conclude(){
        pulse.free();
        whap.free();
    }
    
    // This is the main loop!
    override void main(){
        if(mouse.pressed(Mouse.Button.Left)){
            Channel[0].play(pulse);
        }
        if(mouse.pressed(Mouse.Button.Right)){
            Channel[1].play(whap);
        }
    }
}

void main(){
    new PlaySamples().begin;
}
