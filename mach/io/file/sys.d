module mach.io.file.sys;

private:

import core.stdc.stdio : FILE;
import core.stdc.stdio : SEEK_CUR, SEEK_END, SEEK_SET;
import std.internal.cstring : tempCString;
import mach.error : ThrowableClassMixin;

public:



mixin(ThrowableClassMixin!(`FileException`, `Exception`, `Failed to perform file operation.`));



public import core.stdc.stdio : fclose, fread, fwrite, fflush, fseek, ftell, feof;
public import core.stdc.stdio : fileno, tmpfile, rewind;



alias FileHandle = FILE*;

version(Windows){
    import core.sys.windows.windows : HANDLE;
    alias WinHandle = HANDLE;
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
}



version(Windows){
    //extern(C) nothrow @nogc FileHandle fopen(in wchar* filename, in wchar* mode);
    public import core.stdc.stdio : fopen;
    alias FSChar = char;  // TODO: Should this be wchar instead?
}else version(Posix){
    public import core.sys.posix.stdio : fopen;
    alias FSChar = char;
}else{
    pragma(msg, "Unrecognized platform. IO utilities not guaranteed to act as expected.");
    public import core.stdc.stdio : fopen;
    alias FSChar = char;
}

auto dfopen(string path, in char[] mode = "rb"){
    auto cpath = path.tempCString!FSChar();
    auto cmode = mode.tempCString!FSChar();
    return fopen(cpath, cmode);
}



version(Windows){
    public import core.sys.windows.stat : stat, fstat, Stat = struct_stat;
}else{
    public import core.sys.posix.sys.stat : stat, fstat, Stat = stat_t;
}

auto dstat(string path){
    Stat st = void;
    version(Windows) stat(cast(char*) path.ptr, &st);
    else stat(path.ptr, &st);
    return st;
}

auto dfstat(FileHandle file){
    Stat st = void;
    auto result = fstat(file.fileno, &st);
    if(result < 0) throw new FileException;
    return st;
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
        assert(result == 0, "Failed to sync file, error code %s.".format(result));
    }
}



version(unittest){
    private:
    import std.path;
    import mach.error.unit;
    enum string TestPath = __FILE__.dirName ~ "/sys.txt";
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
    tests("stat", {
        testeq("dstat", dstat(TestPath).st_size, 86);
        auto file = dfopen(TestPath, "rb");
        testeq("dfstat", dfstat(file).st_size, 86);
        file.fclose;
    });
}
