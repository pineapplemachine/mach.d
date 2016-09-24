module mach.error.enforce.syserror;

version(Windows):

private:

import std.windows.syserror : GetLastError, sysErrorString;
import mach.text : text;

public:



alias SysError = typeof(GetLastError());



class SysErrorException: Exception{
    SysError error;
    
    this(string message = null, size_t line = __LINE__, string file = __FILE__) @trusted{
        this(message, GetLastError(), line, file);
    }
    this(string message, SysError error, size_t line = __LINE__, string file = __FILE__) @trusted{
        this.error = error;
        super(geterrorstring(error, message), file, line, null);
    }
    
    static string geterrorstring(SysError error, string message = null){
        auto errstring = sysErrorString(error);
        if(message !is null){
            return text(message, " (Error code ", error, ": ", errstring, ")");
        }else{
            return text("Error code ", error, ": ", errstring);
        }
    }
}



auto enforcesyserror(T)(
    T condition, string message = null,
    size_t line = __LINE__, string file = __FILE__
){
    if(!condition) throw new SysErrorException(message, line, file);
    return condition;
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Windows error", {
        //enforcesyserror(true);
        //errno = 0;
        //fail(
        //    (e) => ((cast(ErrnoException) e).errno == 0),
        //    {enforceerrno(false);}
        //);
        //errno = 1;
        //fail(
        //    (e) => ((cast(ErrnoException) e).errno == 1),
        //    {enforceerrno(false);}
        //);
    });
}

