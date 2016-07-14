module mach.range.split;

private:

import std.traits : isIntegral;
import mach.traits : hasProperty, hasNumericLength, ElementType;
import mach.traits : isFiniteIterable, isSavingRange;
import mach.range.asrange : asrange, validAsRange, AsRangeType;
import mach.range.find : findalliter, findallelements;
import mach.range.find : canFindAllIterable, canFindAllElements;
import mach.range.pluck : pluck;

public:



alias DefaultSplitPredicate = (a, b) => (a == b);
alias DefaultSplitIndex = size_t;

alias validSplitIndex = isIntegral;

template canSplit(alias pred, Index, Iter, Delim){
    static if(validAsRange!Iter) alias Source = AsRangeType!Iter;
    else alias Source = Iter;
    enum bool canSplit = (
        validSplitIndex!Index && (
            canFindAllIterable!(pred, Index, Source, Delim) ||
            canFindAllElements!(e => pred(e, Delim.init), Index, Source)
        )
    );
}



auto split(alias pred = DefaultSplitPredicate, Index = DefaultSplitIndex, Iter, Delim)(
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
    return SplitIterableRange!(Source, typeof(indexes))(
        source, indexes, delimlength
    );
}



struct SplitIterableRange(Iter, Delims, Index = DefaultSplitIndex){
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
        return this.source[
            this.segmentbegin ..
            this.delimindexes.empty ? this.source.length : this.delimindexes.front
        ];
    }
    void popFront() in{assert(!this.empty);} body{
        static if(Finite){
            if(this.delimindexes.empty){
                this.empty = true;
                return;
            }
        }
        this.segmentbegin = this.delimindexes.front + this.delimlength;
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
    });
}
