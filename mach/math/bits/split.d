module mach.math.bits.split;

private:

import mach.meta : Aliases;
import mach.traits : isIntegral, SmallerType;
import mach.math.bits.pow2 : pow2d;

/++ Docs

The `lowbits` and `highbits` functions can be use to acquire the low or high
half of the bits comprising an input integer value, respectively.
The output is always the same type as the input.

+/

unittest{ /// Example
    assert(uint(0x12345678).highbits == 0x1234);
    assert(uint(0x12345678).lowbits == 0x5678);
}

/++ Docs

The `splitbits` function may be used to get both at once.
It returns a type with `low` and `high` attributes, and can also be indexed
as though it was a tuple.

+/

unittest{ /// Example
    auto split = ushort(0xabcd).splitbits;
    // Access via the `high` and `low` attributes:
    assert(split.high == 0xab);
    assert(split.low == 0xcd);
    // Access via indexing:
    assert(split[1] == 0xab);
    assert(split[0] == 0xcd);
}

/++ Docs

Additionally, the `mergebits` function may be used to perform the complementary
operation where an integer is built from its separately-known high and low bits.

+/

unittest{ /// Example
    assert(mergebits(uint(0x1234), uint(0x5678)) == uint(0x12345678));
}

public:



/// Get the low half of the bits of an input value.
pure @safe @nogc nothrow auto lowbits(T)(in T value) if(isIntegral!T){
    return cast(T)(value & pow2d!(T.sizeof * 4));
}

/// Get the high half of the bits of an input value.
pure @safe @nogc nothrow auto highbits(T)(in T value) if(isIntegral!T){
    return cast(T)(value >> (T.sizeof * 4));
}

/// Type returned by `splitbits` function.
struct SplitBits(T) if(isIntegral!T){
    @safe @nogc nothrow:
    
    alias T2 = Aliases!(T, T);
    enum HighIndex = 1;
    enum LowIndex = 0;
    
    /// Abuse alias this to make static opIndex possible.
    alias expand this;
    T2 expand;
    
    /// The high bits of the input.
    @property auto ref high() const{
        return this.expand[HighIndex];
    }
    /// Ditto
    @property auto ref high(){
        return this.expand[HighIndex];
    }
    /// The low bits of the input.
    @property auto ref low() const{
        return this.expand[LowIndex];
    }
    /// Ditto
    @property auto ref low(){
        return this.expand[LowIndex];
    }
    
    this(in T high, in T low){
        assert(high <= pow2d!(T.sizeof * 4));
        assert(low <= pow2d!(T.sizeof * 4));
        this.high = high;
        this.low = low;
    }
    this(in T value) @trusted{
        static if(is(Smaller : SmallerType!T)){
            static assert(Smaller.sizeof * 2 == T.sizeof); // Verify assumption
            immutable s = cast(Smaller*) &value;
            version(LittleEndian){
                this(s[1], s[0]);
            }else{
                this(s[0], s[1]);
            }
        }else{
            this(highbits(value), lowbits(value));
        }
    }
    
    @property T mergebits() const{
        return .mergebits(this.high, this.low);
    }
}

/// Separately get the low and high bits of an input value.
auto splitbits(T)(in T value) if(isIntegral!T){
    return SplitBits!T(value);
}



/// Return a value of type T for which `high` is the high bits and `low` the
/// low bits.
/// If either input is larger than `T.max / 2` then an error may be produced.
T mergebits(T)(in T high, in T low) if(isIntegral!T){
    assert(high <= pow2d!(T.sizeof * 4));
    assert(low <= pow2d!(T.sizeof * 4));
    return cast(T)(cast(T)(high << T.sizeof * 4) | low);
}



unittest{ /// highbits and lowbits
    assert(ulong(0x0123456789abcdef).highbits == 0x01234567);
    assert(ulong(0x0123456789abcdef).lowbits == 0x89abcdef);
    assert(uint(0x12345678).highbits == 0x1234);
    assert(uint(0x12345678).lowbits == 0x5678);
    assert(ushort(0x1234).highbits == 0x12);
    assert(ushort(0x1234).lowbits == 0x34);
    assert(ubyte(0x12).highbits == 0x1);
    assert(ubyte(0x12).lowbits == 0x2);
}

unittest{ /// splitbits with ulong input
    assert(splitbits(ulong(0)) == SplitBits!ulong(ulong(0), ulong(0)));
    assert(splitbits(ulong(0xffffffff)) == SplitBits!ulong(ulong(0), ulong(0xffffffff)));
    assert(splitbits(ulong(0xffffffff00000000)) == SplitBits!ulong(ulong(0xffffffff), ulong(0x00000000)));
    assert(splitbits(ulong(0xffffffffffffffff)) == SplitBits!ulong(ulong(0xffffffff), ulong(0xffffffff)));
    assert(splitbits(ulong(0x0123456789abcdef)) == SplitBits!ulong(ulong(0x01234567), ulong(0x89abcdef)));
}
unittest{ /// splitbits with uint input
    assert(splitbits(uint(0)) == SplitBits!uint(uint(0), uint(0)));
    assert(splitbits(uint(0xffff)) == SplitBits!uint(uint(0), uint(0xffff)));
    assert(splitbits(uint(0xffff0000)) == SplitBits!uint(uint(0xffff), uint(0x0000)));
    assert(splitbits(uint(0xffffffff)) == SplitBits!uint(uint(0xffff), uint(0xffff)));
    assert(splitbits(uint(0x12345678)) == SplitBits!uint(uint(0x1234), uint(0x5678)));
}
unittest{ /// splitbits with ushort input
    assert(splitbits(ushort(0)) == SplitBits!ushort(ushort(0), ushort(0)));
    assert(splitbits(ushort(0x00ff)) == SplitBits!ushort(ushort(0x00), ushort(0xff)));
    assert(splitbits(ushort(0xff00)) == SplitBits!ushort(ushort(0xff), ushort(0x00)));
    assert(splitbits(ushort(0xffff)) == SplitBits!ushort(ushort(0xff), ushort(0xff)));
    assert(splitbits(ushort(0x1234)) == SplitBits!ushort(ushort(0x12), ushort(0x34)));
}
unittest{ /// splitbits with ubyte input
    assert(splitbits(ubyte(0)) == SplitBits!ubyte(ubyte(0), ubyte(0)));
    assert(splitbits(ubyte(0x0f)) == SplitBits!ubyte(ubyte(0x0), ubyte(0xf)));
    assert(splitbits(ubyte(0xf0)) == SplitBits!ubyte(ubyte(0xf), ubyte(0x0)));
    assert(splitbits(ubyte(0xff)) == SplitBits!ubyte(ubyte(0xf), ubyte(0xf)));
    assert(splitbits(ubyte(0x12)) == SplitBits!ubyte(ubyte(0x1), ubyte(0x2)));
}

unittest{ /// SplitBits indexing
    immutable x = splitbits(uint(0x12345678));
    assert(x[1] == 0x1234);
    assert(x[0] == 0x5678);
    static assert(!is(typeof({x[2];})));
    // Also test the `mergebits` method of the output type
    assert(x.mergebits == 0x12345678);
}

unittest{ /// mergebits
    assert(mergebits(ulong(0x01234567), ulong(0x89abcdef)) == ulong(0x0123456789abcdef));
    assert(mergebits(uint(0x1234), uint(0x5678)) == uint(0x12345678));
    assert(mergebits(ushort(0x12), ushort(0x34)) == ushort(0x1234));
    assert(mergebits(ubyte(0x1), ubyte(0x2)) == ubyte(0x12));
}
