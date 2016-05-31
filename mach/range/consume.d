module mach.range.consume;

private:

import mach.traits : isFiniteRange, isBidirectionalRange;

public:



alias canConsume = isFiniteRange;
enum canConsumeReverse(Range) = canConsume!Range && isBidirectionalRange!Range;



void consume(Range)(Range range) if(canConsume!Range){
    while(!range.empty) range.popFront();
}

void consumereverse(Range)(Range range) if(canConsumeReverse!Range){
    while(!range.empty) range.popBack();
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.asrange : asrange;
    struct SomeRange{
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
            SomeRange.consumed++;
        }
    }
}
unittest{
    tests("Consume", {
        auto range = SomeRange(0, 10);
        testf(range.empty);
        testeq(SomeRange.consumed, 0);
        range.consume;
        testeq(SomeRange.consumed, 10);
    });
}
