module mach.error.mustthrow;

private:

//

public:



/// Exception thrown when `mustthrow` fails.
class MustThrowError: Error{
    this(string message, Throwable next, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
}



/// If the operation throws an exception, catch it.
/// If it doesn't throw an exception, throw another one.
auto mustthrow(Fn)(
    Fn func, in size_t line = __LINE__, in string file = __FILE__
){
    return func.mustthrow!((e => e !is null))(line, file);
}

/// If the operation throws an exception, catch it.
/// If the thrown exception is not of the type specified, throw another one.
/// If it doesn't throw an exception, throw another one.
auto mustthrow(T: Throwable, Fn)(
    Fn func, in size_t line = __LINE__, in string file = __FILE__
){
    return func.mustthrow!((e => cast(T) e !is null))(line, file);
}

/// If the operation throws an exception, catch it.
/// If the thrown exception doesn't meet the predicate, throw another one.
/// If it doesn't throw an exception, throw another one.
auto mustthrow(alias pred, Fn)(
    Fn func, in size_t line = __LINE__, in string file = __FILE__
){
    Throwable thrown = null;
    try{
        func();
    }catch(Throwable e){
        thrown = e;
        if(!pred(e)) throw new MustThrowError(
            "Thrown exception did not meet the predicate.", e, line, file
        );
    }
    if(thrown is null) throw new MustThrowError(
        "Operation did not throw an exception.", null, line, file
    );
}



version(unittest){
    private:
    import core.exception : AssertError;
}

unittest{
    mustthrow({
        assert(false);
    });
}
unittest{
    bool thrown = false;
    try{
        mustthrow({
            return;
        });
    }catch(MustThrowError){
        thrown = true;
    }
    assert(thrown);
}

unittest{
    mustthrow!AssertError({
        assert(false);
    });
}
unittest{
    mustthrow!MustThrowError({
        mustthrow!AssertError({
            return;
        });
    });
}

unittest{
    mustthrow!(e => e.msg == "hi")({
        assert(false, "hi");
    });
}
unittest{
    mustthrow!MustThrowError({
        mustthrow!(e => e.msg == "no")({
            assert(false, "hi");
        });
    });
}
