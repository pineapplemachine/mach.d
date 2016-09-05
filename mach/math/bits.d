module mach.math.bits;

private:

//

public:



/// http://cs-fundamentals.com/tech-interview/c/c-program-to-count-number-of-ones-in-unsigned-integer.php
auto hamming(N)(in N value) if(is(N == int) || is(N == uint)){
    uint x = cast(uint) value;
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    x = (x + (x >> 4)) & 0x0F0F0F0F;
    x = x + (x >> 8);
    x = x + (x >> 16);
    return x & 0x0000003F;
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Hamming", {
        tests("32 bit", {
            testeq(int(0).hamming, 0);
            testeq(int(1).hamming, 1);
            testeq(int(2).hamming, 1);
            testeq(int(3).hamming, 2);
            testeq(int(8).hamming, 1);
            testeq(int(127).hamming, 7);
            testeq(int(128).hamming, 1);
            testeq(int(255).hamming, 8);
            testeq(uint(8).hamming, 1);
            testeq(uint(127).hamming, 7);
            testeq(uint(128).hamming, 1);
            testeq(uint(255).hamming, 8);
            testeq(uint.max.hamming, uint.sizeof << 3);
        });
    });
}
