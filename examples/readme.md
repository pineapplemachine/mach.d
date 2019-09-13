# Examples

## How to run

Examples in this directory can be run simply using a command such as:

``` text
rdmd -I"path/to/mach.d" "helloworld/helloworld.d"
```

Note that the **rdmd** tool is packaged with the **dmd** compiler, which can be
downloaded from the dlang website [here](https://dlang.org/download.html).

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
