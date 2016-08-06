module mach.error.unit;

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
import std.string : indexOf;
import std.traits : isNumeric, fullyQualifiedName;

import mach.error.mixins : ErrorClassMixin;

bool contains(T)(in string str, in T sub){
    return str.indexOf(sub) >= 0;
}

public:



mixin(ErrorClassMixin!(
    "TestFailureError", "Encountered unit test failure."
));

enum DefaultMessage : string {
    True = "Value must be true",
    False = "Value must be false",
    Is = "Values must be identical",
    Equal = "Values must be equal",
    Unequal = "Values must be unequal",
    Near = "Values must be nearly equal",
    NotNear = "Values must not be nearly equal",
    Greater = "First value must be greater",
    Lesser = "First value must be lesser",
    GreaterEq = "First value must be greater than or equal to the second",
    LesserEq = "First value must be less than or equal to the second",
    Throw = "Must catch a throwable object",
    ThrowPredicate = "Must catch a throwable object meeting predicate",
    Cast = "Value must be castable to type",
    Type = "Value must be of type",
}



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



template TestCompTemplate(string condition, string defaultmessage){
    void func(A, B, size_t line = __LINE__, string file = __FILE__)(
        in A lhs, in B rhs
    ){
        func(defaultmessage, lhs, rhs, line, file);
    }
    void func(A, B)(
        in string message, in A lhs, in B rhs, in size_t line = __LINE__, in string file = __FILE__
    ){
        mixin(`testcomparison(lhs, rhs, ` ~ condition ~ `, message, line, file);`);
    }
    alias TestCompTemplate = func;
}

/// Verify that the inputs are identical.
alias testis = TestCompTemplate!("lhs is rhs", DefaultMessage.Is);
/// Verify that the inputs are equal.
alias testequal = TestCompTemplate!("lhs == rhs", DefaultMessage.Equal);
/// Verify that the inputs are not equal.
alias testnotequal = TestCompTemplate!("lhs != rhs", DefaultMessage.Unequal);
/// Verify that the first input is greater than the second.
alias testgreater = TestCompTemplate!("lhs > rhs", DefaultMessage.Greater);
/// Verify that the first input is greater than or equal to the second.
alias testgreatereq = TestCompTemplate!("lhs >= rhs", DefaultMessage.GreaterEq);
/// Verify that the first input is less than the second.
alias testlesser = TestCompTemplate!("lhs < rhs", DefaultMessage.Lesser);
/// Verify that the first input is less than or equal to the second.
alias testlessereq = TestCompTemplate!("lhs <= rhs", DefaultMessage.LesserEq);




/// Verify that the inputs are nearly equal.
void testnear(N, size_t line = __LINE__, string file = __FILE__)(
    in N lhs, in N rhs, in N epsilon
)if(isNumeric!N){
    testnear(DefaultMessage.Near, lhs, rhs, epsilon, line, file);
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
    testnotnear(DefaultMessage.NotNear, lhs, rhs, epsilon, line, file);
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
void testtrue(size_t line = __LINE__, string file = __FILE__, Bool)(in Bool value){
    testtrue(DefaultMessage.True, value, line, file);
}
/// ditto
void testtrue(Bool)(
    in string message, in Bool value, in size_t line = __LINE__, in string file = __FILE__
){
    if(!value)throw new TestFailureError(message, null, line, file);
}
/// Verify that a condition is false.
void testfalse(size_t line = __LINE__, string file = __FILE__, Bool)(in Bool value){
    testfalse(DefaultMessage.False, value, line, file);
}
/// ditto
void testfalse(Bool)(
    in string message, in Bool value, in size_t line = __LINE__, in string file = __FILE__
){
    if(value) throw new TestFailureError(message, null, line, file);
}



void testcast(Type, T, size_t line = __LINE__, string file = __FILE__)(in T value){
    testcast!(Type, T)(DefaultMessage.Cast, value, line, file);
}
void testcast(Type, T)(in T value, in size_t line = __LINE__, in string file = __FILE__){
    if(cast(Type) value is null){
        throw new TestFailureError(message, null, line, file);
    }
}



void testtype(Type, T, size_t line = __LINE__, string file = __FILE__)(in T value){
    testtype!(Type, T)(DefaultMessage.Type, value, line, file);
}
void testtype(Type, T)(in string message, in T value, in size_t line = __LINE__, in string file = __FILE__){
    static if(!is(Type == T)){
        throw new TestFailureError(
            message ~ " " ~ fullyQualifiedName!Type ~ " and " ~ fullyQualifiedName!T,
            null, line, file
        );
    }
}



void testfail(in void delegate() func, in size_t line = __LINE__, in string file = __FILE__){
    testfail(DefaultMessage.Throw, func, line, file);
}
void testfail(in string message, in void delegate() func, in size_t line = __LINE__, in string file = __FILE__){
    bool caught = false;
    try{
        func();
    }catch(Throwable thrown){
        caught = true;
    }
    if(!caught) throw new TestFailureError(message, null, line, file);
}

alias ThrownCheck = bool delegate(in Throwable thrown);
void testfail(in ThrownCheck predicate, in void delegate() func, in size_t line = __LINE__, in string file = __FILE__){
    testfail(DefaultMessage.ThrowPredicate, predicate, func, line, file);
}
void testfail(in string message, in ThrownCheck predicate, in void delegate() func, in size_t line = __LINE__, in string file = __FILE__){
    bool caught = false;
    try{
        func();
    }catch(Throwable thrown){
        caught = predicate(thrown);
    }
    if(!caught) throw new TestFailureError(message, null, line, file);
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
alias testgte = testgreatereq;
alias testlte = testlessereq;
alias fail = testfail;



version(unittest){
    import std.format : format;
}

unittest{
    fail(
        (error) => (cast(AssertError) error !is null && error.msg == "Hello"),
        {assert(false, "Hello");}
    );
    fail(
        (error) => (cast(TestFailureError) error !is null),
        {fail({assert(true);});}
    );
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
    test(1);
    test("message", true);
    testf(false);
    testf(0);
    testf("message", false);
    
    tests("group", {
        test("t", true);
        testf("f", false);
    });
    
    // TODO: Tests for missing methods (near, notnear, gteq, lteq)
    
}

unittest{
    
    // All of these should throw errors
    
    void fail(
        in void delegate() test, in string message = null,
        size_t line = __LINE__, string file = __FILE__
    ){
        testfail(
            "Error messages must be consistent",
            (error) => (
                cast(TestFailureError) error !is null &&
                error.msg.indexOf(message) == 0
            ),
            test, line, file
        );
    }
    
    fail({testneq(1, 1);}, DefaultMessage.Unequal);
    fail({testneq(1, 1.0);});
    fail({testneq("hi", "hi");});
    fail({testneq(5 - 5, 0);});
    fail({testneq([1, 2], [1, 2]);});
    fail({testneq("message", 1, 1);});
    fail({testneq("message", "abc", "abc");}, "message");
    
    fail({testeq(0, 1);}, DefaultMessage.Equal);
    fail({testeq(1, 1.5);});
    fail({testeq("hello", "world");});
    fail({testeq([1, 2], [3, 4]);});
    fail({testeq("message", 0, 1);});
    fail({testeq("message", "abc", "xyz");}, "message");
    
    fail({testlt(1, 0);}, DefaultMessage.Lesser);
    fail({testlt(2.0, 1.0);});
    fail({testlt("xyz", "abc");});
    fail({testlt("message", 1, 0);});
    fail({testlt("message", "xyz", "abc");}, "message");
    
    fail({testgt(0, 1);}, DefaultMessage.Greater);
    fail({testgt(1.0, 2.0);});
    fail({testgt("abc", "xyz");});
    fail({testgt("message", 0, 1);});
    fail({testgt("message", "abc", "xyz");}, "message");
    
    fail({testf(true);}, DefaultMessage.False);
    fail({testf("message", true);}, "message");
    fail({test(false);}, DefaultMessage.True);
    fail({test("message", false);}, "message");
    
    fail({tests("group", {
        test("t", false);
        testf("f", true);
    });}, "group: t");
    
    // TODO: Tests for missing methods (near, notnear, gteq, lteq)

}
