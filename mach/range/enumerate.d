module mach.range.enumerate;

private:

import std.typecons : Tuple;
import std.traits : isImplicitlyConvertible;
import mach.traits : canIncrement, canDecrement, canCast, ElementType;
import mach.traits : isRange, isSavingRange, isRandomAccessRange, isSlicingRange;
import mach.traits : canReassign, isMutableFrontRange, isMutableBackRange;
import mach.traits : isMutableRandomRange, isMutableInsertRange;
import mach.traits : isMutableRemoveFrontRange, isMutableRemoveBackRange;
import mach.traits : hasLength, LengthType, canIndex, canSliceSame;
import mach.traits : hasSingleIndexParameter, SingleIndexParameter;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canEnumerateIndex(Index) = canIncrement!Index;
enum canEnumerateIndexBidirectional(Index) = (
    canEnumerateIndex!Index && canDecrement!Index
);

enum canEnumerate(Iter, Index = size_t) = (
    validAsRange!Iter && canEnumerateIndex!Index
);
enum canEnumerateRange(Range, Index = size_t) = (
    isRange!Range && canEnumerateIndex!Index
);
enum canEnumerateRangeBidirectional(Range, Index = size_t) = (
    isRange!Range && canEnumerateIndexBidirectional!Index &&
    hasLength!Range && canCast!(LengthType!Range, Index)
);



auto enumerate(Index = size_t, Iter)(
    auto ref Iter iter, Index initial = Index.init
) if(canEnumerate!(Iter, Index)){
    auto range = iter.asrange;
    return EnumerationRange!(Index, typeof(range))(range, initial);
}



struct EnumerationRange(Index = size_t, Range) if(canEnumerateRange!(Range, Index)){
    alias Element = Tuple!(Index, "index", ElementType!Range, "value");
    
    static enum bool isBidirectional = canEnumerateRangeBidirectional!(Range, Index);
    
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Length Dollar`
    );
    
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
    
    @property auto ref front(){
        return Element(this.frontindex, this.source.front);
    }
    void popFront(){
        this.source.popFront();
        this.frontindex++;
    }
    static if(isBidirectional){
        @property auto ref back(){
            return Element(this.backindex, this.source.back);
        }
        void popBack(){
            this.source.popBack();
            this.backindex--;
        }
    }
    
    static if(isRandomAccessRange!Range && canIndex!(Range, Index)){
        auto ref opIndex(Index index){
            return Element(index, this.source[index]);
        }
    }
    
    static if(isSlicingRange!Range && canSliceSame!(Range, Index)){
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
        static if(isMutableRandomRange!Range && canIndex!(Range, Index)){
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
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.pluck : pluck;
    import mach.collect : aslist;
}
unittest{
    tests("Enumerate", {
        auto input = ["ant", "bat", "cat", "dot", "eel"];
        testeq("Length",
            input.enumerate.length, input.length
        );
        testeq("Random access", 
            input.enumerate[1].value, input[1]
        );
        test("Indexes",
            input.enumerate.pluck!`index`.equals([0, 1, 2, 3, 4])
        );
        test("Values",
            input.enumerate.pluck!`value`.equals(input)
        );
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
    });
}
