# mach.d

A general-purpose library for the D programming language.

Be warned: "Stability" is meaningless in the context of this library. I am constantly rewriting and improving and breaking code. If it does something you're looking for, I strongly recommend against ever upgrading the version you use for that project unless you're comfortable updating your code to work with the inevitable changes made to this library.

That said, I take some pride in the thoroughness of this library's unit tests. Said tests are frequently verified on Win 7 with 32-bit dmd, and occassionally verified on OSX 10.9.5 with 64-bit dmd.

Maybe I'll think about a versioning system and proper releases once the content and foci of this library has been better-established, but that may never happen. I'm really just writing whatever interests me, or that I need to support another project I'm toying with, and this repo is here to share with the world because FOSS is the best.

The vast majority of this package depends only on D's standard library, Phobos.

The very work-in-progress mach.sdl module also requires the Derelict bindings for [SDL2](https://github.com/DerelictOrg/DerelictSDL2) and [OpenGL](https://github.com/DerelictOrg/DerelictGL3).
