module mach.io.file.common;

private:

import core.stdc.stdio : FILE, fileno;

public:



alias FileHandle = FILE*;

version(Windows){
    alias FSChar = wchar;
}else version(Posix){
    alias FSChar = char;
}else{
    static assert(false, "File system unsupported.");
}



version(Windows){
    import core.sys.windows.windows : HANDLE;
    alias WinHandle = HANDLE;
    WinHandle winhandle(FileHandle file){
        version(CRuntime_DigitalMars){
            import core.stdc.stdio : _fdToHandle;
            return _fdToHandle(file.fileno);
        }else version(CRuntime_Microsoft){
            import core.stdc.stdio : _get_osfhandle;
            return cast(WinHandle) _get_osfhandle(file.fileno);
        }else{
            assert(false);
        }
    }
}
