module mach.sdl.audio.fading;

private:

import derelict.sdl2.mixer;

public:



/// Enumeration of possible audio fading states.
static enum AudioFading: Mix_Fading{
    None = MIX_NO_FADING,
    In = MIX_FADING_OUT,
    Out = MIX_FADING_IN,
}
