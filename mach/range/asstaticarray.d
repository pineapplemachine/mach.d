module mach.range.asstaticarray;

private:

import mach.traits : isIterable, isArray, ElementType, CommonType, hasCommonType;

/++ Docs

The `asstaticarray` function can be used to produce a static array from either
a list of variadic arguments, or from an iterable whose length is known at
compile time.

+/

unittest{ /// Example
    int[4] array = asstaticarray(0, 1, 2, 3);
    assert(array == [0, 1, 2, 3]);
}

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof!int(0, 1, 2, 3);
    int[4] array = range.asstaticarray!4;
    assert(array == [0, 1, 2, 3]);
}

/++ Docs

When constructing a static array from an iterable, `asstaticarray` will produce
an error if the actual length of the input iterable does not match the expected
length.
Except for in release mode, the function throws an `AsStaticArrayError` by way
of reporting this error. In release mode, the conditionals required to perform
this error reporting are ommitted.

+/

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    import mach.error.mustthrow : mustthrow;
    auto range = rangeof!int(0, 1, 2, 3);
    mustthrow!AsStaticArrayError({
        range.asstaticarray!10; // Fails because of incorrect length.
    });
}

public:



/// Error thrown when `asstaticarray` fails for an iterable because its length
/// was inconsistent with the expected length. 
class AsStaticArrayError: Error{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(
            "Failed to create static array from iterable contents because " ~
            "the iterable was not of the expected length.", file, line, next
        );
    }
}



/// Get some variadic arguments as a static array.
auto asstaticarray(Args...)(Args args) if(hasCommonType!Args){
    return args.asstaticarray!(CommonType!Args);
}

/// Get some variadic arguments as a static array of elements of the given type.
auto asstaticarray(Element, Args...)(Args args){
    Element[Args.length] array = [args];
    return array;
}



/// Create array from an iterable where exact length is known at compile time.
/// If the input is either shorter or longer than the provided length, then an
/// `AsStaticArrayError` is thrown.
/// When compiling in release mode, the length check is ommitted and any
/// errors produced by the incorrect length may be significantly more ambiguous.
auto asstaticarray(size_t length, Iter)(auto ref Iter iter) if(isIterable!Iter){
    return asstaticarray!(ElementType!Iter, length, Iter)(iter);
}

/// ditto
auto asstaticarray(Element, size_t length, Iter)(auto ref Iter iter) if(
    is(typeof({
        foreach(element; iter) Element[1] array = [element];
    }))
){
    version(assert){
        // Initialize error thrown when length is incorrect.
        static const error = new AsStaticArrayError();
    }
    static if(isArray!Iter){
        // Optimized implementation for array inputs.
        version(assert){
            if(iter.length != length) throw error;
        }
        Element[length] staticarray = iter[];
        return staticarray;
    }else{
        // Accumulate elements of iterable in a dynamic array.
        Element[] dynamicarray;
        foreach(item; iter){
            version(assert){
                // Throw error when actual length exceeds expected length.
                if(dynamicarray.length >= length) throw error;
            }
            dynamicarray ~= item;
        }
        version(assert){
            // Throw error when expected length exceeds actual length.
            if(dynamicarray.length != length) throw error;
        }
        // Build and return the static array.
        Element[length] staticarray = dynamicarray[];
        return staticarray;
    }
}



version(unittest){
    private:
    import mach.test;
    struct TestRange{
        int low, high;
        int index = 0;
        @property bool empty() const{return this.index >= (this.high - this.low);}
        @property int front() const{return this.low + this.index;}
        void popFront(){this.index++;}
    }
}
unittest{
    tests("As static array", {
        tests("Variadic args", {
            tests("Explicit type", {
                double[4] array = asstaticarray!double(int(0), int(1), long(2), float(3));
                testeq(array, [0, 1, 2, 3]);
            });
            tests("Inferred type", {
                int[4] array = asstaticarray(0, 1, 2, 3);
                testeq(array, [0, 1, 2, 3]);
            });
            tests("Immutable elements", {
                const(int)[4] array = asstaticarray!(const(int))(0, 1, 2, 3);
                testeq(array, [0, 1, 2, 3]);
            });
        });
        tests("Iterable", {
            tests("Correct length", {
                int[4] array = asstaticarray!4([0, 1, 2, 3]);
                testeq(array, [0, 1, 2, 3]);
            });
            tests("Incorrect length", {
                testfail!AsStaticArrayError({
                    TestRange(0, 4).asstaticarray!2;
                });
                testfail!AsStaticArrayError({
                    TestRange(0, 4).asstaticarray!10;
                });
            });
        });
    });
}
