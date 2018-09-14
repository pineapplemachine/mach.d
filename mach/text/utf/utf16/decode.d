module mach.text.utf.utf16.decode;

private:

import mach.traits : isRange, isIterable, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.text.utf.encode;
import mach.text.utf.exceptions;

/++ Docs

This module implements decoding of a UTF-16 input string to UTF-32.

+/

public:



// References:
// https://tools.ietf.org/html/rfc2781



alias canUTF16Decode = isUTFEncoded!wchar;

template canUTF16DecodeRange(T){
    enum bool canUTF16DecodeRange = isRange!T && canUTF16Decode!T;
}



/// Given an input iterable containing raw char or byte data, iterate over
/// its UTF-16 encoded code points.
/// Throws a `UTFDecodeException` when the input is malformed.
/// TODO: Accept char arrays, not just wchars, and detect BE/LE encoding.
auto utf16decode(Iter)(auto ref Iter iter) if(canUTF16Decode!Iter){
    auto range = iter.asrange;
    return UTF16DecodeRange!(typeof(range))(range);
}



/// Given the two wchar members of a surrogate pair, get the encoded dchar.
/// May throw a `UTFDecodeInvalidException` when the input is invalid.
static dchar getutf16surrogate(in wchar first, in wchar second){
    static const error = new UTFDecodeInvalidException("UTF-16");
    if(second < 0xdc00 || second > 0xdfff) throw error;
    return 0x10000 | ((first & 0x3ff) << 10) | (second & 0x3ff);
}



/// Iterates over unicode code points as indicated by the UTF-16 encoded
/// contents of a range with wchar or ushort elements.
struct UTF16DecodeRange(Range) if(canUTF16DecodeRange!Range){
    alias CodePoint = dchar;
    
    /// The string being decoded.
    Range source;
    /// The current code point.
    CodePoint point = void;
    /// Whether the range has been fully exhausted.
    bool isempty = false;
    /// Represents the low index of the most recently outputted code point.
    size_t lowindex = 0;
    /// Represents the high index of the most recently outputted code point.
    size_t highindex = 0;
    
    this(Range source){
        this.source = source;
        this.isempty = this.source.empty;
        if(!this.isempty) this.popFront();
    }
    this(Range source, CodePoint point, bool isempty){
        this.source = source;
        this.point = point;
        this.isempty = isempty;
    }
    
    /// Get the index of the current code point in the string being decoded.
    @property auto pointindex() const in{assert(!this.empty);} body{
        return this.lowindex;
    }
    /// Get the length in elements (typically bytes) of the current code point
    /// in the string being decoded.
    @property auto pointlength() const in{assert(!this.empty);} body{
        return this.highindex - this.lowindex;
    }
    
    @property bool empty() const{
        return this.isempty;
    }
    @property auto front() const in{assert(!this.empty);} body{
        return this.point;
    }
    void popFront() in{assert(!this.empty);} body{
        // Thrown when an invalid continuation byte is encountered
        static const inverror = new UTFDecodeInvalidException("UTF-16");
        static const eoferror = new UTFDecodeEOFException("UTF-16");
        this.lowindex = this.highindex;
        if(this.source.empty){
            this.isempty = true;
        }else{
            immutable wchar ch0 = this.source.front;
            this.source.popFront();
            this.highindex++;
            if(ch0 < 0xd800 || ch0 > 0xdfff){
                this.point = ch0;
            }else if(ch0 <= 0xdbff){ // Surrogate pair
                if(this.source.empty) throw eoferror;
                this.point = getutf16surrogate(ch0, this.source.front);
                this.source.popFront();
                this.highindex++;
            }else{ // Invalid sequence
                throw inverror;
            }
        }
    }
}



private version(unittest){
    import mach.test.assertthrows : assertthrows;
    import mach.range.compare : equals;
    import mach.range.consume : consume;
}

unittest{
    static assert(canUTF16Decode!(wstring));
    static assert(canUTF16Decode!(wchar[]));
    static assert(canUTF16Decode!(ushort[]));
    static assert(!canUTF16Decode!(string));
    static assert(!canUTF16Decode!(dstring));
    static assert(!canUTF16Decode!(char[]));
    static assert(!canUTF16Decode!(dchar[]));
    static assert(!canUTF16Decode!(uint[]));
    static assert(!canUTF16Decode!int);
    static assert(!canUTF16Decode!uint);
    static assert(!canUTF16Decode!void);
}

unittest{
    // Single code units
    assert(""w.utf16decode.equals(""d));
    assert("test"w.utf16decode.equals("test"d));
    assert("hello"w.utf16decode.equals("hello"d));
    assert("א"w.utf16decode.equals("א"d));
    assert("אֲנָנָס"w.utf16decode.equals("אֲנָנָס"d));
    assert("ツ"w.utf16decode.equals("ツ"d));
    assert("ザーザー"w.utf16decode.equals("ザーザー"d));
    assert("!אツ"w.utf16decode.equals("!אツ"d));
    // Surrogate pairs
    assert("😃"w.utf16decode.equals("😃"d));
    assert("?😃?"w.utf16decode.equals("?😃?"d));
    assert("!אツ😃"w.utf16decode.equals("!אツ😃"d));
}
unittest{
    assert("test"w.asrange.utf16decode.equals("test"d));
    assert([cast(ushort) 'h', cast(ushort) 'i'].utf16decode.equals("hi"d));
}

unittest{
    assertthrows!UTFDecodeException({
        // Invalid start unit
        [ushort(0xd800)].utf16decode.consume;
    });
    assertthrows!UTFDecodeException({
        // Invalid continuation unit
        [ushort(0xdbfe), ushort(0xe001)].utf16decode.consume;
    });
}
