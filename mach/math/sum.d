module mach.math.sum;

private:

import mach.types : Rebindable;
import mach.traits : isFloatingPoint, isFiniteIterable, isIterableOf;
import mach.traits : ElementType, Unqual;

/++ Docs

The `sum` function accepts an finite input iterable and returns the sum of its
elements. The only condition imposed upon element types is that they must allow
addition via the binary `+` operator; i.e. user-defined types may be used as
input in addition to primitive numeric types.

When the input is an iterable of floating point primitives, the
[Kahan summation algorithm](https://en.wikipedia.org/wiki/Kahan_summation_algorithm)
is used to reduce error.
In all other cases, a linear summation algorithm is used.
These separate summation algorithms may be called individually via the
`kahansum` and `linearsum` methods that are also implemented in this module.

+/

unittest{ /// Example
    assert(sum([1, 2, 3, 4]) == 10);
    assert(sum([0.25, 0.5, 0.75]) == 1.5);
}

public:



/// Get whether a type is suitable for summation of its elements.
template canSum(T){
    static if(isFiniteIterable!T){
        enum bool canSum = is(typeof({
            alias Element = ElementType!T;
            auto a = Rebindable!(Element).init;
            a = cast(Element) a + Element.init;
        }));
    }else{
        enum bool canSum = false;
    }
}



/// Implementation of the Kahan summation algorithm
/// https://en.wikipedia.org/wiki/Kahan_summation_algorithm
auto kahansum(Values)(auto ref Values values) if(
    isFiniteIterable!Values && isIterableOf!(Values, isFloatingPoint)
){
    alias Value = Unqual!(ElementType!Values);
    Value sum = 0;
    Value compensation = 0;
    foreach(value; values){
        auto y = value - compensation;
        auto t = sum + y;
        compensation = (t - sum) - y;
        sum = t;
    }
    return sum;
}



/// Linear summation algorithm.
auto linearsum(Values)(auto ref Values values) if(canSum!Values){
    alias Element = ElementType!Values;
    alias Value = Rebindable!Element;
    static if(is(typeof({Value sum = Element(0);}))) Value sum = Element(0);
    else Value sum = Value.init;
    foreach(value; values){
        sum = cast(Element) sum + value;
    }
    return cast(Element) sum;
}



/// Sum the elements of an input iterable.
/// In the case of floating point elements, the Kahan summation algorithm
/// will be used. In every other case, a linear summation.
auto sum(Values)(auto ref Values values) if(canSum!Values){
    static if(isIterableOf!(Values, isFloatingPoint)){
        return kahansum(values);
    }else{
        return linearsum(values);
    }
}



private version(unittest){
    /// Helper function to test floating point summation
    void testfp(E, V)(in E expected, auto ref V values){
        assert(sum(values) == expected);
        assert(kahansum(values) == expected);
    }
    /// Helper function to test linear summation, e.g. of integers
    void testlin(E, V)(in E expected, auto ref V values){
        assert(sum(values) == expected);
        assert(linearsum(values) == expected);
    }
}

unittest{ /// Sum floats
    testfp(0, new float[0]);
    testfp(0, [0.0]);
    testfp(1, [1.0]);
    testfp(-2, [-2.0]);
    testfp(0, [0.0, 0.0, 0.0]);
    testfp(1, [1.0, 0.0, 0.0]);
    testfp(1, [1.0, -0.5, 0.5]);
}

unittest{ /// Sum integers
    testlin(0, new int[0]);
    testlin(0, [0]);
    testlin(1, [1]);
    testlin(-2, [-2]);
    testlin(0, [0, 0, 0]);
    testlin(1, [1, 0, 0]);
    testlin(1, [1, 1, -1]);
}

unittest{ /// Sum unsigned integers
    testlin(0, new uint[0]);
    testlin(0, [0u]);
    testlin(1, [1u]);
    testlin(0, [0u, 0u, 0u]);
    testlin(1, [1u, 0u, 0u]);
    testlin(7, [1u, 2u, 4u]);
}

unittest{ /// Linear summation of non-primitive types
    struct Test{
        string text = "";
        auto opBinary(string op: "+")(in Test test){
            return typeof(this)(this.text ~ test.text);
        }
        auto opEquals(in string text){
            return text == this.text;
        }
    }
    testlin("", new Test[0]);
    testlin("a", [Test("a")]);
    testlin("abc", [Test("abc")]);
    testlin("ab", [Test("a"), Test("b")]);
    testlin("abc", [Test("ab"), Test("c")]);
    testlin("hello world", [Test("hello"), Test(" "), Test("world")]);
}
