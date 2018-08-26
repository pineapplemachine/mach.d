module mach.io.stream.stdiostream;

private:

import core.stdc.stdio : stdin, stdout, stderr;
import mach.io.file.sys : fread, fwrite, fflush;
import mach.error.enforce.errno : enforceerrno;

public:



struct StdInStream{
    static enum bool active = true;
    static enum bool eof = false;
    static size_t readbufferv(void* buffer, size_t size, size_t count){
        return fread(buffer, size, count, stdin);
    }
    static typeof(this) opCall(){
        typeof(this) stream; return stream;
    }
}

struct StdOutStream{
    static enum bool active = true;
    static enum bool eof = false;
    static size_t writebufferv(void* buffer, size_t size, size_t count){
        return fwrite(buffer, size, count, stdout);
    }
    static void flush(){
        enforceerrno(fflush(stdout) == 0);
    }
    static typeof(this) opCall(){
        typeof(this) stream; return stream;
    }
}

struct StdErrStream{
    static enum bool active = true;
    static enum bool eof = false;
    static size_t writebufferv(void* buffer, size_t size, size_t count){
        return fwrite(buffer, size, count, stderr);
    }
    static void flush(){
        enforceerrno(fflush(stderr) == 0);
    }
    static typeof(this) opCall(){
        typeof(this) stream; return stream;
    }
}



private version(unittest){
    import mach.io.stream.templates;
}
unittest{
    static assert(isInputStream!StdInStream);
    static assert(!isInputStream!StdOutStream);
    static assert(!isInputStream!StdErrStream);
    static assert(!isOutputStream!StdInStream);
    static assert(isOutputStream!StdOutStream);
    static assert(isOutputStream!StdErrStream);
}

/+ TODO: How can this be made into a unittest?
void main(){
    import mach.range : until;
    import mach.io.stream.io;
    import mach.io.stream.range;
    StdOutStream().write("test\n");
    auto inrange = StdInStream().asrange!char;
    auto str = inrange.until!(ch => ch == '\n');
    StdOutStream().write(str);
}
+/
