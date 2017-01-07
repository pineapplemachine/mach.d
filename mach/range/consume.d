module mach.range.consume;

private:

import mach.traits : isRange, isFiniteIterable, isIterableReverse;

/++ Docs

The `consume` function consumes an input iterable.
This is primarily useful for ranges which may modify state while they are
being enumerated.

For example, the `tap` function adds a callback for each element of an input
iterable. The callback is only evaluated as that element is popped from the
range.

+/

unittest{ /// Example
    import mach.range.tap : tap;
    int count = 0;
    // Increment `count` every time an element is popped.
    auto range = [0, 1, 2, 3].tap!((e){count++;});
    assert(count == 0);
    range.consume; // Consume the range
    assert(count == 4);
}

/++ Docs

The module also provides a `consumereverse` function for performing the same
consumption operation, but in reverse.

+/

unittest{ /// Example
    import mach.range.tap : tap;
    string str = "";
    auto range = "forwards".tap!((ch){str ~= ch;});
    assert(str == "");
    range.consumereverse;
    assert(str == "sdrawrof");
}

public:



/// Consume an iterable.
void consume(Iter)(auto ref Iter iter) if(
    isFiniteIterable!Iter
){
    static if(isRange!Iter){
        // Optimization for ranges: Don't ever actually acquire `front`.
        while(!iter.empty) iter.popFront();
    }else{
        foreach(_; iter){}
    }
}

/// Consume an iterable, in reverse.
void consumereverse(Iter)(auto ref Iter iter) if(
    isFiniteIterable!Iter && isIterableReverse!Iter
){
    static if(isRange!Iter){
        // Optimization for ranges: Don't ever actually acquire `back`.
        while(!iter.empty) iter.popBack();
    }else{
        foreach_reverse(_; iter){}
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.tap : tap;
    struct TestRange{
        static size_t consumed = 0;
        int index;
        int end;
        @property bool empty() const{
            return this.index >= this.end;
        }
        @property auto front() const{
            return this.index;
        }
        void popFront(){
            this.index++;
            TestRange.consumed++;
        }
    }
}
unittest{
    tests("Consume", {
        tests("Arrays", {
            new int[0].consume;
            [1, 2, 3].consume;
            new int[0].consumereverse;
            [1, 2, 3].consumereverse;
        });
        tests("Ranges", {
            TestRange.consumed = 0;
            auto range = TestRange(0, 10);
            testf(range.empty);
            testeq(TestRange.consumed, 0);
            range.consume;
            testeq(TestRange.consumed, 10);
        });
        tests("Reverse", {
            int[] array;
            auto range = [0, 1, 2].tap!((n){array ~= n;});
            assert(array.length == 0);
            range.consumereverse;
            assert(array == [2, 1, 0]);
        });
    });
}
