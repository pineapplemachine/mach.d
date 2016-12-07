module mach.range.each;

private:

import mach.traits : isFiniteIterable, isFiniteIterableReverse;

public:



void each(alias func, Iter)(auto ref Iter iter) if(isFiniteIterable!Iter){
    foreach(item; iter){
        func(item);
    }
}

void eachreverse(alias func, Iter)(auto ref Iter iter) if(isFiniteIterableReverse!Iter){
    foreach_reverse(item; iter){
        func(item);
    }
}



version(unittest){
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    int[] input = [1, 2, 3, 4, 5];
    // Forward
    int[] output;
    input.each!((i){output ~= i;});
    test(output.equals(input));
    // Reverse
    int[] outputreverse;
    input.eachreverse!((i){outputreverse ~= i;});
    test(outputreverse.equals([5, 4, 3, 2, 1]));
}
