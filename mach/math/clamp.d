module mach.math.clamp;

private:

import mach.traits : isNumeric;

public:



auto clamp(T)(ref T value, in T min, in T max) if(isNumeric!T){
    if(value < min) value = min;
    if(value > max) value = max;
    return value;
}



unittest{
    int i = 10;
    assert(i.clamp(0, 20) == 10);
    assert(i == 10);
    assert(i.clamp(0, 9) == 9);
    assert(i == 9);
    assert(i.clamp(10, 20) == 10);
    assert(i == 10);
}
