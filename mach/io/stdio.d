module mach.io.stdio;

private:

import mach.range : until, asarray;
import mach.text.text : text;
import mach.io.stream : write, asrange, StdOutStream, StdErrStream, StdInStream;

public:



/// Struct provides a namespace for stdio-related functions.
struct stdio{
    /// Write some text to stdout.
    static void write(Args...)(Args args){
        StdOutStream().write(text(args));
    }
    /// Write some text to stdout, terminated by a newline.
    static void writeln(Args...)(Args args){
        StdOutStream().write(text(args), '\n');
    }
    /// Flush stdout.
    static void flushout(){
        StdOutStream().flush();
    }
    
    /// Write some text to stderr.
    static void error(Args...)(Args args){
        StdErrStream().write(text(args));
    }
    /// Write some text to stderr, terminated by a newline.
    static void errorln(Args...)(Args args){
        StdErrStream().write(text(args), '\n');
    }
    /// Flush stderr.
    static void flusherr(){
        StdErrStream().flush();
    }
    
    /// Return a range for reading data from stdin.
    static auto read(T = char)(){
        return StdInStream().asrange!T;
    }
    /// Return a string containing the content of stdin up to the next newline.
    static string readln(){
        return this.read.until!(ch => ch == '\n').asarray!(immutable(char));
    }
}
