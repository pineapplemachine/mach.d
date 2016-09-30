module mach.range.enumerate;

private:

import mach.types : tuple;
import mach.traits : isRange, isSavingRange, isRandomAccessRange, isSlicingRange;
import mach.traits : canReassign, isMutableFrontRange, isMutableBackRange;
import mach.traits : isMutableRandomRange, isMutableInsertRange;
import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
import mach.traits : hasNumericLength, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeEmptyMixin, MetaRangeLengthMixin;

public:



enum canEnumerate(T) = (
    validAsRange!T
);
enum canEnumerateRange(T) = (
    isRange!T && canEnumerate!T
);
enum canEnumerateRangeBidirectional(T) = (
    hasNumericLength!T && canEnumerateRange!T
);



auto enumerate(Iter)(auto ref Iter iter, size_t initial = 0) if(canEnumerate!Iter){
    auto range = iter.asrange;
    return EnumerationRange!(typeof(range))(range, initial);
}



struct EnumerationRangeElement(T){
    size_t index;
    T value;
    @property auto astuple(){
        return tuple(this.index, this.value);
    }
    alias astuple this;
}

struct EnumerationRange(Range) if(canEnumerateRange!Range){
    alias Index = size_t;
    alias Element = EnumerationRangeElement!(ElementType!Range);
    static enum bool isBidirectional = canEnumerateRangeBidirectional!Range;
    
    mixin MetaRangeEmptyMixin!Range;
    mixin MetaRangeLengthMixin!Range;
    
    Range source;
    Index frontindex;
    static if(isBidirectional) Index backindex;
    
    this(typeof(this) range){
        static if(isBidirectional){
            this(range.source, range.frontindex, range.backindex);
        }else{
            this(range.source, range.frontindex);
        }
    }
    this(Range source, Index frontinitial = Index.init){
        static if(isBidirectional){
            Index backinitial = cast(Index) source.length;
            backinitial--;
            this(source, frontinitial, backinitial);
        }else{
            this.source = source;
            this.frontindex = frontinitial;
        }
    }
    static if(isBidirectional){
        this(Range source, Index frontinitial, Index backinitial){
            this.source = source;
            this.frontindex = frontinitial;
            this.backindex = backinitial;
        }
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
        return Element(this.frontindex, this.source.front);
    }
    void popFront() in{assert(!this.empty);} body{
        this.source.popFront();
        this.frontindex++;
    }
    static if(isBidirectional){
        @property auto ref back() in{assert(!this.empty);} body{
            return Element(this.backindex, this.source.back);
        }
        void popBack() in{assert(!this.empty);} body{
            this.source.popBack();
            this.backindex--;
        }
    }
    
    static if(isRandomAccessRange!Range){
        auto ref opIndex(Index index){
            return Element(index, this.source[index]);
        }
    }
    
    static if(isSlicingRange!Range){
        auto ref opSlice(Index low, Index high){
            static if(isBidirectional){
                return typeof(this)(this.source[low .. high], low, high);
            }else{
                return typeof(this)(this.source[low .. high], low);
            }
        }
    }
        
    static if(canReassign!Range){
        enum bool mutable = true;
        static if(isMutableFrontRange!Range){
            @property void front(Element element) in{
                assert(element.index == this.frontindex);
            }body{
                this.front = element.value;
            }
            @property void front(ElementType!Range value){
                this.source.front = value;
            }
        }
        static if(isMutableBackRange!Range){
            @property void back(Element element) in{
                assert(element.index == this.backindex);
            }body{
                this.back = element.value;
            }
            @property void back(ElementType!Range value){
                this.source.back = value;
            }
        }
        static if(isMutableRandomRange!Range){
            void opIndexAssign(Element element, Index index) in{
                assert(element.index == index);
            }body{
                this[index] = element.value;
            }
            void opIndexAssign(ElementType!Range value, Index index){
                this.source[index] = value;
            }
        }
        static if(isMutableInsertRange!Range){
            void insert(ElementType!Range value){
                this.source.insert(value);
            }
        }
        static if(isMutableRemoveFrontRange!Range){
            void removeFront(){
                this.source.removeFront();
                this.frontindex++;
            }
        }
        static if(isBidirectional && isMutableRemoveBackRange!Range){
            void removeBack(){
                this.source.removeBack();
                this.backindex++;
            }
        }
    }else{
        enum bool mutable = false;
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            static if(isBidirectional){
                return typeof(this)(this.source.save, this.frontindex, this.backindex);
            }else{
                return typeof(this)(this.source.save, this.frontindex);
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.pluck : pluck;
    import mach.collect : aslist;
}
unittest{
    tests("Enumerate", {
        auto input = ["ant", "bat", "cat", "dot", "eel"];
        testeq(input.enumerate.length, input.length); // Length
        testeq(input.enumerate[1].value, input[1]); // Random access
        test(input.enumerate.pluck!`index`.equals([0, 1, 2, 3, 4])); // Indexes
        test(input.enumerate.pluck!`value`.equals(input)); // Values
        tests("Slicing", {
            test(input.enumerate[1 .. $-1].pluck!`index`.equals([1, 2, 3]));
            test(input.enumerate[1 .. $-1].pluck!`value`.equals(input[1 .. $-1]));
        });
        tests("Mutability", {
            tests("Array", {
                char[] input = ['a', 'b', 'c'];
                auto range = input.enumerate;
                range.front = 'x';
                testeq(input[0], 'x');
                range.back = 'y';
                testeq(input[$-1], 'y');
                range[1] = 'z';
                testeq(input[1], 'z');
            });
            tests("Linked list", {
                auto input = ['a', 'b', 'c'].aslist;
                auto range = input.enumerate;
                range.front = 'x';
                testeq(input[0], 'x');
                range.back = 'y';
                testeq(input[$-1], 'y');
                range.removeFront();
                testeq(input.asarray, "by");
                range.removeBack();
                testeq(input.asarray, "b");
                range.insert('z');
                testeq(input.length, 2);
            });
        });
        tests("Static array", {
            int[5] ints = [0, 1, 2, 3, 4];
            foreach(x, y; ints.enumerate) testeq(x, y);
        });
        tests("Immutable source", {
            const(const(int)[]) ints = [0, 1, 2, 3, 4];
            foreach(x, y; ints.enumerate) testeq(x, y);
        });
    });
}
