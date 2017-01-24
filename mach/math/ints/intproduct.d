module mach.math.ints.intproduct;

private:

import mach.traits : isIntegral, isUnsignedIntegral;
import mach.math.bits : pow2d;

/++ Docs

The `intproduct` function can be used to multiply two unsigned integer values
without loss due to overflow, and without the use of a larger integer type
for storing the final or any intermediate value.

+/

unittest{ /// Example
    auto product = intproduct(2, uint.max);
    assert(product.low == (2 * uint.max));
    assert(product.high == 1);
}

/++ Docs

For convenience, when there is a larger integer type that can accommodate both
the high and low bits recorded in the type returned by `intproduct`,
the value of that returned type may be directly compared to that value.

+/

unittest{ /// Example
    assert(intproduct(uint.max, uint.max) == (cast(ulong) uint.max * cast(ulong) uint.max));
}

/++ Docs

The `intproductoverflow` function can be used to get the product of two integers
and whether the operation caused overflow, without computing the carried value.
It returns a type with an integer `value` attribute storing the result of
multiplication and a boolean `overflow` attribute indicating whether the
operation resulted in integer overflow.

+/

unittest{ /// Example
    auto result = intproductoverflow(2, int.max);
    assert(result.value == 2 * int.max);
    assert(result.overflow);
}

public:



/// Type returned by `intproduct`.
struct IntProduct(T) if(isUnsignedIntegral!T){
    enum isBigger(X) = isUnsignedIntegral!X && X.sizeof >= T.sizeof * 2;
    
    T high; // High bits of product.
    T low; // Low bits of product.
    
    auto opCast(To: T)() const{
        return this.low;
    }
    auto opCast(To)() const if(isBigger!To){
        return (cast(To) this.low) | (((cast(To) this.high) << T.sizeof * 8));
    }
    
    bool opEquals(in T value) const{
        return this.low == value && this.high == 0;
    }
    bool opEquals(X)(in X value) const if(isBigger!X){
        return (
            cast(X) this.low == (value & pow2d!(T.sizeof  * 8)) &&
            cast(X) this.high == (value >> (T.sizeof * 8))
        );
    }
    
    int opCmp(in T value) const{
        if(this.high > 0 || this.low > value) return 1;
        else if(this.low < value) return -1;
        else return 0;
    }
    int opCmp(X)(in X value) const if(isBigger!X){
        immutable highcmp = (cast(X) this.high) << T.sizeof * 8;
        immutable highval = value & (~(cast(X) pow2d!(T.sizeof * 8)));
        if(highcmp > highval){
            return 1;
        }else if(highcmp < highval){
            return -1;
        }else{
            immutable lowval = cast(T) value;
            if(low > lowval) return 1;
            else if(low < lowval) return -1;
            else return 0;
        }
    }
}



/// Get the product of two integers, capturing overflow in another value.
/// Credit http://stackoverflow.com/a/1815371/3478907
auto intproduct(T)(in T a, in T b) if(isUnsignedIntegral!T){
    static auto lowhalf(in T value){
        return value & pow2d!(T.sizeof * 4);
    }
    static auto highhalf(in T value){
        return value >> (T.sizeof * 4);
    }
    
    immutable p0 = lowhalf(a) * lowhalf(b);
    immutable s0 = lowhalf(p0);
    immutable p1 = highhalf(a) * lowhalf(b) + highhalf(p0);
    immutable s1 = lowhalf(p1);
    immutable s2 = highhalf(p1);
    immutable p2 = s1 + lowhalf(a) * highhalf(b);
    immutable s3 = lowhalf(p2);
    immutable p3 = s2 + highhalf(a) * highhalf(b) + highhalf(p2);
    
    return IntProduct!T(p3, s0 | (s3 << (T.sizeof * 4)));
}



/// Type returned by `intproductoverflow` and `intsumoverflow`.
struct IntOperationOverflow(T) if(isIntegral!T){
    T value;
    bool overflow;
}
    
/// Get the product of two integers, and whether overflow resulted.
auto intproductoverflow(T)(in T a, in T b) if(isIntegral!T){
    immutable value = cast(T)(a * b);
    immutable overflow = a != 0 && value / a != b;
    return IntOperationOverflow!T(value, overflow);
}

/// Get the sum of two integers and whether overflow occurred.
/// TODO: With this here maybe the package should be renamed
auto intsumoverflow(T)(in T a, in T b) if(isIntegral!T){
    immutable value = cast(T)(a + b);
    immutable overflow = value < a;
    return IntOperationOverflow!T(value, overflow);
}

/// Get the sum of two integers and a carried bit and whether overflow occurred.
auto intsumoverflow(T)(in T a, in T b, in bool carry) if(isIntegral!T){
    immutable value = cast(T)(a + b + carry);
    immutable overflow = value < a || (carry && value == a);
    return IntOperationOverflow!T(value, overflow);
}

/// Get the result of `a * b + c` and whether overflow occurred.
auto intfmaoverflow(T)(in T a, in T b, in T c){
    immutable value = a * b + c;
    immutable overflow = a != 0 && ((value < c) || ((value - c) / a != b));
    return IntOperationOverflow!T(value, overflow);
}



unittest{ /// intproduct
    immutable uint[] numbers = [
        0, 1, 2, 3, 4, 5, 10, 100, 255, 256,
        25 + (1 << 20), int.max, uint.max
    ];
    foreach(x; numbers){
        foreach(y; numbers){
            assert(intproduct(x, y) == cast(ulong) x * cast(ulong) y);
        }
    }
}

unittest{ /// intproductoverflow
    auto yes = intproductoverflow(uint.max, uint(20));
    assert(yes.value == uint.max * uint(20));
    assert(yes.overflow);
    auto no = intproductoverflow(123, 456);
    assert(no.value == 123 * 456);
    assert(!no.overflow);
}

unittest{ /// intsumoverflow without carry
    auto yes = intsumoverflow(uint.max, uint(10));
    assert(yes.value == uint.max + uint(10));
    assert(yes.overflow);
    auto no = intsumoverflow(10, 20);
    assert(no.value == 10 + 20);
    assert(!no.overflow);
}

unittest{ /// intsumoverflow with carry
    {
        // Carry 0
        auto yes = intsumoverflow(uint.max, uint(10), false);
        assert(yes.value == uint.max + uint(10));
        assert(yes.overflow);
        auto no = intsumoverflow(10, 20, false);
        assert(no.value == 10 + 20);
        assert(!no.overflow);
    }{
        // Carry 1
        auto yes = intsumoverflow(uint.max, uint(10), true);
        assert(yes.value == uint.max + uint(11));
        assert(yes.overflow);
        auto no = intsumoverflow(10, 20, true);
        assert(no.value == 10 + 20 + 1);
        assert(!no.overflow);
    }{
        // Carry 1 (and carry causes overflow)
        auto yes = intsumoverflow(uint.max, 0, true);
        assert(yes.value == uint.max + uint(1));
        assert(yes.overflow);
    }
}

unittest{ /// intfmaoverflow
    // Not overflowing
    auto a = intfmaoverflow(0, 0, 0);
    assert(a.value == 0);
    assert(!a.overflow);
    auto b = intfmaoverflow(1, 0, 0);
    assert(b.value == 0);
    assert(!b.overflow);
    auto c = intfmaoverflow(0, 0, 1);
    assert(c.value == 1);
    assert(!c.overflow);
    auto d = intfmaoverflow(5, 6, 7);
    assert(d.value == 5 * 6 + 7);
    assert(!d.overflow);
    auto e = intfmaoverflow(0, 0, int.max);
    assert(e.value == int.max);
    assert(!e.overflow);
    auto f = intfmaoverflow(1, int.max, 0);
    assert(f.value == int.max);
    assert(!f.overflow);
    // Overflowing
    auto g = intfmaoverflow(1, int.max, 1);
    assert(g.value == int.max + 1);
    assert(g.overflow);
    auto h = intfmaoverflow(1, 1, int.max);
    assert(h.value == 1 + int.max);
    assert(h.overflow);
    auto i = intfmaoverflow(int.max, int.max, int.max);
    assert(i.value == int.max * int.max + int.max);
    assert(i.overflow);
}
