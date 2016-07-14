import mach.traits : isRange, isBidirectionalRange, isElementPredicate;
import mach.traits : isMutableRange, isMutableFrontRange, isMutableBackRange;
import mach.traits : hasNumericLength;
import mach.range.asrange : asrange, validAsRange, validAsBidirectionalRange;
import mach.range.meta : MetaRangeMixin;



static enum StripMode{Front, Back, Both}



template canStrip(StripMode mode, Iter, alias pred){
    static if(mode is StripMode.Front){
        alias canStrip = canStripFront!(Iter, pred);
    }else static if(mode is StripMode.Back){
        alias canStrip = canStripBack!(Iter, pred);
    }else{
        alias canStrip = canStripBoth!(Iter, pred);
    }
}
enum canStripFront(Iter, alias pred) = (
    validAsRange!Iter && isElementPredicate!(pred, Iter)
);
enum canStripBack(Iter, alias pred) = (
    validAsBidirectionalRange!Iter && isElementPredicate!(pred, Iter)
);
enum canStripBoth(Iter, alias pred) = (
    canStripFront!(Iter, pred) && canStripBack!(Iter, pred)
);

enum canStripRange(StripMode mode, Iter, alias pred) = (
    canStrip!(mode, Iter, pred) && isElementPredicate!(pred, Iter)
);



auto stripmode(StripMode mode, alias pred, Iter)(auto ref Iter iter) if(
    canStrip!(mode, Iter, pred)
){
    auto range = iter.asrange;
    return StripModeRange!(mode, pred, typeof(range))(range);
}



/// Create a range which enumerates the items of some iterable starting with the
/// first element that doesn't match a predicate.
auto stripfront(alias pred, Iter)(auto ref Iter iter) if(canStripFront!(Iter, pred)){
    return stripmode!(StripMode.Front, pred, Iter)(iter);
}

/// Create a range which enumerates the items of some iterable ending with the
/// last element that doesn't match a predicate.
auto stripback(alias pred, Iter)(auto ref Iter iter) if(canStripBack!(Iter, pred)){
    return stripmode!(StripMode.Back, pred, Iter)(iter);
}

auto stripboth(alias pred, Iter)(auto ref Iter iter) if(canStripBoth!(Iter, pred)){
    return stripmode!(StripMode.Both, pred, Iter)(iter);
}



auto stripfront(Iter, Sub)(auto ref Iter iter, auto ref Sub sub) if(
    canStripFront!(Iter, (e) => (e == sub))
){
    return stripfront!((e) => (e == sub), Iter)(iter);
}

auto stripback(Iter, Sub)(auto ref Iter iter, auto ref Sub sub) if(
    canStripBack!(Iter, (e) => (e == sub))
){
    return stripback!((e) => (e == sub), Iter)(iter);
}

auto stripboth(Iter, Sub)(auto ref Iter iter, auto ref Sub sub) if(
    canStripBoth!(Iter, (e) => (e == sub))
){
    return stripboth!((e) => (e == sub), Iter)(iter);
}



auto StripModeRange(StripMode mode, alias pred, Range)(auto ref Range source) if(
    canStripRange!(mode, Range, pred)
){
    auto range = StripRange!(pred, Range)(source);
    static if(mode !is StripMode.Back) range.stripFront();
    static if(mode !is StripMode.Front) range.stripBack();
    return range;
}

struct StripRange(alias pred, Range){
    alias isBidirectional = isBidirectionalRange!Range;
    
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Save`
    );
    
    Range source;
    size_t stripped; /// Number of elements stripped from source range
    
    this(Range source, size_t stripped = 0){
        this.source = source;
        this.stripped = stripped;
    }
    
    @property auto front(){
        return this.source.front;
    }
    void popFront(){
        this.source.popFront();
    }
    void stripFront(){
        while(!this.source.empty && pred(this.source.front)){
            this.source.popFront();
            this.stripped++;
        }
    }
    
    static if(isBidirectional){
        @property auto back(){
            return this.source.back;
        }
        void popBack(){
            this.source.popBack();
        }
        void stripBack(){
            while(!this.source.empty && pred(this.source.back)){
                this.source.popBack();
                this.stripped++;
            }
        }
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length - this.stripped;
        }
    }
    
    static if(isMutableRange!Range){
        enum bool mutable = true;
        static if(isMutableFrontRange!Range){
            @property void front(Element value){
                this.source.front = value;
            }
        }
        static if(isMutableBackRange!Range){
            @property void back(Element value){
                this.source.back = value;
            }
        }
    }else{
        enum bool mutable = false;
    }
    
    // TODO: Slice
}



version(unittest){
    private:
    import std.ascii : isDigit;
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Strip", {
        auto input = "0011hi1100";
        auto blank = "";
        tests("Front", {
            test(blank.stripfront('0').equals(blank));
            test(input.stripfront('1').equals(input));
            test(input.stripfront('0').equals("11hi1100"));
            test(input.stripfront!isDigit.equals("hi1100"));
            testeq(input.stripfront('0').length, input.length - 2);
        });
        tests("Back", {
            test(blank.stripback('0').equals(blank));
            test(input.stripback('1').equals(input));
            test(input.stripback('0').equals("0011hi11"));
            test(input.stripback!isDigit.equals("0011hi"));
            testeq(input.stripback('0').length, input.length - 2);
        });
        tests("Both", {
            test(blank.stripboth('0').equals(blank));
            test(input.stripboth('1').equals(input));
            test(input.stripboth('0').equals("11hi11"));
            test(input.stripboth!isDigit.equals("hi"));
            testeq(input.stripboth('0').length, input.length - 4);
        });
    });
}
