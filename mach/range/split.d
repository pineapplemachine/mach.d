module mach.range.split;

private:

import mach.traits : hasNumericLength, isFiniteIterable;
import mach.range.asrange : asrange, validAsRange;
import mach.range.find : findall, canFindElement, canFindIterable, DefaultFindIndex; // TODO: lazy
import mach.range.pluck : pluck;

public:



// TODO
//template canSplit(alias compare, Iter, Delim){
//    static if(canFindElement!(
//}



auto split(alias compare = (a, b) => (a == b), Iter, Delim)(Iter iter, Delim delimiter){
    auto range = iter.asrange;
    auto found = range.findall!compare(delimiter).pluck!`index`;
    return SplitRange!(typeof(range), typeof(found))(range, found, delimiter.length);
}



struct SplitRange(Iter, Delims){
    enum bool Finite = isFiniteIterable!Delims;
    
    Iter source;
    Delims delimindexes;
    size_t delimlength;
    size_t segmentbegin;
    
    static if(Finite) bool empty;
    else enum bool empty = false;
    
    this(Iter source, Delims delimindexes, size_t delimlength){
        this.source = source;
        this.delimindexes = delimindexes;
        this.delimlength = delimlength;
        this.segmentbegin = 0;
        static if(Finite) this.empty = false;
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
}


unittest{
    // TODO
    //import std.stdio;
    //auto input = "hello";
    //auto range = input.split(". ");
    //writeln(range);
}
