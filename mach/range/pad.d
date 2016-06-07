module mach.range.pad;

private:

import std.conv : to;
import std.traits : isIntegral, isImplicitlyConvertible;
import mach.traits : isBidirectionalRange, isRandomAccessRange, isSlicingRange;
import mach.traits : isRange, ElementType, hasNumericLength;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canPad(Iter, Count) = (
    validAsRange!Iter && validPadCount!Count
);

enum canPad(Iter, Element, Count) = (
    canPad!(Iter, Count) && isImplicitlyConvertible!(Element, ElementType!Iter)
);

enum canPadLength(Iter, Count) = (
    validAsRange!Iter && hasNumericLength!Iter && validPadCount!Count
);

enum canPadLength(Iter, Element, Count) = (
    canPadLength!(Iter, Count) && isImplicitlyConvertible!(Element, ElementType!Iter)
);

enum canPadRange(Range, Count) = (
    isRange!Range && validPadCount!Count
);

alias validPadCount = isIntegral;



/// Pad a range on both the left and right sides by a specified amount.
auto pad(Iter, Element, Count = size_t)(
    Iter iter, Element padding, Count leftright
) if(canPad!(Iter, Element, Count)){
    return pad(iter, padding, leftright, leftright);
}
/// ditto
auto pad(Iter, Count = size_t)(
    Iter iter, Count leftright
) if(canPad!(Iter, Count)){
    return pad(iter, ElementType!Iter.init, leftright);
}

/// Pad a range on both the left and right sides by specified amounts.
auto pad(Iter, Element, Count = size_t)(
    Iter iter, Element padding, Count left, Count right
) if(canPad!(Iter, Element, Count)){
    return pad(iter, padding, padding, left, right);
}
/// ditto
auto pad(Iter, Count = size_t)(
    Iter iter, Count left, Count right
) if(canPad!(Iter, Count)){
    return pad(iter, ElementType!Iter.init, left, right);
}

/// Pad a range on both the left and right sides by specified amounts.
auto pad(Iter, Element, Count = size_t)(
    Iter iter, Element paddingleft, Element paddingright, Count left, Count right
) if(canPad!(Iter, Element, Count)){
    auto range = iter.asrange;
    return PadRange!(typeof(range), Count)(
        range, paddingleft, paddingright, left, right
    );
}

/// Pad a range on the left such that it is at least as long as the given length.
auto padleft(Iter, Element, Count = size_t)(
    Iter iter, Element padding, Count length
) if(canPadLength!(Iter, Element, Count)){
    auto left = length <= iter.length ? 0 : length - iter.length;
    return padleftcount(iter, padding, left);
}
/// ditto
auto padleft(Iter, Count = size_t)(
    Iter iter, Count length
) if(canPadLength!(Iter, Count)){
    return padleft(iter, ElementType!Iter.init, length);
}

/// Pad a range on the right such that it is at least as long as the given length.
auto padright(Iter, Element, Count = size_t)(
    Iter iter, Element padding, Count length
) if(canPadLength!(Iter, Element, Count)){
    auto right = length <= iter.length ? 0 : length - iter.length;
    return padrightcount(iter, padding, right);
}
/// ditto
auto padright(Iter, Count = size_t)(
    Iter iter, Count length
) if(canPadLength!(Iter, Count)){
    return padright(iter, ElementType!Iter.init, length);
}


/// Pad a range on the left by the specified amount.
auto padleftcount(Iter, Element, Count = size_t)(
    Iter iter, Element padding, Count left
) if(canPad!(Iter, Element, Count)){
    auto range = iter.asrange;
    return PadRange!(typeof(range), Count)(range, padding, left, Count.init);
}
/// ditto
auto padleftcount(Iter, Count = size_t)(
    Iter iter, Count left
) if(canPadLength!(Iter, Count)){
    return padleftcount(iter, ElementType!Iter.init, left);
}


/// Pad a range on the right by the specified amount.
auto padrightcount(Iter, Element, Count = size_t)(
    Iter iter, Element padding, Count right
) if(canPad!(Iter, Element, Count)){
    auto range = iter.asrange;
    return PadRange!(typeof(range), Count)(range, padding, Count.init, right);
}
/// ditto
auto padrightcount(Iter, Count = size_t)(
    Iter iter, Count right
) if(canPadLength!(Iter, Count)){
    return padrightcount(iter, ElementType!Iter.init, right);
}



struct PadRange(Range, Count = size_t) if(canPadRange!(Range, Count)){
    alias Element = ElementType!Range;
    
    mixin MetaRangeMixin!(
        Range, `source`, `Save`
    );
    
    Range source; /// Range to pad
    Element frontpadding; /// Element to use as padding to the left
    Element backpadding; /// Element to use as padding to the right
    Count frontcount; /// Number of padding elements enumerated so far in front
    Count backcount; /// Number of padding elements enumerated so far in back
    Count frontmax; /// Number of padding elements to enumerate in total to the range's left
    Count backmax; /// Number of padding elements to enumerate in total to the range's right
    
    this(Range source, Element padding, Count frontmax, Count backmax){
        this(source, padding, padding, frontmax, backmax);
    }
    this(
        Range source, Element frontpadding, Element backpadding,
        Count frontmax, Count backmax,
        Count frontcount = Count.init, Count backcount = Count.init
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
                    to!Count(slicepadfront), to!Count(slicepadback)
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
    tests("Pad", {
        auto input = "hi";
        tests("Left", {
            auto range = input.padleft('_', 4);
            testeq("Length", range.length, 4);
            test("Iteration", range.equals("__hi"));
            tests("Random access", {
                testeq(range[0], '_');
                testeq(range[1], '_');
                testeq(range[2], 'h');
                testeq(range[$-1], 'i');
            });
        });
        tests("Right", {
            auto range = input.padright('_', 4);
            testeq("Length", range.length, 4);
            test("Iteration", range.equals("hi__"));
            tests("Random access", {
                testeq(range[0], 'h');
                testeq(range[1], 'i');
                testeq(range[2], '_');
                testeq(range[$-1], '_');
            });
        });
        tests("Left and right", {
            auto range = input.pad('F', 'B', 2, 3);
            testeq("Length", range.length, 7);
            test("Iteration", range.equals("FFhiBBB"));
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
