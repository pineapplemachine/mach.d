module mach.math.bits.ctz;

private:

import mach.traits.primitives : isIntegral;

/++ Docs

The `ctz` function returns the number of trailing zeros for an integer value.
It returns the number of bits in the value when there were no set bits.

+/

unittest { /// Example
    assert(ctz!int(1) == 0);
    assert(ctz!int(0) == 32);
    assert(ctz!int(0x00F00000) == 20);
}

public:

/// Count trailing zeros.
size_t ctz(T)(in T value) if(isIntegral!T) {
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
        if((x & cast(T)(0x00000000FFFFFFFF)) == 0) {
            i += 32;
            x >>= 32;
        }
    }
    static if(T.sizeof >= 4) {
        if((x & cast(T)(0x0000FFFF)) == 0) {
            i += 16;
            x >>= 16;
        }
    }
    static if(T.sizeof >= 2) {
        if((x & cast(T)(0x00FF)) == 0) {
            i += 8;
            x >>= 8;
        }
    }
    if((x & cast(T)(0x0F)) == 0) {
        i += 4;
        x >>= 4;
    }
    if((x & cast(T)(0x03)) == 0) {
        i += 2;
        x >>= 2;
    }
    if((x & cast(T)(0x01)) == 0) {
        i += 1;
    }
    return i;
}

unittest { /// Count trailing zeros of a zero value
    assert(ctz(byte(0)) == 8);
    assert(ctz(ubyte(0)) == 8);
    assert(ctz(short(0)) == 16);
    assert(ctz(ushort(0)) == 16);
    assert(ctz(int(0)) == 32);
    assert(ctz(uint(0)) == 32);
    assert(ctz(long(0)) == 64);
    assert(ctz(ulong(0)) == 64);
}

unittest { /// Count trailing zeros of values with last bit set
    assert(ctz(ubyte(1)) == 0);
    assert(ctz(ushort(1)) == 0);
    assert(ctz(uint(1)) == 0);
    assert(ctz(ulong(1)) == 0);
}

unittest { /// Count trailing zeros of a nonzero value
    assert(ctz(ubyte(0x10)) == 4);
    assert(ctz(ushort(0x10)) == 4);
    assert(ctz(uint(0x10)) == 4);
    assert(ctz(ulong(0x10)) == 4);
}
