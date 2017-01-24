module mach.math.clamp;

private:

import mach.traits : isNumeric;

/++ Docs

The `clamp` function can be used to ensure a value is within some bounds.

The function accepts three arguments.
When the first argument is less than the second, the second argument is returned.
When the first argument is greater than the third, the third is returned.
Otherwise, the first argument is returned.

+/

unittest{ /// Example
    assert(200.clamp(150, 250) == 200);
    assert(100.clamp(150, 250) == 150);
    assert(300.clamp(150, 250) == 250);
}

public:



auto clamp(T)(in T value, in T min, in T max) if(isNumeric!T){
    if(value < min) return min;
    if(value > max) return max;
    return value;
}



unittest{
    assert(10.clamp(0, 20) == 10);
    assert(10.clamp(10, 20) == 10);
    assert(10.clamp(0, 10) == 10);
    assert(10.clamp(0, 9) == 9);
    assert(10.clamp(11, 20) == 11);
}
