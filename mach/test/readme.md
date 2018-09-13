# mach.test


This package contains utilities for writing and running unit tests.


## mach.test.assertthrows


This module implements an `assertthrows` function which, in assert
builds, will produce a descriptive assertion error when a given input
function fails to throw an exception.

The `assertthrows` function comes in two varieties; one that asserts
the input function throws _any_ exception, and another that asserts the
input function throws a specific type of exception.
Both functions return the thrown exception, or null if no exception was
thrown. (The functions always return null in non-assert builds.)

``` D
// Function throws an exception, as expected.
assertthrows({
    throw new Exception("Expected error");
});
// The interior function does not throw, causing `assertthrows` to
// produce an assertion error, satisfying the exterior `assertthrows`
assertthrows({
    assertthrows({}); // Throws an AssertError
});
```

``` D
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
```


The `assertthrows` function returns the Throwable object that was thrown,
if possible, and `null` otherwise.
It always returns `null` in non-assert builds; `assertthrows` is a no-op
in non-assert builds.

``` D
Throwable thrown = assertthrows({
    throw new Exception("Return value test");
});
assert(thrown.msg == "Return value test");
```


