module mach.math.log;

private:

import mach.traits : Unqual, isIntegral;
import std.math : E, log, floor, ceil;

public:



/// Get ceil(log(n)) of some number.
/// TODO: Optimize
auto clog(alias base = E, N)(N number){
    enum auto logbase = log(base);
    return cast(long) ceil(log(number) / logbase);
}

/// Get floor(log(n)) of some number.
/// TODO: Optimize
auto flog(alias base = E, N)(N number){
    enum auto logbase = log(base);
    return cast(long) floor(log(number) / logbase);
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Log", {
        tests("Ceil", {
            testeq(clog!2(1), 0);
            testeq(clog!2(2), 1);
            testeq(clog!2(4), 2);
            testeq(clog!2(8), 3);
            testeq(clog!2(9), 4);
            testeq(clog!10(1), 0);
            testeq(clog!10(10), 1);
            testeq(clog!10(11), 2);
        });
        tests("Floor", {
            testeq(flog!2(1), 0);
            testeq(flog!2(2), 1);
            testeq(flog!2(4), 2);
            testeq(flog!2(8), 3);
            testeq(flog!2(9), 3);
            testeq(flog!10(1), 0);
            testeq(flog!10(10), 1);
            testeq(flog!10(11), 1);
        });
    });
}
