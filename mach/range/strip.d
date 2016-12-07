module mach.range.strip;

private:

import mach.traits : isRange, isBidirectionalRange, ElementType;
import mach.traits : isMutableRange, isMutableFrontRange, isMutableBackRange;
import mach.traits : isSlicingRange, isRandomAccessRange, hasNumericLength;
import mach.range.asrange : asrange, validAsRange, validAsBidirectionalRange;
import mach.range.meta : MetaRangeMixin;

public:



/// Determine whether an iterable can be stripped with the given predicate
/// and front/back flags.
template canStrip(bool front, bool back, Iter, alias pred){
    static if(back){
        enum bool canStrip = (
            validAsBidirectionalRange!Iter && is(typeof({
                if(pred(ElementType!Iter.init)){}
            }))
        );
    }else static if(front){
        enum bool canStrip = (
            validAsRange!Iter && is(typeof({
                if(pred(ElementType!Iter.init)){}
            }))
        );
    }else{
        enum bool canStrip = true;
    }
}

enum canStripRange(bool front, bool back, Range, alias pred) = (
    canStrip!(front, back, Range, pred) && isRange!Range
);

enum canStripRange(Range, alias pred) = (
    isRange!Range && is(typeof({
        if(pred(ElementType!Range.init)){}
    }))
);



/// Return a range which iterates over the elements in a source iterable, with
/// elements at the front or back matching a predicate excluded.
/// The front and back template arguments can be used to control which ends of
/// the range are stripped. By default, both ends of the range are stripped.
auto strip(alias pred, bool front = true, bool back = true, Iter)(auto ref Iter iter) if(
    canStrip!(front, back, Iter, pred)
){
    static if(front || back){
        auto range = iter.asrange;
        return MakeStripRange!(front, back, pred, typeof(range))(range);
    }else{
        return iter;
    }
}

/// Return a range which iterates over the elements in a source iterable, with
/// elements at the front or back being equal to the provided value excluded.
auto strip(bool front = true, bool back = true, Iter, Sub)(
    auto ref Iter iter, auto ref Sub sub
) if(canStrip!(front, back, Iter, (e) => (e == sub))){
    static if(front || back){
        return strip!((e) => (e == sub), front, back, Iter)(iter);
    }else{
        return iter;
    }
}



/// Used to define stripfront, stripback, and stripboth methods.
template StripMethodTemplate(bool front, bool back){
    auto StripMethodTemplate(alias pred, Iter)(auto ref Iter iter) if(
        canStrip!(front, back, Iter, pred)
    ){
        return strip!(pred, front, back, Iter)(iter);
    }
    auto StripMethodTemplate(Iter, Sub)(auto ref Iter iter, auto ref Sub sub) if(
        canStrip!(front, back, Iter, (e) => (e == sub))
    ){
        return strip!(front, back, Iter, Sub)(iter, sub);
    }
}



/// Strip only the front of the input iterable.
alias stripfront = StripMethodTemplate!(true, false);
/// Strip only the back of the input iterable.
alias stripback = StripMethodTemplate!(false, true);
/// Strip both ends of the input iterable.
alias stripboth = StripMethodTemplate!(true, true);



/// Used to construct a StripRange object for the given arguments.
auto MakeStripRange(bool front, bool back, alias pred, Range)(auto ref Range source) if(
    canStripRange!(front, back, Range, pred)
){
    static if(front || back){
        auto range = StripRange!(pred, Range)(source);
        static if(front) range.stripFront();
        static if(back) range.stripBack();
        return range;
    }else{
        return source;
    }
}

struct StripRange(alias pred, Range) if(canStripRange!(Range, pred)){
    alias isBidirectional = isBidirectionalRange!Range;
    
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Save`
    );
    
    Range source;
    /// Number of elements stripped from the front of the source range
    size_t strippedfront;
    /// Number of elements stripped from the back of the source range
    static if(isBidirectional) size_t strippedback;
    
    this(Range source, size_t strippedfront = 0){
        static if(isBidirectional){
            this(source, strippedfront, 0);
        }else{
            this.source = source;
            this.strippedfront = strippedfront;
        }
    }
    static if(isBidirectional){
        this(Range source, size_t strippedfront, size_t strippedback){
            this.source = source;
            this.strippedfront = strippedfront;
            this.strippedback = strippedback;
        }
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
            this.strippedfront++;
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
                this.strippedback++;
            }
        }
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            static if(isBidirectional){
                return this.source.length - this.strippedfront - this.strippedback;
            }else{
                return this.source.length - this.strippedfront;
            }
        }
        alias opDollar = length;
    }
    
    static if(isRandomAccessRange!Range){
        auto opIndex(size_t index) in{
            assert(index >= 0);
            static if(hasNumericLength!(typeof(this))) assert(index < this.length);
        }body{
            return this.source[index + this.strippedfront];
        }
    }
    
    static if(isSlicingRange!Range){
        auto opSlice(size_t low, size_t high) in{
            assert(low >= 0 && high >= low);
            static if(hasNumericLength!(typeof(this))) assert(high <= this.length);
        }body{
            return typeof(this)(this.source[
                low + this.strippedfront .. high + this.strippedfront
            ]);
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
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.next : nextback;
    bool isdigit(in char ch){
        return ch >= '0' && ch <= '9';
    }
}
unittest{
    tests("Strip", {
        auto input = "0011hi1100";
        auto blank = "";
        tests("Front", {
            test(blank.stripfront('0').equals(blank));
            test(input.stripfront('1').equals(input));
            test(input.stripfront('0').equals("11hi1100"));
            test(input.stripfront!isdigit.equals("hi1100"));
            testeq(input.stripfront('0').length, input.length - 2);
            testeq(input.stripfront('0')[0], '1');
            testeq(input.stripfront('0')[$-1], '0');
            test(input.stripfront('0')[1 .. $-1].equals("1hi110"));
        });
        tests("Back", {
            test(blank.stripback('0').equals(blank));
            test(input.stripback('1').equals(input));
            test(input.stripback('0').equals("0011hi11"));
            test(input.stripback!isdigit.equals("0011hi"));
            testeq(input.stripback('0').length, input.length - 2);
            testeq(input.stripback('0')[0], '0');
            testeq(input.stripback('0')[$-1], '1');
            test(input.stripback('0')[1 .. $-1].equals("011hi1"));
        });
        tests("Both", {
            test(blank.stripboth('0').equals(blank));
            test(input.stripboth('1').equals(input));
            test(input.stripboth('0').equals("11hi11"));
            test(input.stripboth!isdigit.equals("hi"));
            testeq(input.stripboth('0').length, input.length - 4);
            testeq(input.stripboth('0')[0], '1');
            testeq(input.stripboth('0')[$-1], '1');
            test(input.stripboth('0')[1 .. $-1].equals("1hi1"));
        });
        tests("Bidirectionality", {
            auto range = input.stripfront('0');
            testeq(range.front, '1');
            testeq(range.back, '0');
            testeq(range.nextback, '0');
            testeq(range.nextback, '0');
            testeq(range.nextback, '1');
            testeq(range.nextback, '1');
            testeq(range.nextback, 'i');
            testeq(range.nextback, 'h');
            testeq(range.nextback, '1');
            testeq(range.nextback, '1');
            test(range.empty);
        });
    });
}
