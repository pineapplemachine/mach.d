module mach.range.retro;

private:

import mach.traits : isBidirectionalRange, isRandomAccessRange, hasNumericLength;
import mach.traits : isMutableRange, isMutableFrontRange, isMutableBackRange;
import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
import mach.traits : isSlicingRange, isSavingRange, isTemplateOf;
import mach.range.asrange : asrange, validAsBidirectionalRange;
import mach.range.meta : MetaRangeEmptyMixin, MetaRangeLengthMixin;

public:



/// Determine if an input iterable can be enumerated in reverse via `retro`.
template canRetro(T){
    enum bool canRetro = validAsBidirectionalRange!T;
}

/// Determine if an input range can be enumerated in reverse via `RetroRange`.
template canRetroRange(T){
    enum bool canRetroRange = isBidirectionalRange!T;
}

/// Determine whether a range is one resulting from a call to `retro`.
template isRetroRange(Range){
    enum bool isRetroRange = isTemplateOf!(Range, RetroRange);
}



/// Return a range which iterates over some iterable in reverse order.
auto retro(Iter)(auto ref Iter iter) if(canRetro!Iter){
    static if(!isRetroRange!Iter){
        auto range = iter.asrange;
        return RetroRange!(typeof(range))(range);
    }else{
        // Dont re-reverse an already reversed range
        return iter.source;
    }
}



/// Range for enumerating over the elements of an input range in reverse order.
struct RetroRange(Range) if(canRetroRange!Range){
    alias Element = typeof(Range.front);
    
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
    
    static if(isMutableRange!Range){
        enum bool mutable = true;
        static if(isMutableFrontRange!Range){
            @property void front(Element value) in{assert(!this.empty);} body{
                this.source.back = value;
            }
        }
        static if(isMutableBackRange!Range){
            @property void back(Element value) in{assert(!this.empty);} body{
                this.source.front = value;
            }
        }
        static if(isMutableRemoveFrontRange!Range){
            auto removeFront(){
                return this.source.removeBack();
            }
        }
        static if(isMutableRemoveBackRange!Range){
            auto removeBack(){
                return this.source.removeFront();
            }
        }
    }else{
        enum bool mutable = false;
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.next : nextback;
    import mach.collect : DoublyLinkedList;
}
unittest{
    tests("Reversed", {
        auto input = [0, 1, 2, 3];
        tests("Iteration", {
            input.retro.equals([3, 2, 1, 0]);
        });
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
        tests("Length & Remaining", {
            auto range = input.retro;
            testeq(range.length, 4);
            testeq(range.remaining, 4);
            range.popFront();
            testeq(range.length, 4);
            testeq(range.remaining, 3);
            range.popFront();
            range.popFront();
            range.popFront();
            testeq(range.length, 4);
            testeq(range.remaining, 0);
        });
        tests("Saving", {
            auto range = input.retro;
            auto saved = range.save;
            range.popFront();
            testeq(range.remaining, 3);
            testeq(saved.remaining, 4);
        });
        tests("Mutability", {
            auto list = new DoublyLinkedList!int([0, 1, 2, 3]);
            auto range = list.values.retro;
            test!equals(list.ivalues, [0, 1, 2, 3]);
            testeq(range.front, 3);
            range.front = 4;
            testeq(range.front, 4);
            test!equals(list.ivalues, [0, 1, 2, 4]);
            testeq(range.back, 0);
            range.back = 5;
            testeq(range.back, 5);
            test!equals(list.ivalues, [5, 1, 2, 4]);
            range.removeFront();
            test!equals(list.ivalues, [5, 1, 2]);
            range.removeBack();
            test!equals(list.ivalues, [1, 2]);
            range.popFront();
            testeq(range.front, 1);
            range.front = 3;
            testeq(range.front, 3);
            test!equals(list.ivalues, [3, 2]);
            range.removeFront();
            test!equals(list.ivalues, [2]);
            test(range.empty);
        });
    });
}
