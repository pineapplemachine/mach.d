module mach.range.walklength;

private:

import mach.traits : isFiniteIterable, canIncrement;

public:



enum canWalkLength(Iter) = isFiniteIterable!Iter;

enum canWalkLength(Iter, Length) = (
    canWalkLength!Iter && canIncrement!Length
);



/// Determine the length of a range by traversing it.
auto walklength(Iter, Length = size_t)(Iter iter, Length initial = Length.init) if(
    canWalkLength!(Iter, Length)
){
    auto length = initial;
    foreach(item; iter) length++;
    return length;
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("WalkLength", {
        testeq("hi".walklength, 2);
        testeq("hello".walklength, 5);
        testeq("".walklength, 0);
        testeq("hi".walklength(4), 6);
        testeq("hello".walklength(-6), -1);
        testeq("".walklength(1), 1);
    });
}
