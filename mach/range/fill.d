module mach.range.fill;

private:

import mach.range.consume : consume;
import mach.range.mutate : mutate, canMutate;

public:



/// Write over all elements of a mutable iterable with some value.
auto ref fill(Iter, Fill)(auto ref Iter iter, Fill fillwith) if(
    canMutate!(Iter, (element) => (fillwith))
){
    iter.mutate!((element) => (fillwith)).consume;
}



version(unittest){
    private:
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
