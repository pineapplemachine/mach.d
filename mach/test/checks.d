module mach.test.checks;

private:

import mach.traits : isString;
import mach.text.str : str;

public:



class TestFailureException: Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
    this(string message, string inputs, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message ~ " " ~ inputs, file, line, next);
    }
    
    static string inputstring(Args...)(auto ref Args args){
        string result = "";
        foreach(arg; args){
            alias Arg = typeof(arg);
            if(result.length) result ~= " and ";
            auto immutable argstr = str(arg);
            static if(isString!Arg){
                result ~= '`' ~ argstr ~ '`';
            }else{
                result ~= argstr;
            }
        }
        return result;
    }
}

class TestFailureUnhandledException: TestFailureException{
    this(Throwable next, size_t line = __LINE__, string file = __FILE__){
        super("Unhandled error occurred.", next, line, file);
    }
}

class TestFailureMustThrowException: TestFailureException{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Operation must throw an exception.", null, line, file);
    }
}
class TestFailureThrowPredicateException: TestFailureException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Operation must throw an exception meeting the predicate.", next, line, file);
    }
}
class TestFailureNoThrowException: TestFailureException{
    this(Throwable next, size_t line = __LINE__, string file = __FILE__){
        super("Operation must not throw an exception.", next, line, file);
    }
}

class TestFailureTrueException: TestFailureException{
    this(T)(auto ref T value, size_t line = __LINE__, string file = __FILE__){
        super("Value must be true.", this.inputstring(value), next, line, file);
    }
}
class TestFailureFalseException: TestFailureException{
    this(T)(auto ref T value, size_t line = __LINE__, string file = __FILE__){
        super("Value must be false.", this.inputstring(value), next, line, file);
    }
}
class TestFailureNullException: TestFailureException{
    this(T)(auto ref T value, size_t line = __LINE__, string file = __FILE__){
        super("Value must be null.", this.inputstring(value), next, line, file);
    }
}
class TestFailureNotNullException: TestFailureException{
    this(T)(auto ref T value, size_t line = __LINE__, string file = __FILE__){
        super("Value must not be null.", this.inputstring(value), next, line, file);
    }
}

class TestFailureEqualityException: TestFailureException{
    this(A, B)(auto ref A a, auto ref B b, size_t line = __LINE__, string file = __FILE__){
        super("Values must be equal.", this.inputstring(a, b), next, line, file);
    }
}
class TestFailureInequalityException: TestFailureException{
    this(A, B)(auto ref A a, auto ref B b, size_t line = __LINE__, string file = __FILE__){
        super("Values must not be equal.", this.inputstring(a, b), next, line, file);
    }
}
class TestFailureIdenticalException: TestFailureException{
    this(A, B)(auto ref A a, auto ref B b, size_t line = __LINE__, string file = __FILE__){
        super("Values must be identical.", this.inputstring(a, b), next, line, file);
    }
}
class TestFailureNotIdenticalException: TestFailureException{
    this(A, B)(auto ref A a, auto ref B b, size_t line = __LINE__, string file = __FILE__){
        super("Values must not be identical.", this.inputstring(a, b), next, line, file);
    }
}

class TestFailureGreaterThanException: TestFailureException{
    this(A, B)(auto ref A a, auto ref B b, size_t line = __LINE__, string file = __FILE__){
        super("First value must be greater than the second.", this.inputstring(a, b), next, line, file);
    }
}
class TestFailureLessThanException: TestFailureException{
    this(A, B)(auto ref A a, auto ref B b, size_t line = __LINE__, string file = __FILE__){
        super("First value must be less than the second.", this.inputstring(a, b), next, line, file);
    }
}
class TestFailureGreaterThanEqException: TestFailureException{
    this(A, B)(auto ref A a, auto ref B b, size_t line = __LINE__, string file = __FILE__){
        super("First value must be greater than or equal to the second.", this.inputstring(a, b), next, line, file);
    }
}
class TestFailureLessThanEqException: TestFailureException{
    this(A, B)(auto ref A a, auto ref B b, size_t line = __LINE__, string file = __FILE__){
        super("First value must be less than or equal to the second.", this.inputstring(a, b), next, line, file);
    }
}

class TestFailurePredicateException: TestFailureException{
    this(T...)(size_t line, string file, T values){
        super("Values must satisfy the predicate.", this.inputstring(values), next, line, file);
    }
}
class TestFailureNotPredicateException: TestFailureException{
    this(T...)(size_t line, string file, T values){
        super("Values must not satisfy the predicate.", this.inputstring(values), next, line, file);
    }
}



/// If the input does not evaluate as truthy, throw a TestFailureException.
void testtrue(T)(
    auto ref T value, in size_t line = __LINE__, in string file = __FILE__
){
    if(!value){
        throw new TestFailureTrueException(value, line, file);
    }
}

/// If the input does not evaluate as falsey, throw a TestFailureException.
void testfalse(T)(
    auto ref T value, in size_t line = __LINE__, in string file = __FILE__
){
    if(value){
        throw new TestFailureFalseException(value, line, file);
    }
}



void testnull(T)(
    auto ref T value, in size_t line = __LINE__, in string file = __FILE__
){
    if(value !is null){
        throw new TestFailureNullException(value, line, file);
    }
}

void testnotnull(T)(
    auto ref T value, in size_t line = __LINE__, in string file = __FILE__
){
    if(value is null){
        throw new TestFailureNotNullException(value, line, file);
    }
}



/// If the inputs are not equal to each other, throw a TestFailureException.
void testequal(A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
){
    if(a != b){
        throw new TestFailureEqualityException(a, b, line, file);
    }
}

/// If the inputs are equal to each other, throw a TestFailureException.
void testnotequal(A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
){
    if(a == b){
        throw new TestFailureInequalityException(a, b, line, file);
    }
}

/// If the inputs are not identical, throw a TestFailureException.
void testsameidentity(A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
){
    if(a !is b){
        throw new TestFailureIdenticalException(a, b, line, file);
    }
}

/// If the inputs are identical, throw a TestFailureException.
void testdiffidentity(A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
){
    if(a is b){
        throw new TestFailureNotIdenticalException(a, b, line, file);
    }
}



/// If the first input is not greater than the second,
/// throw a TestFailureException.
void testgreater(A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
){
    if(!(a > b)){
        throw new TestFailureGreaterThanException(a, b, line, file);
    }
}

/// If the first input is not less than the second,
/// throw a TestFailureException.
void testless(A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
){
    if(!(a < b)){
        throw new TestFailureLessThanException(a, b, line, file);
    }
}

/// If the first input is not greater than or equal to the second,
/// throw a TestFailureException.
void testgreatereq(A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
){
    if(!(a >= b)){
        throw new TestFailureGreaterThanEqException(a, b, line, file);
    }
}

/// If the first input is not less than or equal to the second,
/// throw a TestFailureException.
void testlesseq(A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
){
    if(!(a <= b)){
        throw new TestFailureLessThanEqException(a, b, line, file);
    }
}



/// If the passed delegate does not itself throw an exception,
/// throw a TestFailureException.
void testthrow(Fn)(Fn func, size_t line = __LINE__, string file = __FILE__){
    Throwable caught = null;
    try{
        func();
    }catch(Throwable throwable){
        caught = throwable;
    }
    if(caught is null){
        throw new TestFailureMustThrowException(line, file);
    }
}

/// If the passed delegate does not itself throw an exception, or if it does
/// throw an exception but the thrown object is not of the type specified,
/// throw a TestFailureException.
void testthrow(E, Fn)(
    Fn func, size_t line = __LINE__, string file = __FILE__
){
    testthrow((Throwable e) => (cast(E) e !is null), func, line, file);
}

/// If the passed delegate does not itself throw an exception, or if it does
/// throw an exception but the thrown object does not meet the predicate,
/// throw a TestFailureException.
void testthrow(Pred, Fn)(
    Pred pred, Fn func, size_t line = __LINE__, string file = __FILE__
){
    Throwable caught = null;
    try{
        func();
    }catch(Throwable throwable){
        caught = throwable;
    }
    if(caught is null || !pred(caught)){
        throw new TestFailureThrowPredicateException(caught, line, file);
    }
}

/// If the passed delegate itself throws an exception,
/// throw a TestFailureException.
void testnothrow(Fn)(
    Fn func, in size_t line = __LINE__, in string file = __FILE__
){
    try{
        func();
    }catch(Throwable throwable){
        throw new TestFailureNoThrowException(throwable, line, file);
    }
}



/// Can be used to group other tests together, therein providing more context
/// to exceptions thrown as a result of test failures.
void testgroup(Fn)(
    Fn func, in size_t line = __LINE__, in string file = __FILE__
){
    testgroup(null, func, line, file);
}
/// ditto
void testgroup(Fn)(
    string name, Fn func, in size_t line = __LINE__, in string file = __FILE__
){
    TestFailureException e = null;
    try{
        func();
    }catch(TestFailureException exception){
        e = exception;
    }catch(Throwable throwable){
        e = new TestFailureUnhandledException(throwable, line, file);
    }
    if(e !is null){
        if(name !is null) e.msg = name ~ ": " ~ e.msg;
        throw e;
    }
}



void test(T)(auto ref T value, size_t line = __LINE__, string file = __FILE__){
    testtrue(value, line, file);
}

void test(alias pred, A)(
    auto ref A a, in size_t line = __LINE__, in string file = __FILE__
) if(is(typeof({
    if(pred(a)){}
}))){
    if(!pred(a)){
        throw new TestFailurePredicateException(line, file, a);
    }
}
void test(alias pred, A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
) if(is(typeof({
    if(pred(a, b)){}
}))){
    if(!pred(a, b)){
        throw new TestFailurePredicateException(line, file, a, b);
    }
}
void test(alias pred, T...)(auto ref T values) if(
    values.length > 2 && is(typeof({
        if(pred(values)){}
    }))
){
    if(!pred(values)){
        throw new TestFailurePredicateException(__LINE__, __FILE__, values);
    }
}



void testf(T)(auto ref T value, size_t line = __LINE__, string file = __FILE__){
    testfalse(value, line, file);
}

void testf(alias pred, A)(
    auto ref A a, in size_t line = __LINE__, in string file = __FILE__
) if(is(typeof({
    if(pred(a)){}
}))){
    if(pred(a)){
        throw new TestFailureNotPredicateException(line, file, a);
    }
}
void testf(alias pred, A, B)(
    auto ref A a, auto ref B b, in size_t line = __LINE__, in string file = __FILE__
) if(is(typeof({
    if(pred(a, b)){}
}))){
    if(pred(a, b)){
        throw new TestFailureNotPredicateException(line, file, a, b);
    }
}
void testf(alias pred, T...)(auto ref T values) if(
    values.length > 2 && is(typeof({
        if(pred(values)){}
    }))
){
    if(pred(values)){
        throw new TestFailureNotPredicateException(__LINE__, __FILE__, values);
    }
}



alias testeq = testequal;
alias testneq = testnotequal;
alias testis = testsameidentity;
alias testisnot = testdiffidentity;
alias testgt = testgreater;
alias testlt = testless;
alias testgte = testgreatereq;
alias testlte = testlesseq;
alias testfail = testthrow;
alias tests = testgroup;



version(unittest){
    private:
    import core.exception : AssertError;
}
unittest{
    // Enforce failure
    testfail({assert(false);});
    // Enforce failure of (enforcing failure of (non-failing operation))
    testfail({testfail({});});
}
unittest{
    // Enforce failure with exception type
    testfail!AssertError({
        assert(false);
    });
    // Enforce failure due to incorrect exception type
    testfail({
        testfail!TestFailureException({
            assert(false);
        });
    });
    // Enforce failure due to no error thrown
    testfail!TestFailureException({
        testfail!AssertError({
            return;
        });
    });
}
unittest{
    // Enforce failure with predicate
    testfail(
        (Throwable e){
            return cast(TestFailureEqualityException) e !is null;
        },
        {
            throw new TestFailureEqualityException(1, 2);
        }
    );
    // Enforce failure due to unsatisfied predicate
    testfail({
        testfail(
            (Throwable e){
                return false;
            },
            {
                throw new TestFailureEqualityException(1, 2);
            }
        );
    });
    // Enforce failure due to no error thrown
    testfail({
        testfail(
            (Throwable e){
                return true;
            },
            {
                return;
            }
        );
    });
}
unittest{
    testnothrow({return;});
    testfail({testnothrow({assert(false);});});
}
unittest{
    testnothrow({
        // Named group
        tests("Group", {return;});
        // Unnamed group
        tests({return;});
    });
    testfail(
        (Throwable e){
            return (
                cast(TestFailureException) e !is null &&
                cast(AssertError) e.next !is null &&
                e.msg.length > 5 && e.msg[0 .. 5] == "Group"
            );
        },
        {
            tests("Group", {assert(false);});
        }
    );
    testfail(
        (Throwable e){
            return (
                cast(TestFailureException) e !is null &&
                cast(AssertError) e.next !is null
            );
        },
        {
            tests({assert(false);});
        }
    );
}
unittest{
    tests("True", {
        test(true);
        test(1);
        testfail({test(false);});
        testfail({test(0);});
        testfail({test(null);});
    });
    tests("False", {
        testf(false);
        testf(0);
        testf(null);
        testfail({testf(true);});
        testfail({testf(1);});
    });
}
unittest{
    class TestClass{this(){}}
    int* nullptr = null;
    TestClass nullclass = null;
    int* notnullptr = new int;
    TestClass notnullclass = new TestClass;
    tests("Null", {
        testnull(null);
        testnull(nullptr);
        testnull(nullclass);
        testfail({testnull(notnullptr);});
        testfail({testnull(notnullclass);});
    });
    tests("Not null", {
        testnotnull(notnullptr);
        testnotnull(notnullclass);
        testfail({testnotnull(null);});
        testfail({testnotnull(nullptr);});
        testfail({testnotnull(nullclass);});
    });
}
unittest{
    tests("Equality", {
        testeq(0, 0);
        testeq("hi", "hi");
        testfail({testeq(0, 1);});
        testfail({testeq("hi", "no");});
    });
    tests("Inequality", {
        testneq(0, 1);
        testneq("hi", "no");
        testfail({testneq(0, 0);});
        testfail({testneq("hi", "hi");});
    });
}
unittest{
    tests("Same identity", {
        testis(0, 0);
        testfail({testis(0, 1);});
        auto i0 = new int[3];
        auto i1 = new int[3];
        testis(i0, i0);
        testis(i1, i1);
        testfail({testis(i0, i1);});
    });
    tests("Different identity", {
        testisnot(0, 1);
        testfail({testisnot(0, 0);});
        auto i0 = new int[3];
        auto i1 = new int[3];
        testisnot(i0, i1);
        testfail({testisnot(i0, i0);});
        testfail({testisnot(i1, i1);});
    });
}
unittest{
    tests("Greater than", {
        testgt(1, 0);
        testgt(2, 0);
        testfail({testgt(0, 1);});
        testfail({testgt(0, 0);});
    });
    tests("Less than", {
        testlt(0, 1);
        testlt(0, 2);
        testfail({testlt(1, 0);});
        testfail({testlt(0, 0);});
    });
    tests("Greater or equal", {
        testgte(1, 0);
        testgte(0, 0);
        testfail({testgte(0, 1);});
    });
    tests("Lesser or equal", {
        testlte(0, 1);
        testlte(0, 0);
        testfail({testlte(1, 0);});
    });
}
unittest{
    tests("Templated", {
        alias eq = (a, b) => (a == b);
        alias neq = (a, b) => (a != b);
        test!eq(1, 1);
        test!neq(1, 2);
        testfail({test!eq(1, 2);});
        testfail({test!neq(1, 1);});
        testf!eq(1, 2);
        testf!neq(1, 1);
        testfail({testf!eq(1, 1);});
        testfail({testf!neq(1, 2);});
    });
}
