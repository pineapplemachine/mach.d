module mach.range.elementcount;

private:

import mach.traits : isRange, hasNumericLength, hasNumericRemaining;

/++ Docs

A notable difference between ranges and other iterables in mach is that while
they both indicate the number of elements they contain with the `length`
property, for a partially-consumed range that property no longer represents
the number of elements that should be expected to be handled when, from that
state, enumerating the range. To get the number of elements that enumerating
a range in its present state would result in, the `remaining` property is used.

The `elementcount` function is intended as a way to get the number of elements
that iteration would turn up, e.g. via `foreach`, given the current state of
the input. For ranges the function returns the `remaining` property and for
other types it returns the `length` property.
The function isn't valid for ranges that don't have a numeric `remaining`
property or for other types that don't have a numeric `length`.

+/

unittest{ /// Example
    assert("hello".elementcount == 5);
    assert([0, 1, 2, 3].elementcount == 4);
}

unittest{ /// Example
    import mach.range.rangeof : rangeof;
    auto range = rangeof(0, 1, 2, 3);
    assert(range.elementcount == 4);
    range.popFront();
    assert(range.elementcount == 3); // Correct even for partially-consumed ranges.
}

public:



/// Determine whether a type is valid input for `elementtype`.
template canGetElementCount(T){
    enum bool canGetElementCount = (
        (!isRange!T && hasNumericLength!T) ||
        (isRange!T && hasNumericRemaining!T)
    );
}


/// Implements a generic way to determine the number of elements that can be
/// expected to be consumed when enumerating some input.
/// For ranges, returns the `remaining` property.
/// For iterables that are not ranges, returns the `length` property.
auto elementcount(T)(auto ref T iter) if(canGetElementCount!T){
    static if(isRange!T){
        return iter.remaining;
    }else{
        return iter.length;
    }
}



version(unittest){
    private:
    struct TestRange{
        size_t low, high;
        size_t index = 0;
        @property bool empty() const{return this.index == this.length;}
        @property auto length() const{return this.high - this.low;}
        @property auto remaining() const{return this.length - this.index;}
        @property auto front() const{return this.low + this.index;}
        void popFront(){this.index++;}
    }
}
unittest{
    // Iterable element counts
    assert(new int[0].elementcount == 0);
    assert([0, 1, 2].elementcount == 3);
    assert([0: 0, 1: 1].elementcount == 2);
    // Range element counts
    assert(TestRange(0, 0).elementcount == 0);
    assert(TestRange(0, 4).elementcount == 4);
    // Partially-consumed range
    auto range = TestRange(0, 5);
    assert(range.elementcount == 5);
    range.popFront();
    assert(range.elementcount == 4);
}
