module mach.sdl.haptic.effecttype;

private:

import derelict.sdl2.types;

public:

/// https://wiki.libsdl.org/SDL_HapticPeriodic#type
static enum HapticEffectType{
    // Constant
    Constant = SDL_HAPTIC_CONSTANT,
    // Periodic
    Sine = SDL_HAPTIC_SINE,
    Triangle = SDL_HAPTIC_TRIANGLE,
    SawtoothUp = SDL_HAPTIC_SAWTOOTHUP,
    SawtoothDown = SDL_HAPTIC_SAWTOOTHDOWN,
    // Condition
    Spring = SDL_HAPTIC_SPRING, /// Effect based on axis position/axes positions
    Damper = SDL_HAPTIC_DAMPER, /// Effect based on axis velocity/axes velocities
    Inertia = SDL_HAPTIC_INERTIA, /// Effect based on axis/axes acceleration
    Friction = SDL_HAPTIC_FRICTION, /// Effect based on axis/axes movement/movements
    // Ramp
    Ramp = SDL_HAPTIC_RAMP,
    // Left/Right
    LeftRight = SDL_HAPTIC_LEFTRIGHT,
    // Custom
    Custom = SDL_HAPTIC_CUSTOM,
}
