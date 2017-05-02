module mach.range.fill;

private:

import mach.range.consume : consume;
import mach.range.mutate : mutate, canMutate;

/++ Docs

The `fill` function is an abstraction of the `mutate` function in
`mach.range.mutate` which assigns every element in a mutable input iterable
to a given value.

+/

unittest{ /// Example
    int[] array = [0, 1, 2, 3];
    array.fill(10);
    assert(array == [10, 10, 10, 10]);
}

public:



/// Write over all elements of a mutable iterable with some value.
auto ref fill(Iter, Fill)(auto ref Iter iter, Fill fillwith) if(
    canMutate!(Iter, element => fillwith)
){
    iter.mutate!(element => fillwith).consume;
}



private version(unittest){
    import mach.test;
}
unittest{
    tests("Fill", {
        int[] ints = [1, 2, 3];
        ints.fill(0);
        testeq(ints, [0, 0, 0]);
        ints.fill(1);
        testeq(ints, [1, 1, 1]);
    });
}
