# Overview

This area is under construction. Please check back later.

https://twitter.com/PineMach/status/772921246912655360  
https://twitter.com/PineMach/status/810185839951089664

## Functionality

Current:

- [Load and draw images](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/graphics)
- [Keyboard, mouse, and joystick input](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/input)
- [TTF rendering](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/graphics/ttf)
- [Force feedback](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/haptic)

Partially Complete:

- Input helpers for smoother input checking

Planned:

- Audio playback using SDL_mixer
- Spritesheets and other forms of animation
- Cleaner interface for primitive rendering
- Bitmap font rendering
- OpenAL wrapper
- Save images
- GUI framework
- Networking via SDL_net

## Dependencies

### Bindings

- [DerelictSDL2](https://github.com/DerelictOrg/DerelictSDL2)
- [DerelictGL3](https://github.com/DerelictOrg/DerelictGL3)
- [DerelictUtil](https://github.com/DerelictOrg/DerelictUtil)

### Libraries

- [SDL2](https://www.libsdl.org/download-2.0.php), mandatory.
- [SDL_image](https://www.libsdl.org/projects/SDL_image/), only needed for image loading.
- [SDL_mixer](https://www.libsdl.org/projects/SDL_mixer/), only needed for audio.
- [SDL_ttf](https://www.libsdl.org/projects/SDL_ttf/), only needed for TTF rendering.
- [SDL_net](https://www.libsdl.org/projects/SDL_net/), only needed for networking.
