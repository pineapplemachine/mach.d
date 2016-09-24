module mach.error.enforce.errno;

private:

import core.stdc.errno : errno;
import core.stdc.string : strlen;
import mach.text : text;

public:



alias Errno = typeof(errno());



class ErrnoException: Exception{
    Errno error;
    
    this(string message = null, size_t line = __LINE__, string file = __FILE__) @trusted{
        this(message, errno, line, file);
    }
    this(string message, Errno error, size_t line = __LINE__, string file = __FILE__) @trusted{
        this.error = error;
        super(geterrorstring(error, message), file, line, null);
    }
    
    /// Build an exception message string given an errno and additional text data.
    static string geterrorstring(Errno error, string message = null){
        version(CRuntime_Glibc){
            import core.stdc.string : strerror_r;
            char[1024] buf = void;
            auto errcstring = strerror_r(error, buf.ptr, buf.length);
        }else{
            import core.stdc.string : strerror;
            auto errcstring = strerror(error);
        }
        auto errstring = errcstring[0 .. errcstring.strlen].idup;
        if(message !is null){
            return text(message, " (Error code ", error, ": ", errstring, ")");
        }else{
            return text("Error code ", error, ": ", errstring);
        }
    }
}



/// If a condition is not met, throws an ErrnoException. Otherwise returns the
/// value passed as a condition.
auto enforceerrno(T)(
    T condition, string message = null,
    size_t line = __LINE__, string file = __FILE__
){
    if(!condition) throw new ErrnoException(message, line, file);
    return condition;
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Errno", {
        enforceerrno(true);
        errno = 0;
        testfail(
            (Throwable e) => ((cast(ErrnoException) e).error == 0),
            {enforceerrno(false);}
        );
        errno = 1;
        testfail(
            (Throwable e) => ((cast(ErrnoException) e).error == 1),
            {enforceerrno(false);}
        );
    });
}
