module mach.sys.endian;

private:

//

public:



version(BigEndian){
    enum Endian{
        BigEndian,
        LittleEndian,
        Platform = BigEndian
    }
}else{
    enum Endian{
        BigEndian,
        LittleEndian,
        Platform = LittleEndian
    }
}



T endianswap(T)(in T value) pure nothrow @nogc @trusted{
    T swapped = void;
    ubyte* src = cast(ubyte*) &value;
    ubyte* dst = (cast(ubyte*) &swapped) + T.sizeof - 1;
    foreach(_; 0 .. T.sizeof){
        *dst = *src;
        src++;
        dst--;
    }
    return swapped;
}



private version(unittest){
    import mach.test;
}
unittest{
    tests("Endian swap", {
        testeq(endianswap(ubyte(0xff)), 0xff);
        testeq(endianswap(ushort(0x00ff)), 0xff00);
        testeq(endianswap(uint(0x01020304)), 0x04030201);
        testeq(endianswap(ulong(0x0102030405060708)), 0x0807060504030201);
    });
}
