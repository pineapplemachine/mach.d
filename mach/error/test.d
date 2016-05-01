module mach.error.test;

/++
    
    Makes it convenient to write unit tests with more human-readable output.
    
    Example usage:
    
    test("Never fails", true);
    testeq("Values equal", 11, 11);
    testeq("Integer addition", 5 + 5, 10);
    tests("Reals", {
        testeq("Addition", 4.0 + 3.1, 7.1);
        testeq("Subtraction", 3.5 - 0.5, 3.0);
    });
    
+/

private:

import core.exception : AssertError;
import std.format : format;
import std.conv : to;
import std.math : abs;
import std.algorithm : contains = canFind;
import std.traits : isNumeric;

import mach.error.mixins : ErrorClassMixin;

enum string TEST_TRUE_MESSAGE = "Value must be true";
enum string TEST_FALSE_MESSAGE = "Value must be false";
enum string TEST_EQUAL_MESSAGE = "Values must be equal";
enum string TEST_UNEQUAL_MESSAGE = "Values must be unequal";
enum string TEST_NEAR_MESSAGE = "Values must be nearly equal";
enum string TEST_NOTNEAR_MESSAGE = "Values must not be nearly equal";
enum string TEST_GREATER_MESSAGE = "First value must be greater";
enum string TEST_LESSER_MESSAGE = "First value must be lesser";
enum string TEST_GREATEREQ_MESSAGE = "First value must be greater than or equal to the second";
enum string TEST_LESSEREQ_MESSAGE = "First value must be less than or equal to the second";

public:

mixin(ErrorClassMixin(
    "TestFailureError", "Encountered unit test failure."
));

// Used internally by methods which compare two variables
void testcomparison(A, B)(
    in A lhs, in B rhs,
    in bool condition, in string message,
    in size_t line = __LINE__, in string file = __FILE__
){
    if(!condition){
        string astr = to!string(lhs);
        string bstr = to!string(rhs);
        string suffix;
        if(astr.contains('\n') || bstr.contains('\n')){
            suffix = ":\n" ~ astr ~ "\nand:\n" ~ bstr;
        }else if(astr.contains(' ') || bstr.contains(' ')){
            suffix = " \"" ~ astr ~ "\" and \"" ~ bstr ~ "\"";
        }else{
            suffix = " " ~ astr ~ " and " ~ bstr;
        }
        throw new TestFailureError(message ~ suffix, null, line, file);
    }
}

/// Used internally to construct comparison test methods
static string testcompmixin(string name, string condition, string defaultmessage){
    return "
        void " ~ name ~ "(A, B, size_t line = __LINE__, string file = __FILE__)(
            in A lhs, in B rhs
        ){
            " ~ name ~ "(\"" ~ defaultmessage ~ "\", lhs, rhs, line, file);
        }
        void " ~ name ~ "(A, B)(
            in string message, in A lhs, in B rhs, in size_t line = __LINE__, in string file = __FILE__
        ){
            testcomparison(lhs, rhs, " ~ condition ~ ", message, line, file);
        }
    ";
}

/// Verify that the inputs are equal.
mixin(testcompmixin("testequal", "lhs == rhs", TEST_EQUAL_MESSAGE));
/// Verify that the inputs are not equal.
mixin(testcompmixin("testnotequal", "lhs != rhs", TEST_UNEQUAL_MESSAGE));
/// Verify that the first input is greater than the second.
mixin(testcompmixin("testgreater", "lhs > rhs", TEST_GREATER_MESSAGE));
/// Verify that the first input is greater than or equal to the second.
mixin(testcompmixin("testgreatereq", "lhs >= rhs", TEST_GREATEREQ_MESSAGE));
/// Verify that the first input is less than the second.
mixin(testcompmixin("testlesser", "lhs < rhs", TEST_LESSER_MESSAGE));
/// Verify that the first input is less than or equal to the second.
mixin(testcompmixin("testlessereq", "lhs <= rhs", TEST_LESSEREQ_MESSAGE));

/// Verify that the inputs are nearly equal.
void testnear(N, size_t line = __LINE__, string file = __FILE__)(
    in N lhs, in N rhs, in N epsilon
)if(isNumeric!N){
    testnear(TEST_NEAR_MESSAGE, lhs, rhs, epsilon, line, file);
}
/// ditto
void testnear(N)(
    in string message, in N lhs, in N rhs, in N epsilon,
    in size_t line = __LINE__, in string file = __FILE__
)if(isNumeric!N){
    testequalitybase(
        lhs, rhs, abs(lhs - rhs) <= epsilon, message, line, file
    );
}

/// Verify that the inputs are not equal or nearly equal.
void testnotnear(N, size_t line = __LINE__, string file = __FILE__)(
    in N lhs, in N rhs, in N epsilon
)if(isNumeric!N){
    testnotnear(TEST_NOTNEAR_MESSAGE, lhs, rhs, epsilon, line, file);
}
/// ditto
void testnotnear(N)(
    in string message, in N lhs, in N rhs, in N epsilon,
    in size_t line = __LINE__, in string file = __FILE__
)if(isNumeric!N){
    testequalitybase(
        lhs, rhs, abs(lhs - rhs) > epsilon, message, line, file
    );
}

/// Verify that a condition is true.
void testtrue(size_t line = __LINE__, string file = __FILE__)(in bool value){
    testtrue(TEST_TRUE_MESSAGE, value, line, file);
}
/// ditto
void testtrue(
    in string message, in bool value, in size_t line = __LINE__, in string file = __FILE__
){
    if(!value)throw new TestFailureError(message, null, line, file);
}
/// Verify that a condition is false.
void testfalse(size_t line = __LINE__, string file = __FILE__)(in bool value){
    testfalse(TEST_FALSE_MESSAGE, value, line, file);
}
/// ditto
void testfalse(
    in string message, in bool value, in size_t line = __LINE__, in string file = __FILE__
){
    if(value) throw new TestFailureError(message, null, line, file);
}

void tests(in string message, in void delegate() func){
    try{
        func();
    }catch(Throwable thrown){
        thrown.msg = message ~ ": " ~ thrown.msg;
        throw thrown;
    }
}

alias test = testtrue;
alias testf = testfalse;
alias testeq = testequal;
alias testneq = testnotequal;
alias testgt = testgreater;
alias testlt = testlesser;
alias testgteq = testgreatereq;
alias testlteq = testlessereq;

version(unittest){
    import std.string : indexOf;
    import mach.error.assertf : assertf;
}

unittest{
    
    // None of these should throw errors
    
    testeq(1, 1);
    testeq(1, 1.0);
    testeq("hi", "hi");
    testeq(5 - 5, 0);
    testeq([1, 2], [1, 2]);
    testeq("message", 1, 1);
    testeq("message", "abc", "abc");
    
    testneq(0, 1);
    testneq(1, 1.5);
    testneq("hello", "world");
    testneq([1, 2], [3, 4]);
    testneq("message", 0, 1);
    testneq("message", "abc", "xyz");
    
    testgt(1, 0);
    testgt(2.0, 1.0);
    testgt("xyz", "abc");
    testgt("message", 1, 0);
    testgt("message", "xyz", "abc");
    
    testlt(0, 1);
    testlt(1.0, 2.0);
    testlt("abc", "xyz");
    testlt("message", 0, 1);
    testlt("message", "abc", "xyz");
    
    test(true);
    test("message", true);
    testf(false);
    testf("message", false);
    
    tests("group", {
        test("t", true);
        testf("f", false);
    });
    
    // TODO: Tests for missing methods (near, notnear, gteq, lteq)
    
}

unittest{
    
    // All of these should throw errors
    
    void fail(in void function() test, string message = null){
        bool caught = false;
        try{
            test();
        }catch(TestFailureError error){
            assertf(
                message is null || error.msg.indexOf(message) == 0,
                "Messages inconsistent: Expected \"%s\" and got \"%s\".", message, error.msg
            );
            caught = true;
        }
        assert(caught);
    }
    
    fail({testneq(1, 1);}, TEST_UNEQUAL_MESSAGE);
    fail({testneq(1, 1.0);});
    fail({testneq("hi", "hi");});
    fail({testneq(5 - 5, 0);});
    fail({testneq([1, 2], [1, 2]);});
    fail({testneq("message", 1, 1);});
    fail({testneq("message", "abc", "abc");}, "message");
    
    fail({testeq(0, 1);}, TEST_EQUAL_MESSAGE);
    fail({testeq(1, 1.5);});
    fail({testeq("hello", "world");});
    fail({testeq([1, 2], [3, 4]);});
    fail({testeq("message", 0, 1);});
    fail({testeq("message", "abc", "xyz");}, "message");
    
    fail({testlt(1, 0);}, TEST_LESSER_MESSAGE);
    fail({testlt(2.0, 1.0);});
    fail({testlt("xyz", "abc");});
    fail({testlt("message", 1, 0);});
    fail({testlt("message", "xyz", "abc");}, "message");
    
    fail({testgt(0, 1);}, TEST_GREATER_MESSAGE);
    fail({testgt(1.0, 2.0);});
    fail({testgt("abc", "xyz");});
    fail({testgt("message", 0, 1);});
    fail({testgt("message", "abc", "xyz");}, "message");
    
    fail({testf(true);}, TEST_FALSE_MESSAGE);
    fail({testf("message", true);}, "message");
    fail({test(false);}, TEST_TRUE_MESSAGE);
    fail({test("message", false);}, "message");
    
    fail({tests("group", {
        test("t", false);
        testf("f", true);
    });}, "group: t");
    
    // TODO: Tests for missing methods (near, notnear, gteq, lteq)

}
