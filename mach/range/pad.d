module mach.range.pad;

private:

import std.conv : to;
import mach.traits : isBidirectionalRange, isRandomAccessRange, isSlicingRange;
import mach.traits : isRange, ElementType, hasNumericLength, isIntegral;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canPad(Iter) = (
    validAsRange!Iter
);

enum canPad(Iter, Element) = (
    canPad!(Iter) && is(typeof({
        ElementType!Iter i = Element.init;
    }))
);

enum canPadLength(Iter) = (
    validAsRange!Iter && hasNumericLength!Iter
);

enum canPadLength(Iter, Element) = (
    canPadLength!(Iter) && is(typeof({
        ElementType!Iter i = Element.init;
    }))
);

enum canPadRange(Range) = (
    isRange!Range
);



/// Pad a range on both the left and right sides by a specified amount.
auto pad(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, size_t leftright
) if(canPad!(Iter, Element)){
    return pad(iter, padding, leftright, leftright);
}
/// ditto
auto pad(Iter)(
    auto ref Iter iter, size_t leftright
) if(canPad!(Iter)){
    return pad(iter, ElementType!Iter.init, leftright);
}



/// Pad a range on both the left and right sides by specified amounts.
auto pad(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, size_t left, size_t right
) if(canPad!(Iter, Element)){
    return pad(iter, padding, padding, left, right);
}
/// ditto
auto pad(Iter)(
    auto ref Iter iter, size_t left, size_t right
) if(canPad!(Iter)){
    return pad(iter, ElementType!Iter.init, left, right);
}



/// Pad a range on both the left and right sides by specified amounts.
auto pad(Iter, Element)(
    auto ref Iter iter, auto ref Element paddingleft, auto ref Element paddingright, size_t left, size_t right
) if(canPad!(Iter, Element)){
    auto range = iter.asrange;
    return PadRange!(typeof(range))(
        range, paddingleft, paddingright, left, right
    );
}



/// Pad a range on the left such that it is at least as long as the given length.
auto padfront(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, size_t length
) if(canPadLength!(Iter, Element)){
    auto left = length <= iter.length ? 0 : length - iter.length;
    return padfrontcount(iter, padding, left);
}
/// ditto
auto padfront(Iter)(
    auto ref Iter iter, size_t length
) if(canPadLength!(Iter)){
    return padfront(iter, ElementType!Iter.init, length);
}



/// Pad a range on the right such that it is at least as long as the given length.
auto padback(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, size_t length
) if(canPadLength!(Iter, Element)){
    auto right = length <= iter.length ? 0 : length - iter.length;
    return padbackcount(iter, padding, right);
}
/// ditto
auto padback(Iter)(
    auto ref Iter iter, size_t length
) if(canPadLength!(Iter)){
    return padback(iter, ElementType!Iter.init, length);
}



/// Pad a range on the left by the specified amount.
auto padfrontcount(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, size_t left
) if(canPad!(Iter, Element)){
    auto range = iter.asrange;
    return PadRange!(typeof(range))(range, padding, left, 0);
}
/// ditto
auto padfrontcount(Iter)(
    auto ref Iter iter, size_t left
) if(canPadLength!(Iter)){
    return padfrontcount(iter, ElementType!Iter.init, left);
}



/// Pad a range on the right by the specified amount.
auto padbackcount(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, size_t right
) if(canPad!(Iter, Element)){
    auto range = iter.asrange;
    return PadRange!(typeof(range))(range, padding, 0, right);
}
/// ditto
auto padbackcount(Iter)(
    auto ref Iter iter, size_t right
) if(canPadLength!(Iter)){
    return padbackcount(iter, ElementType!Iter.init, right);
}



struct PadRange(Range) if(canPadRange!(Range)){
    alias Element = ElementType!Range;
    
    mixin MetaRangeMixin!(
        Range, `source`, `Save`
    );
    
    Range source; /// Range to pad
    Element frontpadding; /// Element to use as padding to the left
    Element backpadding; /// Element to use as padding to the right
    size_t frontcount; /// Number of padding elements enumerated so far in front
    size_t backcount; /// Number of padding elements enumerated so far in back
    size_t frontmax; /// Number of padding elements to enumerate in total to the range's left
    size_t backmax; /// Number of padding elements to enumerate in total to the range's right
    
    this(Range source, Element padding, size_t frontmax, size_t backmax){
        this(source, padding, padding, frontmax, backmax);
    }
    this(
        Range source, Element frontpadding, Element backpadding,
        size_t frontmax, size_t backmax,
        size_t frontcount = 0, size_t backcount = 0
    ){
        this.source = source;
        this.frontpadding = frontpadding;
        this.backpadding = backpadding;
        this.frontcount = frontcount;
        this.backcount = backcount;
        this.frontmax = frontmax;
        this.backmax = backmax;
    }
    
    @property bool empty(){
        return (
            this.frontcount >= this.frontmax &&
            this.backcount >= this.backmax &&
            this.source.empty
        );
    }

    @property auto ref front(){
        if(this.frontcount < this.frontmax){
            return this.frontpadding;
        }else if(!this.source.empty){
            return this.source.front;
        }else{
            return this.backpadding;
        }
    }
    void popFront(){
        if(this.frontcount < this.frontmax){
            this.frontcount++;
        }else if(!this.source.empty){
            this.source.popFront();
        }else{
            this.backcount++;
        }
    }
    static if(isBidirectionalRange!Range){
        @property auto ref back(){
            if(this.backcount < this.backmax){
                return this.backpadding;
            }else if(!this.source.empty){
                return this.source.back;
            }else{
                return this.frontpadding;
            }
        }
        void popBack(){
            if(this.backcount < this.backmax){
                this.backcount++;
            }else if(!this.source.empty){
                this.source.popBack();
            }else{
                this.frontcount++;
            }
        }
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return this.frontmax + this.source.length + this.backmax;
        }
        alias opDollar = length;
    
        static if(isRandomAccessRange!Range){
            auto opIndex(size_t index) in{
                assert(index >= 0 && index < this.length);
            }body{
                if(index < this.frontmax){
                    return this.frontpadding;
                }else if(index < this.source.length + this.frontmax){
                    return this.source[index - this.frontmax];
                }else{
                    return this.backpadding;
                }
            }
        }
        
        static if(isSlicingRange!Range){
            auto opSlice(size_t low, size_t high) in{
                assert(low >= 0 && high >= low && high <= this.length);
            }body{
                // Determine front index and padding
                size_t sourcelow, slicepadfront;
                if(low > this.frontmax){
                    sourcelow = low - this.frontmax;
                    slicepadfront = 0;
                }else{
                    sourcelow = 0;
                    slicepadfront = this.frontmax - low;
                }
                // Determine back index and padding
                size_t sourcehigh, slicepadback;
                auto sourcelen = this.source.length;
                auto backstart = this.frontmax + sourcelen;
                if(high > backstart){
                    sourcehigh = sourcelen;
                    slicepadback = high - backstart;
                }else{
                    if(sourcelen > backstart - high){
                        sourcehigh = sourcelen - (backstart - high);
                    }else{
                        sourcehigh = 0;
                    }
                    slicepadback = 0;
                }
                // Do the slice
                return typeof(this)(
                    this.source[sourcelow .. sourcehigh],
                    this.frontpadding, this.backpadding,
                    cast(size_t) slicepadfront,
                    cast(size_t) slicepadback
                );
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Pad", {
        auto input = "hi";
        tests("Front", {
            auto range = input.padfront('_', 4);
            testeq(range.length, 4);
            test!equals(range, "__hi");
            tests("Random access", {
                testeq(range[0], '_');
                testeq(range[1], '_');
                testeq(range[2], 'h');
                testeq(range[$-1], 'i');
            });
        });
        tests("Back", {
            auto range = input.padback('_', 4);
            testeq(range.length, 4);
            test!equals(range, "hi__");
            tests("Random access", {
                testeq(range[0], 'h');
                testeq(range[1], 'i');
                testeq(range[2], '_');
                testeq(range[$-1], '_');
            });
        });
        tests("Both", {
            auto range = input.pad('F', 'B', 2, 3);
            testeq(range.length, 7);
            test!equals(range, "FFhiBBB");
            tests("Random access", {
                testeq(range[0], 'F');
                testeq(range[1], 'F');
                testeq(range[2], 'h');
                testeq(range[3], 'i');
                testeq(range[4], 'B');
                testeq(range[5], 'B');
                testeq(range[$-1], 'B');
            });
            tests("Slicing", {
                test(range[0 .. $].equals(range));
                test(range[0 .. 2].equals("FF"));
                test(range[0 .. 4].equals("FFhi"));
                test(range[1 .. 3].equals("Fh"));
                test(range[1 .. 5].equals("FhiB"));
                test(range[2 .. 4].equals("hi"));
                test(range[2 .. 5].equals("hiB"));
                test(range[2 .. $].equals("hiBBB"));
            });
            tests("Saving", {
                auto copy = range.save;
                copy.popFront();
                copy.popFront();
                testeq(range.front, 'F');
                testeq(copy.front, 'h');
            });
        });
    });
}
