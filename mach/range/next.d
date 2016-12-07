module mach.range.next;

private:

import mach.traits : isRange, isBidirectionalRange;

public:



/// Get the frontmost value of a range and then pop it.
auto ref nextfront(Range)(auto ref Range range) if(isRange!Range) in{
    assert(!range.empty);
}body{
    scope(exit) range.popFront();
    return range.front;
}

/// Get the backmost value of a range and then pop it.
auto ref nextback(Range)(auto ref Range range) if(isBidirectionalRange!Range) in{
    assert(!range.empty);
}body{
    scope(exit) range.popBack();
    return range.back;
}

alias next = nextfront;



version(unittest){
    private:
    import mach.test;
    import mach.range.asrange : asrange;
}
unittest{
    tests("next", {
        auto input = [1, 2, 3, 4];
        auto range = input.asrange;
        testeq(range.nextfront, 1);
        testeq(range.nextfront, 2);
        testeq(range.nextback, 4);
        testeq(range.nextback, 3);
        test(range.empty);
    });
}
