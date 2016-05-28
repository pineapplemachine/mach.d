module mach.range.each;

private:

import mach.traits : isFiniteIterable, isFiniteIterableReverse;

public:

void each(alias func, Iter)(Iter iter) if(isFiniteIterable!Iter){
    foreach(item; iter){
        func(item);
    }
}

void each_reverse(alias func, Iter)(Iter iter) if(isFiniteIterableReverse!Iter){
    foreach_reverse(item; iter){
        func(item);
    }
}

version(unittest){
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    auto input = [1, 2, 3, 4, 5];
    // Forward
    int[] output;
    input.each!((i){output ~= i;});
    test(output.equals(input));
    // Reverse
    int[] output_reverse;
    input.each_reverse!((i){output_reverse ~= i;});
    test(output_reverse.equals([5, 4, 3, 2, 1]));
}
