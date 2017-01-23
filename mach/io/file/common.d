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
    private import core.sys.windows.windows : HANDLE;
    private import core.sys.windows.winbase : INVALID_HANDLE_VALUE;
    
    alias WinHandle = HANDLE;
    alias WinHandleInvalid = INVALID_HANDLE_VALUE;
    
    WinHandle winhandle(FileHandle file){
        immutable no = file.fileno;
        if(no < 0) return WinHandleInvalid;
        version(CRuntime_DigitalMars){
            import core.stdc.stdio : _fdToHandle;
            return _fdToHandle(no);
        }else version(CRuntime_Microsoft){
            import core.stdc.stdio : _get_osfhandle;
            return cast(WinHandle) _get_osfhandle(no);
        }else{
            assert(false);
        }
    }
}
