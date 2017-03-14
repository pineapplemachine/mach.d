# Overview

To see `mach.sdl` in action, take a look at the [examples]
(https://github.com/pineapplemachine/mach.d/tree/master/examples)
section of this repository.

## Functionality

Current:

- [Load and draw images](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/graphics)
- [TTF rendering](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/graphics/ttf)
- [Audio playback](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/audio)
- [Keyboard, mouse, and joystick input](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/input)
- [Force feedback](https://github.com/pineapplemachine/mach.d/tree/master/mach/sdl/haptic)

Partially Complete:

- Input helpers for smoother input checking
- Cleaner interface for primitive rendering

Planned:

- Spritesheets and other forms of animation
- Bitmap font rendering
- OpenAL audio support
- Save images
- GUI widgets
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
