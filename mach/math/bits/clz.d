module mach.math.bits.clz;

private:

import mach.traits.primitives : isIntegral;

/++ Docs

The `clz` function returns the number of leading zeros for an integer value.
It returns the number of bits in the value when there were no set bits.

+/

unittest { /// Example
    assert(clz!int(-1) == 0);
    assert(clz!int(0) == 32);
    assert(clz!int(0x00F00000) == 8);
}

public:

/// Count leading zeros.
size_t clz(T)(in T value) if(isIntegral!T) {
    static if(T.sizeof == 8) alias X = long;
    else static if(T.sizeof == 4) alias X = int;
    else static if(T.sizeof == 2) alias X = short;
    else static if(T.sizeof == 1) alias X = byte;
    else static assert(T.sizeof <= 8, "Unsupported integer type.");
    if(value == 0) {
        return 8 * T.sizeof;
    }
    size_t i = 0;
    X x = value;
    static if(T.sizeof == 8) {
        if((x & X(0xFFFFFFFF00000000)) == 0) {
            i += 32;
            x <<= 32;
        }
    }
    static if(T.sizeof >= 4) {
        if((x & (cast(X)(0xFFFF0000) << (8 * X.sizeof - 32))) == 0) {
            i += 16;
            x <<= 16;
        }
    }
    static if(T.sizeof >= 2) {
        if((x & (cast(X)(0xFF00) << (8 * X.sizeof - 16))) == 0) {
            i += 8;
            x <<= 8;
        }
    }
    if((x & (cast(X)(0xF0) << (8 * X.sizeof - 8))) == 0) {
        i += 4;
        x <<= 4;
    }
    if((x & (cast(X)(0xC0) << (8 * X.sizeof - 8))) == 0) {
        i += 2;
        x <<= 2;
    }
    if((x & (cast(X)(0x80) << (8 * X.sizeof - 8))) == 0) {
        i += 1;
    }
    return i;
}

unittest { /// Count leading zeros of a zero value
    assert(clz(byte(0)) == 8);
    assert(clz(ubyte(0)) == 8);
    assert(clz(short(0)) == 16);
    assert(clz(ushort(0)) == 16);
    assert(clz(int(0)) == 32);
    assert(clz(uint(0)) == 32);
    assert(clz(long(0)) == 64);
    assert(clz(ulong(0)) == 64);
}

unittest { /// Count leading zeros of values with first bit set
    assert(clz(ubyte(0x80)) == 0);
    assert(clz(ushort(0x8000)) == 0);
    assert(clz(uint(0x80000000)) == 0);
    assert(clz(ulong(0x8000000000000000)) == 0);
}

unittest { /// Count leading zeros of a nonzero value
    assert(clz(ubyte(0x10)) == 3);
    assert(clz(ushort(0x10)) == 11);
    assert(clz(uint(0x10)) == 27);
    assert(clz(ulong(0x10)) == 59);
}
