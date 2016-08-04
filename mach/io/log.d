module mach.io.log;

private:

import std.stdio : writeln, stdout;
import std.conv : to;
import mach.traits : hash;

public:



/// Immediately writes a line to stdout together with a file path, function
/// identifier, and line number. Intended to help debug misbehaving code.
void log(
    size_t line = __LINE__, string file = __FILE__, string func = __FUNCTION__
)(){
    log!(line, file, func)("log");
}

/// ditto
void log(
    size_t line = __LINE__, string file = __FILE__, string func = __FUNCTION__, Args...
)(
    auto ref Args args
){
    writeln(args, " in " ~ func ~ " at " ~ file ~ "(" ~ to!string(line) ~ ")");
    stdout.flush();
}



/// As the log function, but will output only once even if the same statement
/// is evaluated multiple times. (Per thread. Probably.)
void logonce(
    size_t line = __LINE__, string file = __FILE__, string func = __FUNCTION__
)(){
    logonce!(line, file, func)("log");
}

/// ditto
void logonce(
    size_t line = __LINE__, string file = __FILE__, string func = __FUNCTION__, Args...
)(
    auto ref Args args
){
    struct logged{
        size_t line; string file;
        ulong toHash() nothrow @trusted{
            return this.line ^ this.file.hash;
        }
    }
    static size_t[logged] logrecord;
    
    auto thislogged = logged(line, file);
    if(thislogged !in logrecord){
        log!(line, file, func)(args);
        logrecord[thislogged] = 1;
    }
}



unittest{
    // TODO: How to verify output programmatically?
    //log;
    //log("test");
    //log("test", "test");
    //foreach(_; 0 .. 10){
    //    logonce;
    //    logonce("test");
    //}
}
