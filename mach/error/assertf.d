module mach.error.assertf;

private:

import core.exception : AssertError;
import std.format : format;

public:

/// Throws an AssertError when the condition is not met.
void assertf(
    size_t line = __LINE__, string file = __FILE__, Args...
)(
    lazy bool condition, in string message, in Args args
){
    assertf(file, line, condition, message, args);
}

void assertf(Args...)(in string file, in size_t line, lazy bool condition, in string message, in Args args){
    assert({
        // Putting the function body in an assert statement means it only
        // evaluates when assertions are normally evaluated, i.e. not in
        // release mode.
        if(!condition()) throw new AssertError(format(message, args), file, line, null);
        return true;
    }());
}

unittest{
    
    void fail(in void function() test, string message = null){
        bool caught = false;
        try{
            test();
        }catch(AssertError error){
            if(message is null || error.msg == message) caught = true;
        }
        assert(caught);
    }
    
    assertf(true, "hello %s", "world");
    assertf((2 * 5) == (10 * 1), "hello %s", "world");
    
    fail({assertf(false, "hello %s", "world");}, "hello world");
    fail({assertf((2 * 5) != (10 * 1), "hello %s", "world");}, "hello world");
    
}
