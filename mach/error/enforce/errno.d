module mach.error.enforce.errno;

private:

import core.stdc.errno : errno;
import core.stdc.string : strlen;
import std.format : format;

public:



alias Errno = typeof(errno());



class ErrnoException: Exception{
    Errno errno;
    this(string message = null, size_t line = __LINE__, string file = __FILE__) @trusted{
        this(message, .errno, line, file);
    }
    this(string message, Errno errno, size_t line = __LINE__, string file = __FILE__) @trusted{
        this.errno = errno;
        super(geterrnostring(errno, message), file, line, null);
    }
    /// Builds an exception message string given an errno and additional text data.
    static string geterrnostring(Errno errno, string message = null){
        version(CRuntime_Glibc){
            import core.stdc.string : strerror_r;
            char[1024] buf = void;
            auto errcstring = strerror_r(errno, buf.ptr, buf.length);
        }else{
            import core.stdc.string : strerror;
            auto errcstring = strerror(errno);
        }
        auto errstring = errcstring[0..errcstring.strlen].idup;
        if(message !is null){
            return "%s (Errno %s: %s)".format(message, errno, errstring);
        }else{
            return "Errno %s: %s".format(errno, errstring);
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

/// If a condition is not met, throws an ErrnoException, but only when the code
/// has been compiled with flags that cause assert statements to be evaluated.
auto asserterrno(T)(
    lazy T condition, string message = null,
    size_t line = __LINE__, string file = __FILE__
){
    assert({
        if(!condition()) throw new ErrnoException(message, line, file);
        return true;
    }());
}



version(unittest){
    private:
    import mach.error.unit;
    void TestErrno(alias errnofunc)(){
        errno = 0;
        errnofunc(true);
        fail(
            (e) => ((cast(ErrnoException) e).errno == 0),
            {errnofunc(false);}
        );
        errno = 1;
        fail(
            (e) => ((cast(ErrnoException) e).errno == 1),
            {errnofunc(false);}
        );
    }
}
unittest{
    tests("Errno", {
        tests("Enforce", {
            TestErrno!enforceerrno;
        });
        tests("Assert", {
            TestErrno!asserterrno;
        });
    });
}
