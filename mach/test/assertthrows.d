module mach.test.assertthrows;

private:

/++ Docs

This module implements an `assertthrows` function which, in assert
builds, will produce a descriptive assertion error when a given input
function fails to throw an exception.

The `assertthrows` function comes in two varieties; one that asserts
the input function throws _any_ exception, and another that asserts the
input function throws a specific type of exception.
Both functions return the thrown exception, or null if no exception was
thrown. (The functions always return null in non-assert builds.)

+/

unittest{ /// Example
    // Function throws an exception, as expected.
    assertthrows({
        throw new Exception("Expected error");
    });
    // The interior function does not throw, causing `assertthrows` to
    // produce an assertion error, satisfying the exterior `assertthrows`
    assertthrows({
        assertthrows({}); // Throws an AssertError
    });
}

unittest{ /// Example
    import core.exception : RangeError, AssertError;
    // Failed assertions throw an AssertError
    assertthrows!AssertError({
        assert(false);
    });
    // Interior function doesn't throw anything
    assertthrows({
        assertthrows!Exception({});
    });
    // Interior function throws a wrong type of error
    assertthrows({
        assertthrows!RangeError({
            assert(false, "Not a RangeError.");
        });
    });
}

/++ Docs

The `assertthrows` function returns the Throwable object that was thrown,
if possible, and `null` otherwise.
It always returns `null` in non-assert builds; `assertthrows` is a no-op
in non-assert builds.

+/

unittest{ /// Example
    Throwable thrown = assertthrows({
        throw new Exception("Return value test");
    });
    assert(thrown.msg == "Return value test");
}

public:

/// Assert that the delegate throws an exception
/// Returns the thrown exception
/// Returns null in non-assert builds
Throwable assertthrows(void delegate() dg){
    version(assert){
        Throwable caught = null;
        try{
            dg();
        }catch(Throwable throwable){
            caught = throwable;
        }
        assert(caught !is null, "Delegate did not throw.");
        return caught;
    }else{
        return null; // Do nothing in non-assert version
    }
}

/// Assert that the delegate throws an exception of the given type
/// Returns the thrown exception
/// Returns null in non-assert builds
Type assertthrows(Type)(void delegate() dg){
    version(assert){
        Type caught = null;
        try{
            dg();
        }catch(Throwable throwable){
            caught = cast(Type) throwable;
            assert(caught !is null,
                "Delegate threw a different type of error."
            );
        }
        assert(caught !is null, "Delegate did not throw.");
        return caught;
    }else{
        return null; // Do nothing in non-assert version
    }
}

/// Make sure assertthrows fails with a bad type argument
unittest{
    static assert(!is(typeof(assertthrows!int({}))));
    static assert(!is(typeof(assertthrows!int*({}))));
}

/// Test return value with Throwable type constraint
unittest{
    Throwable thrown = assertthrows!Exception({
        throw new Exception("Return value test");
    });
    assert(thrown.msg == "Return value test");
}
