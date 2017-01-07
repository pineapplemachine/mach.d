module mach.error.rethrow;

private:

//

public:



/// Utility for capturing exceptions in the given code and
/// wrapping them in another exception type.
auto rethrow(alias make, alias func)(
    in size_t line = __LINE__, in string file = __FILE__
) if(is(typeof({
    func();
    throw make(Throwable.init, line, file);
}))){
    try{
        return func();
    }catch(Throwable thrown){
        throw make(thrown, line, file);
    }
}

/// ditto
auto rethrow(E, alias func)(
    in size_t line = __LINE__, in string file = __FILE__
){
    static if(is(typeof({new E(Throwable.init, line, file);}))){
        // Pattern for exceptions in mach
        return rethrow!(
            (next, line, file) => new E(next, line, file), func
        )(line, file);
    }else static if(is(typeof({new E(file, line, Throwable.init);}))){
        // Pattern for exceptions in core.exception
        return rethrow!(
            (next, line, file) => new E(file, line, next), func
        )(line, file);
    }else static if(is(typeof({new E("", file, line, Throwable.init);}))){
        // Pattern for exceptions in core.exception
        return rethrow!(
            (next, line, file) => new E("Rethrown exception.", file, line, next), func
        )(line, file);
    }else static if(is(typeof({new E(Throwable.init, file, line);}))){
        // Pattern for exceptions in core.exception
        return rethrow!(
            (next, line, file) => new E(next, file, line), func
        )(line, file);
    }else{
        static assert(false, "Unable to construct throwable object.");
    }
}



version(unittest){
    private:
    import core.exception;
    class TestException: Exception{
        this(Throwable next, size_t line, string file){
            super("Test", file, line, next);
        }
    }
    void TestRethrow(E)(){
        // Don't throw an exception
        rethrow!(E, {});
        // Don't throw, but do return a value
        assert(rethrow!(E, {return 1;}) == 1);
        // Do throw, and catch it
        bool success = false;
        try{
            rethrow!(E, {
                assert(false);
            });
        }catch(E){
            success = true;
        }
        assert(success);
    }
}
unittest{
    rethrow!((n, l, f) => new TestException(n, l, f), {return;})();
}
unittest{
    TestRethrow!Exception();
    TestRethrow!Error();
    TestRethrow!RangeError();
    TestRethrow!AssertError();
    TestRethrow!TestException();
}
