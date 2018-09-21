module mach.text.utf.utf8.decode;

private:

import mach.traits : isRange, isIterable, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.text.utf.encode;
import mach.text.utf.exceptions;

/++ Docs

This module implements decoding of a UTF-8 input string to UTF-32.

+/

public:



// References:
// https://encoding.spec.whatwg.org/#utf-8
// https://github.com/mathiasbynens/utf8.js/blob/master/utf8.js



alias canUTF8Decode = isUTFEncoded!char;

template canUTF8DecodeRange(T){
    enum bool canUTF8DecodeRange = isRange!T && canUTF8Decode!T;
}



/// Given an input iterable containing raw char or byte data, iterate over
/// its UTF-8 encoded code points.
/// Throws a `UTFDecodeException` when the input is malformed.
auto utf8decode(Iter)(auto ref Iter iter) if(canUTF8Decode!Iter){
    auto range = iter.asrange;
    return UTF8DecodeRange!(typeof(range))(range);
}



/// Iterates over unicode code points as indicated by the UTF-8 encoded
/// contents of a range with char or ubyte elements.
struct UTF8DecodeRange(Range) if(canUTF8DecodeRange!Range){
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
        static const inverror = new UTFDecodeInvalidException("UTF-8");
        this.lowindex = this.highindex;
        if(this.source.empty){
            this.isempty = true;
        }else{
            auto continuation(){
                static const eoferror = new UTFDecodeEOFException("UTF-8");
                if(this.source.empty) throw eoferror;
                immutable ch = this.source.front;
                if((ch & 0xc0) != 0x80) throw inverror;
                this.source.popFront();
                this.highindex++;
                return ch & 0x3f;
            }
            immutable char ch0 = this.source.front;
            this.source.popFront();
            this.highindex++;
            if((ch0 & 0x80) == 0){
                this.point = ch0;
            }else if((ch0 & 0xe0) == 0xc0){
                immutable ch1 = continuation();
                this.point = cast(CodePoint)(
                    ((ch0 & 0x1f) << 6) | ch1
                );
                if(this.point < 0x80) throw inverror;
            }else if((ch0 & 0xf0) == 0xe0){
                immutable ch1 = continuation();
                immutable ch2 = continuation();
                this.point = cast(CodePoint)(
                    ((ch0 & 0x0f) << 12) | (ch1 << 6) | ch2
                );
                if(this.point < 0x0800) throw inverror;
                if(this.point >= 0xd800 && this.point <= 0xdfff) throw inverror;
            }else if((ch0 & 0xf8) == 0xf0){
                immutable ch1 = continuation();
                immutable ch2 = continuation();
                immutable ch3 = continuation();
                this.point = cast(CodePoint)(
                    ((ch0 & 0x07) << 18) | (ch1 << 12) | (ch2 << 6) | ch3
                );
                if(this.point < 0x010000 || this.point > 0x10ffff) throw inverror;
            }else{
                throw inverror; // Invalid initial code point byte
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
    static assert(canUTF8Decode!(string));
    static assert(canUTF8Decode!(char[]));
    static assert(canUTF8Decode!(ubyte[]));
    static assert(!canUTF8Decode!(wstring));
    static assert(!canUTF8Decode!(dstring));
    static assert(!canUTF8Decode!(wchar[]));
    static assert(!canUTF8Decode!(dchar[]));
    static assert(!canUTF8Decode!(uint[]));
    static assert(!canUTF8Decode!int);
    static assert(!canUTF8Decode!uint);
    static assert(!canUTF8Decode!void);
}

unittest{
    // Single-byte
    assert("".utf8decode.equals(""d));
    assert("test".utf8decode.equals("test"d));
    assert("hello".utf8decode.equals("hello"d));
    // Two bytes
    assert("א".utf8decode.equals("א"d));
    assert("אֲנָנָס".utf8decode.equals("אֲנָנָס"d));
    // Three bytes
    assert("ツ".utf8decode.equals("ツ"d));
    assert("ザーザー".utf8decode.equals("ザーザー"d));
    assert("!אツ".utf8decode.equals("!אツ"d));
    // Four bytes
    assert("😃".utf8decode.equals("😃"d));
    assert("?😃?".utf8decode.equals("?😃?"d));
    assert("!אツ😃".utf8decode.equals("!אツ😃"d));
}
unittest{
    assert("test".asrange.utf8decode.equals("test"d));
    assert([cast(ubyte) 'h', cast(ubyte) 'i'].utf8decode.equals("hi"d));
}

unittest{
    assertthrows!UTFDecodeException({
        "\xD7".utf8decode.consume;
    });
    assertthrows!UTFDecodeException({
        "\xF0".utf8decode.consume;
    });
    assertthrows!UTFDecodeException({
        "\xF0\x9F".utf8decode.consume;
    });
}

unittest{
    auto str = "!\xD7\x90\xE3\x83\x84\xF0\x9F\x98\x83"; // "!אツ😃"
    auto utf = str.utf8decode;
    assert(utf.pointindex == 0);
    assert(utf.pointlength == 1);
    utf.popFront();
    assert(utf.pointindex == 1);
    assert(utf.pointlength == 2);
    utf.popFront();
    assert(utf.pointindex == 3);
    assert(utf.pointlength == 3);
    utf.popFront();
    assert(utf.pointindex == 6);
    assert(utf.pointlength == 4);
    utf.popFront();
    assert(utf.empty());
    assertthrows({auto x = utf.front;});
    assertthrows({auto x = utf.pointindex;});
    assertthrows({auto x = utf.pointlength;});
    assertthrows({utf.popFront;});
}
