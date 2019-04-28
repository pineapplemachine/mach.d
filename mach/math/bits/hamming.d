module mach.math.bits.hamming;

private:

import mach.traits.primitives : isIntegral;

/++ Docs

The `hamming` function can be used to get the hamming weight of a primitive
integral type, which is a count of the number of 1 bits representing its
binary value.

+/

unittest{ /// Example
    assert(uint(0x101010).hamming == 3); // 3 bits
    assert(uint(0x111111).hamming == 6); // 6 bits
    assert(uint(0x000000).hamming == 0); // No bits
}

public:



/// Get the hamming weight of an integral value, which counts the number of
/// nonzero bits.
/// For example, the hamming weight of 0b00101101 is 4, because there are 4
/// nonzero bits.
/// http://cs-fundamentals.com/tech-interview/c/c-program-to-count-number-of-ones-in-unsigned-integer.php
auto hamming(N)(in N value) if(isIntegral!N){
    static if(N.sizeof == 8){
        ulong x = cast(ulong) value;
        x = x - ((x >> 1) & 0x5555555555555555);
        x = (x & 0x3333333333333333) + ((x >> 2) & 0x3333333333333333);
        x = (x + (x >> 4)) & 0x0F0F0F0F0F0F0F0F;
        x = x + (x >> 8);
        x = x + (x >> 16);
        x = x + (x >> 32);
        return x & 0x0000007F;
    }else static if(N.sizeof == 4){
        uint x = cast(uint) value;
        x = x - ((x >> 1) & 0x55555555);
        x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
        x = (x + (x >> 4)) & 0x0F0F0F0F;
        x = x + (x >> 8);
        x = x + (x >> 16);
        return x & 0x0000003F;
    }else static if(N.sizeof == 2){
        uint x = cast(uint) value;
        x = x - ((x >> 1) & 0x5555);
        x = (x & 0x3333) + ((x >> 2) & 0x3333);
        x = (x + (x >> 4)) & 0x0F0F;
        x = x + (x >> 8);
        return x & 0x0000001F;
    }else static if(N.sizeof == 1){
        uint x = cast(uint) value;
        x = x - ((x >> 1) & 0x55);
        x = (x & 0x33) + ((x >> 2) & 0x33);
        x = (x + (x >> 4)) & 0x0F;
        return x & 0x0F;
    }else{
        static assert(false, "Hamming weight not currently implemented for this type.");
    }
}



version(unittest){
    private:
    import mach.test;
    void HammingTest(T)(){
        testeq(hamming(T(0)), 0);
        testeq(hamming(T(1)), 1);
        testeq(hamming(T(2)), 1);
        testeq(hamming(T(3)), 2);
        testeq(hamming(T(7)), 3);
        testeq(hamming(T(8)), 1);
        testeq(hamming(T(127)), 7);
        static if(T.max >= 128){
            testeq(hamming(T(128)), 1);
            testeq(hamming(T(255)), 8);
        }
        static if(T.min == 0){
            testeq(uint.max.hamming, uint.sizeof << 3);
        }
    }
}
unittest{
    tests("Hamming weight", {
        HammingTest!long();
        HammingTest!ulong();
        HammingTest!int();
        HammingTest!uint();
        HammingTest!short();
        HammingTest!ushort();
        HammingTest!byte();
        HammingTest!ubyte();
    });
}
