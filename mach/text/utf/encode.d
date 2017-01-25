module mach.text.utf.encode;

private:

import mach.traits : isIterable, ElementType, isRange;
import mach.traits : isSavingRange, hasEmptyEnum;
import mach.range.asrange : asrange, validAsRange;

/++ Docs

This module implements templates and types shared by UTF-8 and UTF-16
encoding implementations.

+/

public:



/// Determine whether some input is an iterable which can be UTF encoded.
template canUTFEncode(T){
    enum bool canUTFEncode = validAsRange!T && is(typeof({
        static assert(ElementType!T.sizeof == 4);
        dchar ch = T.init.asrange.front;
    }));
}

/// Determine whether some input is a range which can be UTF encoded.
template canUTFEncodeRange(T){
    enum bool canUTFEncodeRange = isRange!T && canUTFEncode!T;
}



template isUTFEncoded(Char){
    template isUTFEncoded(T){
        enum bool isUTFEncoded = isIterable!T && is(typeof({
            static assert(ElementType!T.sizeof == Char.sizeof);
            Char ch = ElementType!T.init;
        }));
    }
}



/// A range for enumerating the encoded code units of some inputted
/// UTF-32 string.
/// `encodechar` must be a function accepting a single `dchar` argument
/// and returning an encoded code point type such as `UTF8EncodePoint`
/// or `UTF16EncodePoint`.
struct UTFEncodeRange(Range, alias encodechar) if(canUTFEncodeRange!Range){
    alias CodePoint = typeof(encodechar(dchar.init));
    
    Range source;
    CodePoint encoded = void;
    size_t encodedindex = 0;
    
    static if(hasEmptyEnum!Range){
        enum bool empty = Range.empty;
    }else{
        bool isempty = false;
        @property bool empty() const{
            return this.isempty;
        }
    }
    
    this(Range source){
        this.source = source;
        this.isempty = source.empty;
        if(!this.isempty) this.popFront();
    }
    
    static if(hasEmptyEnum!Range) this(
        Range source, CodePoint encoded, size_t encodedindex
    ){
        this.source = source;
        this.encoded = encoded;
        this.encodedindex = encodedindex;
    }
    static if(!hasEmptyEnum!Range) this(
        Range source, CodePoint encoded, size_t encodedindex, bool isempty
    ){
        this.source = source;
        this.encoded = encoded;
        this.encodedindex = encodedindex;
        this.isempty = isempty;
    }
    
    @property auto front() const in{
        assert(!this.empty);
        assert(this.encodedindex < this.encoded.length);
    }body{
        return this.encoded[this.encodedindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.encodedindex++;
        if(this.encodedindex >= this.encoded.length){
            static if(!hasEmptyEnum!Range){
                if(this.source.empty){
                    this.isempty = true;
                    return;
                }
            }
            this.encoded = encodechar(this.source.front);
            this.encodedindex = 0;
            // TODO: Pop after fully consuming code point, not at the start.
            // should be possible to get rid of `isempty` this way.
            this.source.popFront();
        }
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            static if(hasEmptyEnum!Range){
                return typeof(this)(
                    this.source.save, this.encoded, this.encodedindex
                );
            }else{
                return typeof(this)(
                    this.source.save, this.encoded, this.encodedindex, this.isempty
                );
            }
        }
    }
}



unittest{
    static assert(canUTFEncode!(dstring));
    static assert(canUTFEncode!(dchar[]));
    static assert(canUTFEncode!(uint[]));
    static assert(!canUTFEncode!(string));
    static assert(!canUTFEncode!(char[]));
    static assert(!canUTFEncode!(ubyte[]));
    static assert(!canUTFEncode!(wstring));
    static assert(!canUTFEncode!(wchar[]));
    static assert(!canUTFEncode!(ushort[]));
    static assert(!canUTFEncode!int);
    static assert(!canUTFEncode!uint);
    static assert(!canUTFEncode!void);
}
