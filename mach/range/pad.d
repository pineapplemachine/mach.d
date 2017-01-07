module mach.range.pad;

private:

import mach.traits : isBidirectionalRange, isRandomAccessRange;
import mach.traits : isRange, isSlicingRange, isSavingRange;
import mach.traits : hasNumericLength, hasNumericRemaining, ElementType;
import mach.range.asrange : asrange, validAsRange;

/++ Docs

This module implements the `pad` function and its derivatives, which produce
a range enumerating the contents of an input iterable, with additional elements
added to its front or back.

The `padfront` and `padback` functions can be used to perform the common
string manipulation of adding elements to the front or back such that the
total length of the output is at most or at minimum a given length.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    assert("123".padfront('0', 6).equals("000123"));
    assert("345".padback('0', 6).equals("345000"));
}

/++ Docs

Since these functions generate lazy sequences, functions like string
concatenation will require using a function like `asarray` in order to
create an in-memory array from the padded output.

+/

unittest{ /// Example
    import mach.range.asarray : asarray;
    auto text = "hello" ~ "world".padfront('_', 7).asarray;
    assert(text == "hello__world");
}

/++ Docs

The `pad` function provides several overloads for producing an output
which enumerates the input with a given number of elements appended or
prepended to the input.

+/

unittest{ /// Example
    // Pad with two underscores at the front and the back.
    assert("hi".pad('_', 2).equals("__hi__"));
    // Pad with one underscore at the front and three at the back.
    assert("yo".pad('_', 1, 3).equals("_yo___"));
    // Pad with two underscores at the front and three bangs at the back.
    assert("bro".pad('_', 2, '!', 3).equals("__bro!!!"));
}

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
    validAsRange!Iter && (hasNumericRemaining!Iter || hasNumericLength!Iter)
);

enum canPadLength(Iter, Element) = (
    canPadLength!(Iter) && is(typeof({
        ElementType!Iter i = Element.init;
    }))
);

enum canPadRange(Range) = (
    isRange!Range
);



/// Pad both the front and back of an input iterable by the specified amount,
/// using the same element for the front and back padding.
auto pad(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, in size_t amount
) if(canPad!(Iter, Element)){
    return pad(iter, padding, amount, amount);
}

/// ditto
auto pad(Iter)(
    auto ref Iter iter, in size_t amount
) if(canPad!(Iter)){
    return pad(iter, ElementType!Iter.init, amount);
}



/// Pad the front and back of an input iterable by the specified amounts,
/// using the same element for the front and back padding.
auto pad(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, in size_t front, in size_t back
) if(canPad!(Iter, Element)){
    return pad(iter, padding, front, padding, back);
}

/// ditto
auto pad(Iter)(
    auto ref Iter iter, size_t front, size_t back
) if(canPad!(Iter)){
    return pad(iter, ElementType!Iter.init, front, back);
}



/// Pad the front and back of an input iterable by the specified amounts,
/// using differing elements for the front and back padding.
auto pad(Iter, Element)(
    auto ref Iter iter,
    auto ref Element paddingfront, in size_t front,
    auto ref Element paddingback, in size_t back
) if(canPad!(Iter, Element)){
    auto range = iter.asrange;
    return PadRange!(typeof(range))(
        range, paddingfront, paddingback, front, back
    );
}



/// Pad the front of the input such that it is at least as long as the given length.
auto padfront(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, in size_t length
) if(canPadLength!(Iter, Element)){
    static if(hasNumericRemaining!Iter){
        auto front = length <= iter.remaining ? 0 : length - iter.remaining;
    }else{
        auto front = length <= iter.length ? 0 : length - iter.length;
    }
    return padfrontcount(iter, padding, front);
}

/// ditto
auto padfront(Iter)(
    auto ref Iter iter, in size_t length
) if(canPadLength!(Iter)){
    return padfront(iter, ElementType!Iter.init, length);
}



/// Pad the back of the input such that it is at least as long as the given length.
auto padback(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, in size_t length
) if(canPadLength!(Iter, Element)){
    static if(hasNumericRemaining!Iter){
        auto back = length <= iter.remaining ? 0 : length - iter.remaining;
    }else{
        auto back = length <= iter.length ? 0 : length - iter.length;
    }
    return padbackcount(iter, padding, back);
}

/// ditto
auto padback(Iter)(
    auto ref Iter iter, in size_t length
) if(canPadLength!(Iter)){
    return padback(iter, ElementType!Iter.init, length);
}



/// Pad the front of the input with a specified number of occurrences of the
/// provided element.
auto padfrontcount(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, in size_t front
) if(canPad!(Iter, Element)){
    auto range = iter.asrange;
    return PadRange!(typeof(range))(range, padding, front, 0);
}

/// ditto
auto padfrontcount(Iter)(
    auto ref Iter iter, in size_t front
) if(canPadLength!(Iter)){
    return padfrontcount(iter, ElementType!Iter.init, front);
}



/// Pad the back of the input with a specified number of occurrences of the
/// provided element.
auto padbackcount(Iter, Element)(
    auto ref Iter iter, auto ref Element padding, in size_t back
) if(canPad!(Iter, Element)){
    auto range = iter.asrange;
    return PadRange!(typeof(range))(range, padding, 0, back);
}

/// ditto
auto padbackcount(Iter)(
    auto ref Iter iter, in size_t back
) if(canPadLength!(Iter)){
    return padbackcount(iter, ElementType!Iter.init, back);
}



struct PadRange(Range) if(canPadRange!(Range)){
    alias Element = ElementType!Range;
    
    /// Range to pad.
    Range source;
    /// Element to use as padding at the front.
    Element frontpadding;
    /// Element to use as padding at the back.
    Element backpadding;
    /// Number of padding elements enumerated so far in front.
    size_t frontcount;
    /// Number of padding elements enumerated so far in back.
    size_t backcount;
    /// Number of padding elements to enumerate in total at the front.
    size_t frontmax;
    /// Number of padding elements to enumerate in total at the back.
    size_t backmax;
    
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

    @property auto front(){
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
        @property auto back(){
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
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(
                this.source.save, this.frontpadding, this.backpadding,
                this.frontmax, this.backmax, this.frontcount, this.backcount
            );
        }
    }
    
    static if(hasNumericRemaining!Range){
        @property auto remaining(){
            return (
                (this.frontmax - this.frontcount) +
                (this.backmax - this.backcount) +
                cast(size_t) this.source.remaining
            );
        }
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return (
                this.frontmax + this.backmax +
                cast(size_t) this.source.length
            );
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
    import mach.range.asrange : asrange;
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
            auto range = input.pad('F', 2, 'B', 3);
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
        tests("Pad partially-consumed range", {
            // TODO: I'm not really sure whether this should be desireable
            // behavior. The notion of left-padding an already partially-
            // consumed range doesn't make much sense, does it?
            // Attempting to do so should probably produce an error but, at
            // least for now, I'm just going to test for consistent behavior.
            // Another idea: Maybe any partially-consumed input produces a
            // pad range where all its front padding elements have already
            // been consumed?
            auto input = "abcde".asrange;
            input.popFront();
            auto padded = input.pad('_', 2, 2);
            testeq(padded.length, input.length + 4);
            testeq(padded.remaining, input.remaining + 4);
            test!equals(padded, "__bcde__");
        });
    });
}
