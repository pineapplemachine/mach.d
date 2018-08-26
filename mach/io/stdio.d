module mach.io.stdio;

private:

import mach.range.asarray : asarray;
import mach.range.select : until;
import mach.text.text : text;
import mach.io.stream : write, asrange, StdOutStream, StdErrStream, StdInStream;

/++ Docs

This module provides an abstraction for common uses of the stdin, stdout, and
stderr, streams as implemented in `mach.io.stream.stdiostream`.

It defines an `stdio` namespace with several methods:
- `write`, `writeln`, and `flushout` for interacting with stdout.
- `error`, `errorln`, and `flusherr` for interacting with stderr.
- `read` and `readln` for interacting with stdin.

The `stdio.write`, `stdio.writeln`, `stdio.error`, and `stdio.errorln` methods
accept any number of arguments, which are all converted to strings using
`mach.text.str` and then concatenated.
The resulting string is outputted to stdout or stderr and, in the case of
`stdio.writeln` and `stdio.errorln`, also terminated by a newline character.

``` D
stdio.writeln("Hello, world!");
stdio.errorln("Oh no!");
```

`stdio.read` returns a range for enumerating the contents of the stdin stream.
By default, the range has elements of type `char`.
The method optionally accepts a template argument defining the element type,
for when a type other than `char` is desired.

The `stdio.readln` method acquires data from stdin until a newline character
is encountered. It always returns a string.

``` D
stdio.writeln("What is your name?");
string name = stdio.readln();
stdio.writeln("Hello, ", name, "!");
```

+/

public:



/// Struct provides a namespace for stdio-related functions.
struct stdio{
    @disable this();
    
    static @property auto stdin(){
        return StdInStream();
    }
    static @property auto stdout(){
        return StdOutStream();
    }
    static @property auto stderr(){
        return StdErrStream();
    }
    
    /// Write some text to stdout.
    static void write(Args...)(Args args){
        static if(Args.length) stdout.write(text(args));
    }
    /// Write some text to stdout, terminated by a newline.
    static void writeln(Args...)(Args args){
        stdout.write(text(args, '\n'));
    }
    /// Flush stdout.
    static void flushout(){
        stdout.flush();
    }
    
    /// Write some text to stderr.
    static void error(Args...)(Args args){
        static if(Args.length) stderr.write(text(args));
    }
    /// Write some text to stderr, terminated by a newline.
    static void errorln(Args...)(Args args){
        stderr.write(text(args, '\n'));
    }
    /// Flush stderr.
    static void flusherr(){
        stderr.flush();
    }
    
    /// Return a range for reading data from stdin.
    static auto read(T = char)(){
        return stdin.asrange!T;
    }
    /// Return a string containing the content of stdin up to the next
    /// newline character.
    static string readln(T = immutable char)(){
        return this.read.until!(ch => ch == '\n').asarray!T;
    }
}
