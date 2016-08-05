module mach.io.file.sys;

private:

import core.stdc.stdio : FILE;
import core.stdc.stdio : SEEK_CUR, SEEK_END, SEEK_SET;
import core.sys.windows.windows : HANDLE;

public:



public import core.stdc.stdio : fclose, fread, fwrite, fflush, fseek, ftell, feof;
public import core.stdc.stdio : fileno, tmpfile, rewind;



alias FileHandle = FILE*;

alias WinHandle = HANDLE;



version(Windows){
    //extern(C) nothrow @nogc FileHandle fopen(in wchar* filename, in wchar* mode);
    public import core.stdc.stdio : fopen;
    alias FSChar = char;  // TODO: Should this be wchar instead?
}else version(Posix){
    public import core.sys.posix.stdio : fopen;
    alias FSChar = char;
}else{
    pragma(msg, "Unknown file system. IO utilities not guaranteed to act as expected.");
    public import core.stdc.stdio : fopen;
    alias FSChar = char;
}

auto dfopen(string path, in char[] mode = "rb"){
    import std.internal.cstring : tempCString;
    auto cpath = path.tempCString!FSChar();
    auto cmode = mode.tempCString!FSChar();
    return fopen(cpath, cmode);
}



WinHandle winhandle(FileHandle file){
    version(CRuntime_DigitalMars){
        import core.stdc.stdio : _fdToHandle;
        return _fdToHandle(file.fileno);
    }else version(CRuntime_Microsoft){
        import core.stdc.stdio : _get_osfhandle;
        return _get_osfhandle(file.fileno);
    }else{
        assert(false);
    }
}



enum Seek: int{
    Cur = SEEK_CUR, /// Relative to the current position in the file
    Set = SEEK_SET, /// Relative to the beginning of the file
    End = SEEK_END, /// Relative to the end of the file (Support dubious)
}



void fsync(FileHandle file) @trusted in{
    assert(file, "Can't sync unopened file.");
}body{
    import std.format : format;
    version(Windows){
        import core.sys.windows.winbase : FlushFileBuffers, GetLastError;
        auto result = FlushFileBuffers(file.winhandle);
        assert(result != 0, "Failed to sync file, error code %s.".format(GetLastError()));
    }else{
        import core.sys.posix.unistd : fsync;
        auto result = fsync(file.fileno);
        assert(result, "Failed to sync file, error code %s.".format(result));
    }
}



version(unittest){
    private:
    import std.path;
    import mach.error.unit;
    enum string TestPath = __FILE__.dirName ~ "/test.txt";
}
unittest{
    tests("fsync", {
        auto file = dfopen(TestPath, "ab");
        testf(file.feof);
        testeq(file.ftell, 86);
        fsync(file);
        testf(file.feof);
        testeq(file.ftell, 86);
        file.fclose;
        fail("Attempt to sync closed file", {fsync(file);});
        fail("Attempt to sync nonexistent file", {fsync(FileHandle.init);});
    });
}
