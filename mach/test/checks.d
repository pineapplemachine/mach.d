module mach.test.checks;

private:

//

public:



class TestFailureException: Exception{
    static enum Type{
        UnhandledError,
        True,
        False,
        Equality,
        Inequality,
        SameIdentity,
        DiffIdentity,
        Ascending,
        Descending,
        GreaterThan,
        LessThan,
        GreaterThanEq,
        LessThanEq,
        MustThrow,
        MustThrowPred,
        NoThrow,
        BinaryOp,
        // TODO: Support these test types also
        /+
        NearlyEqual,
        NotNearlyEqual,
        +/
    }
    
    Type type;
    bool group;
    
    this(Type type, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(typename(type, next), file, line, next);
        this.type = type;
    }
    this(Type type, string inputs, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(typename(type, next) ~ ' ' ~ inputs, file, line, next);
        this.type = type;
    }
    
    void enforce(T)(Type type, lazy T condition){
        try{
            if(condition()){
                //
            }else{
                throw new typeof(this)(type);
            }
        }catch(Throwable thrown){
            throw new typeof(this)(type, thrown);
        }
    }
    
    static string typename(in Type type){
        final switch(type){
            case Type.UnhandledError: return "Unhandled error occurred.";
            case Type.True: return "Value must evaluate true.";
            case Type.False: return "Value must evaluate false.";
            case Type.Equality: return "Values must be equal.";
            case Type.Inequality: return "Values must be unequal.";
            case Type.SameIdentity: return "Values must be identical.";
            case Type.DiffIdentity: return "Values must not be identical.";
            case Type.Ascending: return "Values must be in ascending order.";
            case Type.Descending: return "Values must be in descending order.";
            case Type.GreaterThan: return "First value must be greater than the second.";
            case Type.LessThan: return "First value must be less than the second.";
            case Type.GreaterThanEq: return "First value must be greater than or equal to the second.";
            case Type.LessThanEq: return "First value must be less than or equal to the second.";
            case Type.MustThrow: return "Operation must throw an exception.";
            case Type.MustThrowPred: return "Operation must throw an exception meeting the predicate.";
            case Type.NoThrow: return "Operation must not throw an exception.";
            case Type.BinaryOp: return "Binary operation must evaluate true for all pairs of inputs.";
        }
    }
    
    static string typename(in Type type, in Throwable next){
        if(next is null){
            return typename(type);
        }else{
            return typename(type) ~ " (Encountered exception.)";
        }
    }
    
    static string inputstring(Args...)(auto ref Args args){
        import std.conv : to;
        import mach.traits : isString;
        string str = "";
        foreach(arg; args){
            alias Arg = typeof(arg);
            if(str.length) str ~= " and ";
            auto immutable argstr = arg.to!string;
            static if(isString!Arg){
                str ~= '`' ~ argstr ~ '`';
            }else{
                str ~= argstr;
            }
        }
        return str;
    }
}



/// If all inputs do not evaluate as truthy, throw a TestFailureException.
void testtrue(T...)(auto ref T conditions){
    foreach(cond; conditions){
        if(cond){
            continue;
        }else{
            throw new TestFailureException(
                TestFailureException.Type.True,
                TestFailureException.inputstring(conditions)
            );
        }
    }
}

/// If all inputs do not evaluate as falsey, throw a TestFailureException.
void testfalse(T...)(auto ref T conditions){
    foreach(cond; conditions){
        if(cond){
            throw new TestFailureException(
                TestFailureException.Type.False,
                TestFailureException.inputstring(conditions)
            );
        }
    }
}



/// Throw an exception unless for e.g. a, b, c: op(a, b) && op(b, c)
void testbinaryseq(string op, T...)(TestFailureException.Type type, auto ref T values){
    mixin(`
        testbinaryseq!((a, b) => (a ` ~ op ~ ` b))(type, values);
    `);
}
/// ditto
void testbinaryseq(alias op, T...)(TestFailureException.Type type, auto ref T values){
    static if(values.length > 1){
        foreach(index, value; values){
            static if(index > 0){
                if(op(values[index - 1], value)){
                    continue;
                }else{
                    throw new TestFailureException(
                        type, TestFailureException.inputstring(values)
                    );
                }
            }
        }
    }
}



/// Throw an exception unless for e.g. a, b, c: op(a, b) && op(a, c) && op(b, c)
void testbinaryall(string op, T...)(TestFailureException.Type type, auto ref T values){
    mixin(`
        testbinaryall!((a, b) => (a ` ~ op ~ ` b))(type, values);
    `);
}
/// ditto
void testbinaryall(alias op, T...)(TestFailureException.Type type, auto ref T values){
    static if(values.length > 1){
        foreach(i, ivalue; values){
            foreach(j, jvalue; values){
                static if(i < j){
                    if(op(ivalue, jvalue)){
                        continue;
                    }else{
                        throw new TestFailureException(
                            type, TestFailureException.inputstring(values)
                        );
                    }
                }
            }
        }
    }
}



/// Throw an exception unless for e.g. a, b, c: op(a, b) || op(a, c) || op(b, c)
void testbinaryany(string op, T...)(TestFailureException.Type type, auto ref T values){
    mixin(`
        testbinaryany!((a, b) => (a ` ~ op ~ ` b))(type, values);
    `);
}
/// ditto
void testbinaryany(alias op, T...)(TestFailureException.Type type, auto ref T values){
    static if(values.length > 1){
        foreach(i, ivalue; values){
            foreach(j, jvalue; values){
                static if(i < j){
                    if(op(ivalue, jvalue)) return;
                }
            }
        }
    }
    throw new TestFailureException(
        type, TestFailureException.inputstring(values)
    );
}



/// If all inputs are not equal to each other, throw a TestFailureException.
void testequal(T...)(auto ref T values) if(values.length > 1){
    testbinaryall!`==`(TestFailureException.Type.Equality, values);
}

/// If all inputs are equal to each other, throw a TestFailureException.
void testnotequal(T...)(auto ref T values) if(values.length > 1){
    testbinaryany!`!=`(TestFailureException.Type.Inequality, values);
}

/// If any two inputs are not identical, throw a TestFailureException.
void testsameidentity(T...)(auto ref T values) if(values.length > 1){
    testbinaryseq!`is`(TestFailureException.Type.SameIdentity, values);
}

/// If all inputs are identical, throw a TestFailureException.
void testdiffidentity(T...)(auto ref T values) if(values.length > 1){
    testbinaryany!`!is`(TestFailureException.Type.DiffIdentity, values);
}

/// If inputs are not in ascending order, throw a TestFailureException.
void testascending(T...)(auto ref T values){
    testbinaryseq!`<=`(TestFailureException.Type.Ascending, values);
}

/// If inputs are not in descending order, throw a TestFailureException.
void testdescending(T...)(auto ref T values){
    testbinaryseq!`>=`(TestFailureException.Type.Descending, values);
}

/// If the first input is not greater than the second,
/// throw a TestFailureException.
void testgreater(A, B)(auto ref A a, auto ref B b){
    testbinaryseq!`>`(TestFailureException.Type.GreaterThan, a, b);
}

/// If the first input is not less than the second,
/// throw a TestFailureException.
void testless(A, B)(auto ref A a, auto ref B b){
    testbinaryseq!`<`(TestFailureException.Type.LessThan, a, b);
}

/// If the first input is not greater than or equal to the second,
/// throw a TestFailureException.
void testgreatereq(A, B)(auto ref A a, auto ref B b){
    testbinaryseq!`>=`(TestFailureException.Type.GreaterThanEq, a, b);
}

/// If the first input is not less than or equal to the second,
/// throw a TestFailureException.
void testlesseq(A, B)(auto ref A a, auto ref B b){
    testbinaryseq!`<=`(TestFailureException.Type.LessThanEq, a, b);
}



/// If the passed delegate does not itself throw an exception,
/// throw a TestFailureException.
void testthrow(Fn)(Fn func){
    Throwable caught = null;
    try{
        func();
    }catch(Throwable throwable){
        caught = throwable;
    }
    if(caught is null){
        throw new TestFailureException(
            TestFailureException.Type.MustThrow
        );
    }
}

/// If the passed delegate does not itself throw an exception, or if it does
/// throw an exception but the thrown object does not meet the predicate,
/// throw a TestFailureException.
void testthrow(Pred, Fn)(Pred pred, Fn func){
    Throwable caught = null;
    try{
        func();
    }catch(Throwable throwable){
        caught = throwable;
    }
    if(caught is null || !pred(caught)){
        throw new TestFailureException(
            TestFailureException.Type.MustThrowPred,
            TestFailureException.inputstring(caught)
        );
    }
}

/// If the passed delegate itself throws an exception,
/// throw a TestFailureException.
void testnothrow(Fn)(Fn func){
    try{
        func();
    }catch(Throwable throwable){
        throw new TestFailureException(
            TestFailureException.Type.NoThrow, throwable
        );
    }
}



/// Can be used to group other tests together, therein providing more context
/// to exceptions thrown as a result of test failures.
void testgroup(Fn)(Fn func, size_t line = __LINE__, string file = __FILE__){
    testgroup(null, func, line, file);
}
/// ditto
void testgroup(Fn)(string name, Fn func, size_t line = __LINE__, string file = __FILE__){
    TestFailureException e = null;
    try{
        func();
    }catch(TestFailureException exception){
        e = exception;
        if(!e.group){
            e.line = line;
            e.file = file;
            e.group = true;
        }
    }catch(Throwable throwable){
        e = new TestFailureException(
            TestFailureException.Type.UnhandledError, throwable, line, file
        );
        e.group = true;
    }
    if(e !is null){
        if(name !is null) e.msg = name ~ ": " ~ e.msg;
        throw e;
    }
}



void test(alias op, T...)(auto ref T inputs){
    testbinaryall!op(TestFailureException.Type.BinaryOp, inputs);
}
void test(T...)(auto ref T inputs){
    testtrue(inputs);
}



alias testf = testfalse;
alias testeq = testequal;
alias testneq = testnotequal;
alias testis = testsameidentity;
alias testisnot = testdiffidentity;
alias testasc = testascending;
alias testdesc = testdescending;
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
    // Enforce failure with predicate
    testfail(
        (Throwable e){
            auto te = cast(TestFailureException) e;
            return te !is null && te.type is TestFailureException.Type.Equality;
        },
        {
            throw new TestFailureException(
                TestFailureException.Type.Equality
            );
        }
    );
    // Enforce failure due to unsatisfied predicate
    testfail({
        testfail(
            (Throwable e){
                auto te = cast(TestFailureException) e;
                return te !is null && te.type is TestFailureException.Type.Inequality;
            },
            {
                throw new TestFailureException(
                    TestFailureException.Type.Equality
                );
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
    tests("Equality", {
        testeq(0, 0);
        testeq(0, 0, 0, 0);
        testeq("hi", "hi");
        testfail({testeq(0, 1);});
        testfail({testeq(0, 0, 0, 1);});
        testfail({testeq("hi", "no");});
    });
    tests("Inequality", {
        testneq(0, 1);
        testneq(0, 0, 0, 1);
        testneq("hi", "no");
        testfail({testneq(0, 0);});
        testfail({testneq(0, 0, 0, 0);});
        testfail({testneq("hi", "hi");});
    });
}
unittest{
    tests("Same identity", {
        testis(0, 0);
        testis(0, 0, 0, 0);
        testfail({testis(0, 1);});
        testfail({testis(0, 0, 0, 1);});
        auto i0 = new int[3];
        auto i1 = new int[3];
        testis(i0, i0);
        testis(i1, i1);
        testfail({testis(i0, i1);});
    });
    tests("Different identity", {
        testisnot(0, 1);
        testisnot(0, 0, 0, 1);
        testfail({testisnot(0, 0);});
        testfail({testisnot(0, 0, 0, 0);});
        auto i0 = new int[3];
        auto i1 = new int[3];
        testisnot(i0, i1);
        testfail({testisnot(i0, i0);});
        testfail({testisnot(i1, i1);});
    });
}
unittest{
    tests("Ascending order", {
        testasc(0);
        testasc(0, 1, 2, 3);
        testasc(0, 1, 1, 2);
        testfail({testasc(1, 0);});
    });
    tests("Descending order", {
        testdesc(0);
        testdesc(3, 2, 1, 0);
        testdesc(2, 1, 1, 0);
        testfail({testdesc(0, 1);});
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
        alias pred = (a, b) => (a == b + 1);
        test!pred(2, 1);
        testfail({test!pred(0, 0);});
    });
}
