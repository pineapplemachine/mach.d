module mach.math.sum;

private:

import mach.types : Rebindable;
import mach.traits : isFloatingPoint, isFiniteIterable, isIterableOf;
import mach.traits : ElementType, Unqual;
import mach.math.abs : abs;
import mach.math.floats.properties : fisinf, fisnan;

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

/++ Docs

The `fsum` (or `shewsum`) function can additionally be used to sum floats using
[https://people.eecs.berkeley.edu/~jrs/papers/robustr.pdf](Shewchuck's algorithm).
It is less efficient than the Kahan summation algorithm, but its output is more
correct.

+/

unittest{ /// Example
    assert(fsum([0.25, 0.5, 0.75]) == 1.5);
}

/++ Docs

Note that the floating-point summation implementations — both `kahansum` and
`shewsum` and their aliases — have consistent behavior for NaN and infinite
inputs, and for intermediate overflow during summation.

+/

unittest{ /// Example
    import mach.math.floats.properties : fisnan, fisposinf, fisneginf;
    // When there is any NaN, returns the first NaN.
    assert(sum([1.0, +real.nan]).fisnan);
    // When there is any +inf but no NaN or -inf, returns +inf.
    assert(sum([1.0, +real.infinity]).fisposinf);
    // When there is any -inf but no NaN or +inf, returns -inf.
    assert(sum([1.0, -real.infinity]).fisneginf);
    // When there's both +inf and -inf but no NaN, returns NaN.
    assert(sum([+real.infinity, -real.infinity]).fisnan);
    // When there's intermediate positive overflow but no +inf, -inf, or NaN, returns +inf.
    assert(sum([+real.max, +real.max]).fisposinf);
    // When there's intermediate negative overflow but no +inf, -inf, or NaN, returns -inf.
    assert(sum([-real.max, -real.max]).fisneginf);
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



/// Implementation of the Kahan summation algorithm.
/// If any input is NaN, returns the first NaN input.
/// If any input is +inf and no inputs are -inf, returns +inf.
/// If any input is -inf and no inputs are +inf, returns -inf.
/// If any input is +inf and any input is -inf, returns NaN.
/// In case of intermediate positive overflow, returns +inf.
/// In case of intermediate negative overflow, returns -inf.
/// https://en.wikipedia.org/wiki/Kahan_summation_algorithm
auto kahansum(Values)(auto ref Values values) if(
    isFiniteIterable!Values && isIterableOf!(Values, isFloatingPoint)
){
    alias Value = Unqual!(ElementType!Values);
    Value sum = 0;
    Value compensation = 0;
    bool overflow = false;
    foreach(value; values){
        if(fisnan(value)){
            return value;
        }else if(fisinf(value)){
            if(overflow || !fisinf(sum)) sum = value;
            else value += sum;
            if(fisnan(value)) return value;
        }else if(!fisinf(sum)){
            auto y = value - compensation;
            auto t = sum + y;
            compensation = (t - sum) - y;
            sum = t;
            overflow = fisinf(sum);
        }
    }
    return sum;
}



/// Sum floating point values using Shewchuk's summation algorithm.
/// Less efficient than the Kahan summation algorithm, but more accurate.
/// If any input is NaN, returns the first NaN input.
/// If any input is +inf and no inputs are -inf, returns +inf.
/// If any input is -inf and no inputs are +inf, returns -inf.
/// If any input is +inf and any input is -inf, returns NaN.
/// In case of intermediate positive overflow, returns +inf.
/// In case of intermediate negative overflow, returns -inf.
/// http://stackoverflow.com/a/2704565/3478907
/// http://code.activestate.com/recipes/393090-binary-floating-point-summation-accurate-to-full-p/
/// http://svn.python.org/view/python/trunk/Modules/mathmodule.c?view=markup
auto shewsum(Values)(auto ref Values values) if(
    isFiniteIterable!Values && isIterableOf!(Values, isFloatingPoint)
){
    alias Element = ElementType!Values;
    alias Value = real;
    
    Value infsum = 0; // Used to handle infinity in the input
    Value overflow = 0; // Used to handle intermediate overflow
    
    Value[] partials;
    foreach(value; values){
        if(fisnan(value)){
            return value;
        }else if(fisinf(value)){
            infsum += value;
        }else if(infsum == 0 && overflow == 0){
            Value x = value;
            size_t i = 0;
            foreach(partial; partials){
                Value y = partial;
                if(abs(x) < abs(y)){
                    auto t = x; x = y; y = t;
                }
                auto high = x + y;
                auto yr = high - x;
                auto low = y - yr;
                if(low != 0){
                    partials[i++] = low;
                }
                x = high;
            }
            partials.length = i;
            
            if(x != 0){
                if(fisinf(value)){
                    infsum = value;
                }else if(fisinf(x)){
                    overflow = x;
                }else{
                    partials ~= x;
                }
            }
        }
    }
    
    if(infsum != 0){
        return infsum;
    }else if(overflow != 0){
        return overflow;
    }
    
    Value high = 0;
    if(partials.length){
        size_t n = partials.length;
        high = partials[--n];
        Value low;
        while(n < 0){
            auto x = high;
            auto y = partials[--n];
            assert(abs(y) < abs(x));
            high = x + y;
            auto yr = high - x;
            low = y - yr;
            if(low != 0) break;
        }
        if(n > 0 && (
            (low < 0 && partials[n - 1] < 0) || (low > 0 && partials[n - 1] > 0)
        )){
            auto y = low * 2;
            auto x = high + y;
            auto yr = x - high;
            if(y == yr) high = x;
        }
    }
    
    return high;
}



/// More standard and easier to remember than "shewsum"
alias fsum = shewsum;



private version(unittest){
    import mach.math.floats.properties : fisposinf, fisneginf;
    /// Helper function to test floating point summation
    void testfp(E, V)(in E expected, auto ref V values){
        assert(sum(values) == expected);
        assert(kahansum(values) == expected);
        assert(shewsum(values) == expected);
    }
    /// Helper function to test float summation resulting in infinity or NaN
    void testfpspecial(alias pred, V)(auto ref V values){
        assert(pred(sum(values)));
        assert(pred(kahansum(values)));
        assert(pred(shewsum(values)));
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

unittest{ /// Float summation special cases
    // Only element in input
    testfpspecial!fisposinf([+double.infinity]);
    testfpspecial!fisneginf([-double.infinity]);
    testfpspecial!fisnan([double.nan]);
    // One element among finite numbers
    testfpspecial!fisposinf([1.0, 2.0, +double.infinity]);
    testfpspecial!fisposinf([+double.infinity, 1.0, 2.0]);
    testfpspecial!fisposinf([1.0, +double.infinity, 2.0]);
    testfpspecial!fisneginf([1.0, 2.0, -double.infinity]);
    testfpspecial!fisneginf([-double.infinity, 1.0, 2.0]);
    testfpspecial!fisneginf([1.0, -double.infinity, 2.0]);
    testfpspecial!fisnan([1.0, 2.0, double.nan]);
    testfpspecial!fisnan([double.nan, 1.0, 2.0]);
    testfpspecial!fisnan([1.0, double.nan, 2.0]);
    // Combination of NaN and infinity
    testfpspecial!fisnan([double.nan, double.infinity]);
    testfpspecial!fisnan([double.infinity, double.nan]);
    // Multiple same-signed infinities
    testfpspecial!fisposinf([+double.infinity, +double.infinity]);
    testfpspecial!fisneginf([-double.infinity, -double.infinity]);
    // Combination of positive and negative infinity
    testfpspecial!fisnan([+double.infinity, -double.infinity]);
    testfpspecial!fisnan([-double.infinity, +double.infinity]);
    // Intermediate overflow
    testfpspecial!fisposinf([+real.max, +real.max]);
    testfpspecial!fisneginf([-real.max, -real.max]);
    // Intermediate overflow and same-sign infinity
    testfpspecial!fisposinf([+real.infinity, +real.max, +real.max]);
    testfpspecial!fisposinf([+real.max, +real.infinity, +real.max]);
    testfpspecial!fisposinf([+real.max, +real.max, +real.infinity]);
    testfpspecial!fisneginf([-real.infinity, -real.max, -real.max]);
    testfpspecial!fisneginf([-real.max, -real.infinity, -real.max]);
    testfpspecial!fisneginf([-real.max, -real.max, -real.infinity]);
    // Intermediate overflow and opposing-sign infinity
    testfpspecial!fisposinf([+real.infinity, -real.max, -real.max]);
    testfpspecial!fisposinf([-real.max, +real.infinity, -real.max]);
    testfpspecial!fisposinf([-real.max, -real.max, +real.infinity]);
    testfpspecial!fisneginf([-real.infinity, +real.max, +real.max]);
    testfpspecial!fisneginf([+real.max, -real.infinity, +real.max]);
    testfpspecial!fisneginf([+real.max, +real.max, -real.infinity]);
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
