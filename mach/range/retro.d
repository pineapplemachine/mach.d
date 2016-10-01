module mach.range.retro;

private:

import mach.traits : isBidirectionalRange, isRandomAccessRange, hasNumericLength;
import mach.traits : isSlicingRange, isSavingRange, isTemplateOf;
import mach.range.asrange : asrange, validAsBidirectionalRange;
import mach.range.meta : MetaRangeEmptyMixin, MetaRangeLengthMixin;

public:



alias canRetro = validAsBidirectionalRange;
alias canRetroRange = isBidirectionalRange;

enum isRetroRange(Range) = isTemplateOf!(Range, RetroRange);



/// Return a range which iterates over some iterable in reverse-order.
auto retro(Iter)(auto ref Iter iter) if(canRetro!Iter){
    static if(!isRetroRange!Iter){
        auto range = iter.asrange;
        return RetroRange!(typeof(range))(range);
    }else{
        // Dont re-reverse an already reversed range
        return iter.source;
    }
}



struct RetroRange(Range) if(canRetroRange!Range){
    mixin MetaRangeEmptyMixin!Range;
    mixin MetaRangeLengthMixin!Range;
    
    Range source;
    
    this(Range source){
        this.source = source;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this.source.back;
    }
    void popFront() in{assert(!this.empty);} body{
        this.source.popBack();
    }
    
    @property auto back() in{assert(!this.empty);} body{
        return this.source.front;
    }
    void popBack() in{assert(!this.empty);} body{
        this.source.popFront();
    }
    
    static if(hasNumericLength!Range){
        static if(isRandomAccessRange!Range){
            auto opIndex(in size_t index) in{
                assert(index >= 0 && index < this.length);
            }body{
                return this.source[cast(size_t)(this.source.length - index - 1)];
            }
        }
        static if(isSlicingRange!Range){
            typeof(this) opSlice(in size_t low, in size_t high) in{
                assert(low >= 0 && high >= low && high <= this.length);
            }body{
                auto sourcelow = cast(size_t)(this.source.length - high);
                auto sourcehigh = cast(size_t)(this.source.length - low);
                return typeof(this)(this.source[sourcelow .. sourcehigh]);
            }
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save);
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.next : nextback;
}
unittest{
    tests("Reversed", {
        auto input = [0, 1, 2, 3];
        test("Iteration",
            input.retro.equals([3, 2, 1, 0])
        );
        tests("Random access", {
            testeq(input.retro[0], 3);
            testeq(input.retro[3], 0);
            testeq(input.retro[$-1], 0);
            testfail({input.retro[$];});
        });
        tests("Slicing", {
            auto range = input.retro;
            test(range[0 .. 0].equals(new int[0]));
            test(range[$ .. $].equals(new int[0]));
            test(range[0 .. $-1].equals([3, 2, 1]));
            test(range[1 .. $-1].equals([2, 1]));
            test(range[1 .. $].equals([2, 1, 0]));
            testfail({range[0 .. $+1];});
        });
        tests("Bidirectionality", {
            auto range = input.retro;
            testeq(range.front, 3);
            testeq(range.back, 0);
            testeq(range.nextback, 0);
            testeq(range.nextback, 1);
            testeq(range.nextback, 2);
            testeq(range.nextback, 3);
            test(range.empty);
            testfail({range.front;});
            testfail({range.popFront;});
            testfail({range.back;});
            testfail({range.popBack;});
        });
    });
}
