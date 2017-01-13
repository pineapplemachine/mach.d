module mach.math.ints.log2;

private:

import mach.traits : Unqual, isIntegral;

public:



// Credit http://stackoverflow.com/a/22701843/4099022



/// Get ceil(log2(n)) of some positive integer.
auto clog2(N)(N number) if(isIntegral!N) in{
    assert(number > 0);
}body{
    Unqual!N log, n = number - 1;
    while(n > 0){
        log++; n >>= 1;
    }
    return log;
}

/// Get floor(log2(n)) of some positive integer.
auto flog2(N)(N number) if(isIntegral!N) in{
    assert(number > 0);
}body{
    Unqual!N log, n = number;
    while(n > 1){
        log++; n >>= 1;
    }
    return log;
}



unittest{
    // flog2
    assert(flog2(1) == 0);
    assert(flog2(2) == 1);
    assert(flog2(4) == 2);
    assert(flog2(8) == 3);
    assert(flog2(9) == 3);
    // clog2
    assert(clog2(1) == 0);
    assert(clog2(2) == 1);
    assert(clog2(4) == 2);
    assert(clog2(8) == 3);
    assert(clog2(9) == 4);
}
