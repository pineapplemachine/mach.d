module mach.io.fileutil;

private:

import core.stdc.stdio : fileno, File = FILE;

public:



auto windowshandle(File* file){
    //import core.sys.windows.windows : WinHandle = HANDLE;
    version(CRuntime_DigitalMars){
        import core.stdc.stdio : _fdToHandle;
        return cast(File*) _fdToHandle(file.fileno);
    }else version(CRuntime_Microsoft){
        import core.stdc.stdio :  _get_osfhandle;
        return cast(File*) _get_osfhandle(file.fileno);
    }else{
        assert(false);
    }
}



void fsync(File* file) @trusted in{
    assert(file, "Can't sync unopened file.");
}body{
    version(Windows){
        extern(Windows) void FlushFileBuffers(File* file);
        FlushFileBuffers(windowshandle(file));
    }else{
        import core.sys.posix.unistd : fsync;
        import std.format : format;
        auto result = fsync(file.fileno);
        assert(result, "Failed to sync file, error code %s.".format(result));
    }
}
