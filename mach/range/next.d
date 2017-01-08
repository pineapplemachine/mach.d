module mach.range.next;

private:

import mach.traits : isRange, isBidirectionalRange;

/++ Docs

This module provides, very simply, methods for simultaneously retrieving the
front or back element of a range and popping that element, in the form of
`nextfront` and `nextback`.

The `nextfront` method can additionally be referenced by the name `next`.

+/

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof(0, 1, 2);
    assert(range.next == 0);
    assert(range.next == 1);
    assert(range.next == 2);
    assert(range.empty);
}

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof(5, 6, 7);
    assert(range.nextback == 7);
    assert(range.nextback == 6);
    assert(range.nextback == 5);
    assert(range.empty);
}

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
    tests("Next", {
        auto input = [1, 2, 3, 4];
        auto range = input.asrange;
        testeq(range.nextfront, 1);
        testeq(range.nextfront, 2);
        testeq(range.nextback, 4);
        testeq(range.nextback, 3);
        test(range.empty);
    });
}
