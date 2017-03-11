# Examples

## How to run

Examples in this directory which do not depend on `mach.sdl` can be run
simply using a command such as:

``` text
rdmd -I"path/to/mach.d" "helloworld/helloworld.d"
```

Note that the **rdmd** tool is packaged with the **dmd** compiler, which can be
downloaded from the dlang website [here](https://dlang.org/download.html).

Examples which demonstrate the `mach.sdl` package depend on the Derelict
SDL2 and OpenGL3 bindings.
In order to run these examples, the [DerelictSDL2](https://github.com/DerelictOrg/DerelictSDL2),
[DerelictGL3](https://github.com/DerelictOrg/DerelictGL3), and
[DerelictUtil](https://github.com/DerelictOrg/DerelictUtil) dependencies must
be downloaded and placed in some directory and the examples can be run using
a command such as:

``` text
rdmd -I"path/to/mach.d" -I"path/to/dir/containing/derelict/deps" "movepineapple/movepineapple.d"
``` 

Note that mach typically depends on the most up-to-date versions of these
repositories, and downloading them automatically using **dub** may result in
compiler errors if the dub packages are not recent.

If running on **Windows**, the SDL2 DLLs must be available to the compiler.
If compilation fails with the above command, try placing the DLLs in the same
directory as the source file.
If running on **OSX**, the SDL2 dylibs must be installed on the system.
The DLLs and dylibs can be downloaded [here](https://www.libsdl.org/download-2.0.php)
or [here](https://www.libsdl.org/projects/).

## What's in this directory

### helloworld

Prints "Hello, world!" to stdout.

### bottles

Prints the lyrics of *99 Bottles* to stdout.

### collatz

Asks the user to input a number via stdin, and then outputs the
Collatz sequence of that number to stdout.

### jsonio

Reads json from an input file, modifies it, and then writes the
modified content to an output file.

### traversedir

Traverses this examples directory and its subdirectories and
finds and prints the paths of all the D source files contained in them.

### movepineapple

Initializes a window using `mach.sdl` and draws an image to the
screen which can be moved using the WASD keys.

### wireframe

An example of a very basic software 3D renderer using matrix transformations
and 2D rendering calls.
