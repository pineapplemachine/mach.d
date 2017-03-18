// This program plays audio samples loaded from external WAV files when the
// left or right mouse buttons are clicked.

import mach.sdl;
import mach.math;

class PlaySamples: Application{
    MixSample pulse;
    MixSample whap;
    
    // This happens when the program starts.
    override void initialize(){
        // Create a window.
        window = new Window("PlaySamples", 256, 256);
        // Load the audio samples.
        pulse = MixSample("pulse.wav");
        whap = MixSample("whap.wav");
    }
    
    // This happens when the program quits.
    override void conclude(){
        pulse.free();
        whap.free();
    }
    
    // This is the main loop!
    override void main(){
        if(mouse.pressed(Mouse.Button.Left)){
            MixChannel[0].play(pulse);
        }
        if(mouse.pressed(Mouse.Button.Right)){
            MixChannel[1].play(whap);
        }
    }
}

void main(){
    new PlaySamples().begin;
}
