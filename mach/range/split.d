module mach.range.split;

private:

import mach.traits : isIntegral, hasProperty, hasNumericLength, ElementType;
import mach.traits : isFiniteIterable, isSavingRange, canSliceSame;
import mach.range.asrange : asrange, validAsRange, AsRangeType;
import mach.range.find : findalliter, findallelements;
import mach.range.find : canFindAllIterable, canFindAllElements;
import mach.range.pluck : pluck;

public:



// TODO: Split ranges not supporting slicing (is that even doable?)



alias DefaultSplitPredicate = (a, b) => (a == b);
alias DefaultSplitIndex = size_t;

alias validSplitIndex = isIntegral;

template canSplit(alias pred, Index, Iter){
    static if(validAsRange!Iter) alias Source = AsRangeType!Iter;
    else alias Source = Iter;
    enum bool canSplit = canSliceSame!Source && (
        validSplitIndex!Index && (
            canFindAllElements!(pred, Index, Source)
        )
    );
}

template canSplit(alias pred, Index, Iter, Delim){
    static if(validAsRange!Iter) alias Source = AsRangeType!Iter;
    else alias Source = Iter;
    enum bool canSplit = canSliceSame!Source && (
        validSplitIndex!Index && (
            canFindAllIterable!(pred, Index, Source, Delim) ||
            canFindAllElements!(e => pred(e, Delim.init), Index, Source)
        )
    );
}



/// Indicates whether to include the delimiter at the beginning of each element
/// of a split range, and the front, both, or neither.
enum SplitInclusionMode{
    Neither, Front, Back, Both
}

alias DefaultSplitInclusionMode = SplitInclusionMode.Neither;



auto split(
    SplitInclusionMode mode, Index = DefaultSplitIndex, Iter, Delim
)(
    auto ref Iter iter, auto ref Delim delimiter
) if(canSplit!(DefaultSplitPredicate, Index, Iter, Delim)){
    return split!(
        DefaultSplitPredicate, mode, Index, Iter, Delim
    )(iter, delimiter);
}

// TODO: Make these two implementations cleaner, I'm doing a lot of copypasting
// right now just to get it working.
auto split(
    alias pred = DefaultSplitPredicate,
    SplitInclusionMode mode = DefaultSplitInclusionMode,
    Index = DefaultSplitIndex, Iter
)(
    auto ref Iter iter
) if(canSplit!(pred, Index, Iter)){
    static if(validAsRange!Iter){
        auto source = iter.asrange;
    }else{
        alias source = iter;
    }
    alias Source = typeof(source);
    auto found = source.findallelements!(pred, Index, Source)();
    auto delimlength = 1;
    static if(validSplitIndex!(ElementType!(typeof(found)))){
        alias indexes = found;
    }else static if(hasProperty!(ElementType!(typeof(found)), `index`)){
        auto indexes = found.pluck!`index`;
    }else{
        assert(false); // This shouldn't happen
    }
    enum bool beginwithdelim = (
        mode is SplitInclusionMode.Front || mode is SplitInclusionMode.Both
    );
    enum bool endwithdelim = (
        mode is SplitInclusionMode.Back || mode is SplitInclusionMode.Both
    );
    return SplitIterableRange!(
        Source, typeof(indexes), Index, beginwithdelim, endwithdelim
    )(
        source, indexes, delimlength
    );
}

auto split(
    alias pred = DefaultSplitPredicate,
    SplitInclusionMode mode = DefaultSplitInclusionMode,
    Index = DefaultSplitIndex, Iter, Delim
)(
    auto ref Iter iter, auto ref Delim delimiter
) if(canSplit!(pred, Index, Iter, Delim)){
    static if(validAsRange!Iter){
        auto source = iter.asrange;
    }else{
        alias source = iter;
    }
    alias Source = typeof(source);
    static if(canFindAllIterable!(pred, Index, Source, Delim)){
        auto found = source.findalliter!(pred, Index, Source, Delim)(delimiter);
        auto delimlength = delimiter.length;
    }else static if(canFindAllElements!(e => pred(e, delimiter), Index, Source)){
        auto found = source.findallelements!(e => pred(e, delimiter), Index, Source)();
        auto delimlength = 1;
    }else{
        assert(false); // This shouldn't happen
    }
    static if(validSplitIndex!(ElementType!(typeof(found)))){
        alias indexes = found;
    }else static if(hasProperty!(ElementType!(typeof(found)), `index`)){
        auto indexes = found.pluck!`index`;
    }else{
        assert(false); // Also shouldn't happen
    }
    enum bool beginwithdelim = (
        mode is SplitInclusionMode.Front || mode is SplitInclusionMode.Both
    );
    enum bool endwithdelim = (
        mode is SplitInclusionMode.Back || mode is SplitInclusionMode.Both
    );
    return SplitIterableRange!(
        Source, typeof(indexes), Index, beginwithdelim, endwithdelim
    )(
        source, indexes, delimlength
    );
}



struct SplitIterableRange(
    Iter, Delims, Index = DefaultSplitIndex,
    bool beginwithdelim = false, bool endwithdelim = false
){
    enum bool Finite = isFiniteIterable!Delims;
    
    Iter source;
    Delims delimindexes;
    Index delimlength;
    Index segmentbegin;
    
    static if(Finite) bool empty;
    else enum bool empty = false;
    
    this(Iter source, Delims delimindexes, Index delimlength){
        this.source = source;
        this.delimindexes = delimindexes;
        this.delimlength = delimlength;
        this.segmentbegin = 0;
        static if(Finite) this.empty = false;
    }
    static if(Finite){
        this(
            Iter source, Delims delimindexes,
            Index delimlength, Index segmentindex, bool empty
        ){
            this.source = source;
            this.delimindexes = delimindexes;
            this.delimlength = delimlength;
            this.segmentbegin = segmentbegin;
            this.empty = empty;
        }
    }else{
        this(
            Iter source, Delims delimindexes,
            Index delimlength, Index segmentindex
        ){
            this.source = source;
            this.delimindexes = delimindexes;
            this.delimlength = delimlength;
            this.segmentbegin = segmentbegin;
        }
    }
    
    static if(hasNumericLength!Delims){
        @property auto length(){
            return this.delimindexes.length + 1;
        }
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
        Index high = void;
        if(this.delimindexes.empty){
            high = this.source.length;
        }else{
            static if(!endwithdelim) high = this.delimindexes.front;
            else high = this.delimindexes.front + this.delimlength;
        }
        return this.source[this.segmentbegin .. high];
    }
    void popFront() in{assert(!this.empty);} body{
        static if(Finite){
            if(this.delimindexes.empty){
                this.empty = true;
                return;
            }
        }
        static if(beginwithdelim) this.segmentbegin = this.delimindexes.front;
        else this.segmentbegin = this.delimindexes.front + this.delimlength;
        this.delimindexes.popFront();
    }
    
    static if(isSavingRange!Delims){
        @property typeof(this) save(){
            static if(Finite){
                return typeof(this)(
                    this.source, this.delimindexes.save,
                    this.delimlength, this.segmentbegin, this.empty
                );
            }else{
                return typeof(this)(
                    this.source, this.delimindexes.save,
                    this.delimlength, this.segmentbegin
                );
            }
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    import std.stdio;
    tests("Split", {
        tests("Range delimiter", {
            tests("Longer-than-one", {
                auto range = "hello..there..world".split("..");
                test(range.equals(["hello", "there", "world"]));
                static assert(isFiniteIterable!(typeof(range)));
            });
            tests("Single length", {
                auto range = "hello.there.world".split(".");
                test(range.equals(["hello", "there", "world"]));
                static assert(isFiniteIterable!(typeof(range)));
            });
        });
        tests("Element delimiter", {
            auto range = "hello.there.world".split('.');
            test(range.equals(["hello", "there", "world"]));
            static assert(isFiniteIterable!(typeof(range)));
        });
        tests("Element predicate", {
            auto range = "hello_there world".split!(e => e == '_' || e == ' ');
            test(range.equals(["hello", "there", "world"]));
        });
        tests("No delimiters", {
            auto range = "test".split(", ");
            test(range.equals(["test"]));
        });
        tests("Delimiters in series", {
            auto range = "x,y,,z".split(",");
            test(range.equals(["x", "y", "", "z"]));
        });
        tests("Start/end with delimiter", {
            test("hi.".split(".").equals(["hi", ""]));
            test(".hi".split(".").equals(["", "hi"]));
            test(".hi.".split(".").equals(["", "hi", ""]));
        });
        tests("Elements begin/end with delim", {
            test("hi.hi".split!(SplitInclusionMode.Front)('.').equals(["hi", ".hi"]));
            test("hi.hi".split!(SplitInclusionMode.Back)('.').equals(["hi.", "hi"]));
            test("hi.hi".split!(SplitInclusionMode.Both)('.').equals(["hi.", ".hi"]));
        });
    });
}
