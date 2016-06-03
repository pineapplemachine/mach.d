module mach.range.walk;

private:

import mach.traits : isFiniteIterable, canIncrement;

public:



enum canWalk(Iter) = isFiniteIterable!Iter;

enum canWalk(Iter, Length) = (
    canWalk!Iter && canIncrement!Length
);



/// Determine the length of a range by traversing it.
auto walk(Iter, Length = size_t)(Iter iter, Length initial = Length.init) if(
    canWalk!(Iter, Length)
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
    tests("Walk", {
        testeq("hi".walk, 2);
        testeq("hello".walk, 5);
        testeq("".walk, 0);
        testeq("hi".walk(4), 6);
        testeq("hello".walk(-6), -1);
        testeq("".walk(1), 1);
    });
}
