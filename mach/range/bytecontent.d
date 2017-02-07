module mach.range.bytecontent;

private:

import mach.traits : isRange, isBidirectionalRange, isSavingRange;
import mach.traits : isRandomAccessRange, isSlicingRange, hasEmptyEnum;
import mach.traits : hasNumericLength, hasNumericRemaining;
import mach.traits : Unqual, ElementType;
import mach.math : divceil;
import mach.range.asrange : asrange, validAsRange;
import mach.range.map : map;

/++ Docs

The `bytecontent` function can be used to produce a range which enumerates
the bytes comprising the elements of some input iterable.
The function accepts an optional template argument of the type `Endian` —
implemented in `mach.sys.endian` — to indicate byte order of the produced
range.
If the byte order template argument isn't provided, then a little-endian
range is produced by default.

The range produced by `bytecontent` has elements of type `ubyte`.
It is bidirectional when the input is bidirectional and has a `remaining`
property.
It supports `length` and `remaining` when the input supports them, as well
as random access, slicing, and saving.

If the input to `bytecontent` is an iterable with elements that are already
ubytes, it will simply return its input.
If the input is an iterable with elements that are not ubytes, but are the
same size as ubytes, it will return a range which maps the input's elements
to values casted to `ubyte`.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    ushort[] shorts = [0x1234, 0x5678];
    auto range = shorts.bytecontent!(Endian.LittleEndian);
    assert(range.equals([0x34, 0x12, 0x78, 0x56]));
}

/++ Docs

The module also provides `bytecontentle` and `bytecontentbe` functions
for convenience which are equivalent to `bytecontent!(Endian.LittleEndian)`
and `bytecontent!(Endian.BigEndian)`, respectively.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    ushort[] shorts = [0xabcd, 0x0123];
    assert(shorts.bytecontentbe.equals([0xab, 0xcd, 0x01, 0x23])); // Big endian
    assert(shorts.bytecontentle.equals([0xcd, 0xab, 0x23, 0x01])); // Little endian
}

public:



import mach.sys.endian : Endian;



/// Get a range for enumerating the bytes comprising the elements of some
/// iterable in big-endian or little-endian order.
/// When no byte order is provided, defaults to little endian.
auto bytecontent(Endian endian = Endian.LittleEndian, T)(auto ref T iter) if(validAsRange!T){
    alias Element = ElementType!T;
    static if(is(Unqual!Element == ubyte)){
        return iter;
    }else static if(Element.sizeof == ubyte.sizeof){
        return iter.map!(e => cast(immutable(ubyte)) e);
    }else{
        auto range = iter.asrange;
        return ByteContentRange!(endian, typeof(range))(range);
    }
}

/// Get a little-endian byte content range.
auto bytecontentle(T)(auto ref T iter) if(validAsRange!T){
    return bytecontent!(Endian.LittleEndian)(iter);
}

/// Get a big-endian byte content range.
auto bytecontentbe(T)(auto ref T iter) if(validAsRange!T){
    return bytecontent!(Endian.BigEndian)(iter);
}



/// A range for enumerating the bytes making up the elements of a source
/// range in big-endian or little-endian order.
struct ByteContentRange(Endian endian, Source) if(isRange!Source){
    alias SourceElementType = typeof(this.source.front);
    enum SourceElementSize = SourceElementType.sizeof;
    enum isBidirectional = isBidirectionalRange!Source && hasNumericRemaining!Source;
    
    Source source;
    size_t frontindex = 0;
    static if(isBidirectional) size_t backindex = SourceElementSize;
    
    static if(hasEmptyEnum!Source){
        enum empty = Source.empty;
    }else{
        @property bool empty(){
            static if(isBidirectional){
                return this.source.empty || (
                    this.source.remaining == 1 && this.frontindex >= this.backindex
                );
            }else{
                return this.source.empty;
            }
        }
    }
    
    private static @trusted ubyte getbyte(in SourceElementType element, in size_t index){
        assert(index >= 0 && index < SourceElementSize);
        static if(endian is Endian.Platform){
            return *((cast(ubyte*) &element) + index);
        }else{
            return *((cast(ubyte*) &element) + (SourceElementSize - 1 - index));
        }
    }
    
    @property auto front() in{assert(!this.empty);} body{
        immutable element = this.source.front;
        return this.getbyte(element, frontindex);
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
        if(this.frontindex >= SourceElementSize){
            this.frontindex = 0;
            this.source.popFront();
        }
    }
    
    static if(isBidirectional){
        @property auto back() in{assert(!this.empty);} body{
            immutable element = this.source.back;
            return this.getbyte(element, this.backindex - 1);
        }
        void popBack() in{assert(!this.empty);} body{
            this.backindex = this.backindex - 1;
            if(this.backindex == 0){
                this.backindex = SourceElementSize;
                this.source.popBack();
            }
        }
    }
    
    static if(hasNumericLength!Source){
        @property auto length(){
            return this.source.length * SourceElementSize;
        }
        alias opDollar = length;
    }
    static if(hasNumericRemaining!Source){
        @property auto remaining(){
            static if(isBidirectional){
                return (
                    this.source.remaining * SourceElementSize -
                    this.frontindex - SourceElementSize + this.backindex
                );
            }else{
                return (
                    this.source.remaining * SourceElementSize - this.frontindex
                );
            }
        }
    }
    
    static if(isRandomAccessRange!Source){
        auto opIndex(in size_t index){
            immutable element = this.source[index / SourceElementSize];
            return this.getbyte(element, index % SourceElementSize);
        }
    }
    
    static if(isSlicingRange!Source){
        auto opSlice(in size_t low, in size_t high){
            immutable sourcelow = low / SourceElementSize;
            immutable sourcehigh = divceil(high, SourceElementSize);
            static if(isBidirectional){
                return typeof(this)(
                    this.source[sourcelow .. sourcehigh],
                    low % SourceElementSize,
                    SourceElementSize - (high % SourceElementSize)
                );
            }else{
                return typeof(this)(
                    this.source[sourcelow .. sourcehigh],
                    low % SourceElementSize
                );
            }
        }
    }
    
    static if(isSavingRange!Source){
        @property typeof(this) save(){
            static if(isBidirectional){
                return typeof(this)(this.source.save, this.frontindex, this.backindex);
            }else{
                return typeof(this)(this.source.save, this.frontindex);
            }
        }
    }
}



private version(unittest){
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Byte content", {
        uint[] ints = [0x01234567, 0x89abcdef, 0x11223344, 0x55667788];
        ubyte* bytes = cast(ubyte*) ints.ptr;
        tests("Platform", {
            auto range = ints.bytecontent!(Endian.Platform);
            testeq(range.length, ints.length * 4);
            testeq(range.remaining, range.length);
            testf(range.empty);
            for(size_t i = 0; i < range.length; i++){
                testeq(range.front, bytes[i]);
                testeq(range[i], bytes[i]);
                range.popFront();
                testeq(range.remaining, range.length - i - 1);
            }
            test(range.empty);
        });
        tests("Big endian", {
            auto range = ints.bytecontent!(Endian.BigEndian);
            // Content
            testeq(range.length, ints.length * 4);
            testeq(range.remaining, range.length);
            test!equals(range, [
                0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
                0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
            ]);
            // Random access
            testeq(range[0], 0x01);
            testeq(range[$-1], 0x88);
            testfail({range[$];});
            // Slicing
            test(range[0 .. 0].empty);
            test(range[$ .. $].empty);
            test!equals(range[0 .. $], range);
            test!equals(range[0 .. 4], [0x01, 0x23, 0x45, 0x67]);
            test!equals(range[2 .. 6], [0x45, 0x67, 0x89, 0xab]);
        });
        tests("Little endian", {
            auto range = ints.bytecontent!(Endian.LittleEndian);
            // Content
            testeq(range.length, ints.length * 4);
            testeq(range.remaining, range.length);
            test!equals(range, [
                0x67, 0x45, 0x23, 0x01, 0xef, 0xcd, 0xab, 0x89,
                0x44, 0x33, 0x22, 0x11, 0x88, 0x77, 0x66, 0x55,
            ]);
            // Random access
            testeq(range[0], 0x67);
            testeq(range[$-1], 0x55);
            testfail({range[$];});
            // Slicing
            test(range[0 .. 0].empty);
            test(range[$ .. $].empty);
            test!equals(range[0 .. $], range);
            test!equals(range[0 .. 4], [0x67, 0x45, 0x23, 0x01]);
            test!equals(range[2 .. 6], [0x23, 0x01, 0xef, 0xcd]);
        });
        tests("Reverse-order", {
            // Little endian
            auto lil = ints.bytecontent!(Endian.LittleEndian);
            testeq(lil.back, 0x55);
            lil.popBack();
            testeq(lil.back, 0x66);
            while(!lil.empty) lil.popBack();
            testeq(lil.remaining, 0);
            // Big endian
            auto big = ints.bytecontent!(Endian.BigEndian);
            testeq(big.back, 0x88);
            big.popBack();
            testeq(big.back, 0x77);
            while(!big.empty) big.popBack();
            testeq(big.remaining, 0);
        });
        tests("Bidirectionality", {
            uint[] array = [0x11223344, 0x55667788];
            auto range = array.bytecontent!(Endian.LittleEndian);
            testeq(range.front, 0x44);
            testeq(range.back, 0x55);
            testeq(range.remaining, 8);
            range.popFront();
            testeq(range.front, 0x33);
            testeq(range.back, 0x55);
            testeq(range.remaining, 7);
            range.popFront();
            testeq(range.front, 0x22);
            testeq(range.back, 0x55);
            testeq(range.remaining, 6);
            range.popBack();
            testeq(range.front, 0x22);
            testeq(range.back, 0x66);
            testeq(range.remaining, 5);
            range.popBack();
            testeq(range.front, 0x22);
            testeq(range.back, 0x77);
            testeq(range.remaining, 4);
            range.popFront();
            testeq(range.front, 0x11);
            testeq(range.back, 0x77);
            testeq(range.remaining, 3);
            range.popFront();
            testeq(range.front, 0x88);
            testeq(range.back, 0x77);
            testeq(range.remaining, 2);
            range.popFront();
            testeq(range.front, 0x77);
            testeq(range.back, 0x77);
            testeq(range.remaining, 1);
            range.popBack();
            testeq(range.remaining, 0);
            test(range.empty);
        });
        tests("Saving", {
            ushort[] array = [0x0123, 0x4567];
            auto range = array.bytecontent;
            auto saved = range.save;
            range.popFront();
            testeq(range.front, 0x01);
            testeq(saved.front, 0x23);
        });
        tests("Byte input", {
            ubyte[] array = [1, 2, 3];
            test!equals(array.bytecontentbe, array);
            test!equals(array.bytecontentle, array);
        });
        tests("Byte-like input", {
            char[] array = ['a', 'b', 'c'];
            test!equals(array.bytecontentbe, array);
            test!equals(array.bytecontentle, array);
            ubyte front = array.bytecontent.front;
            testeq(front, 'a');
        });
    });
}
