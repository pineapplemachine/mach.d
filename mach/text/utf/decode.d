module mach.text.utf.decode;

private:

import mach.traits : isRange, isIterable, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.text.utf.common : UTFException;

public:



// References:
// https://encoding.spec.whatwg.org/#utf-8
// https://github.com/mathiasbynens/utf8.js/blob/master/utf8.js

// TODO: Correctly handle UTF-16 encoded strings.



/// Exception thrown when decoding a UTF-encoded string fails.
class UTFDecodeException: UTFException{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, next, line, file);
    }
    static void enforceeof(T)(auto ref T cond, size_t line = __LINE__, string file = __FILE__){
        if(!cond) throw new UTFDecodeEOFException(null, line, file);
    }
    static void enforcecont(T)(auto ref T cond, size_t line = __LINE__, string file = __FILE__){
        if(!cond) throw new UTFDecodeInvalidContException(null, line, file);
    }
}

/// Exception thrown when decoding a UTF-encoded string fails
/// as the result of an unexpected end-of-input.
class UTFDecodeEOFException: UTFDecodeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered unexpected EOF while decoding UTF-8 string.", null, line, file);
    }
}

/// Exception thrown when decoding a UTF-encoded string fails
/// as the result of an invalid byte at the beginning of a code point.
class UTFDecodeInvalidInitException: UTFDecodeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered invalid code point initial byte while decoding UTF-8 string.", null, line, file);
    }
}

/// Exception thrown when decoding a UTF-encoded string fails
/// as the result of an invalid byte not at the beginning of a code point.
class UTFDecodeInvalidContException: UTFDecodeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered invalid code point continuation byte while decoding UTF-8 string.", null, line, file);
    }
}



template canUTF8Decode(T){
    enum bool canUTF8Decode = validAsRange!T && is(typeof({
        static assert(ElementType!T.sizeof == 1);
        char ch = T.init.asrange.front;
    }));
}

template canUTF8DecodeRange(T){
    enum bool canUTF8DecodeRange = isRange!T && is(typeof({
        static assert(ElementType!T.sizeof == 1);
        char ch = T.init.front;
    }));
}

template isUTF8Decoded(T){
    enum bool isUTF8Decoded = isIterable!T && is(typeof({
        static assert(ElementType!T.sizeof > 1);
        dchar ch = ElementType!T.init;
    }));
}



/// Given an input iterable containing raw char or byte data, iterate over
/// its UTF-8 encoded code points.
/// Throws a UTFDecodeException when the input is malformed.
auto utf8decode(Iter)(auto ref Iter iter) if(isUTF8Decoded!Iter || canUTF8Decode!Iter){
    static if(isUTF8Decoded!Iter){
        return iter;
    }else{
        auto range = iter.asrange;
        return UTF8DecodeRange!(typeof(range), dchar)(range);
    }
}



/// Iterates over unicode code points as indicated by the UTF-8 encoded
/// contents of a range with char or ubyte elements.
struct UTF8DecodeRange(Range, CodePoint = dchar) if(canUTF8DecodeRange!Range){
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
        this.lowindex = this.highindex;
        if(this.source.empty){
            this.isempty = true;
        }else{
            auto continuation(){
                UTFDecodeException.enforceeof(!this.source.empty);
                auto ch = this.source.front;
                this.source.popFront();
                this.highindex++;
                UTFDecodeException.enforcecont((ch & 0xc0) == 0x80);
                return ch & 0x3f;
            }
            char ch0 = this.source.front;
            this.source.popFront();
            this.highindex++;
            if((ch0 & 0x80) == 0){
                this.point = ch0;
            }else if((ch0 & 0xe0) == 0xc0){
                auto ch1 = continuation();
                this.point = cast(CodePoint)(
                    ((ch0 & 0x1f) << 6) | ch1
                );
                UTFDecodeException.enforcecont(this.point >= 0x80);
            }else if((ch0 & 0xf0) == 0xe0){
                auto ch1 = continuation();
                auto ch2 = continuation();
                this.point = cast(CodePoint)(
                    ((ch0 & 0x0f) << 12) | (ch1 << 6) | ch2
                );
                UTFDecodeException.enforcecont(this.point >= 0x0800);
            }else if((ch0 & 0xf8) == 0xf0){
                auto ch1 = continuation();
                auto ch2 = continuation();
                auto ch3 = continuation();
                this.point = cast(CodePoint)(
                    ((ch0 & 0x07) << 18) | (ch1 << 12) | (ch2 << 6) | ch3
                );
                UTFDecodeException.enforcecont(
                    this.point >= 0x010000 && this.point <= 0x10ffff,
                );
            }else{
                throw new UTFDecodeInvalidInitException();
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.consume : consume;
}
unittest{
    static assert(isUTF8Decoded!(wstring));
    static assert(isUTF8Decoded!(dstring));
    static assert(isUTF8Decoded!(wchar[]));
    static assert(isUTF8Decoded!(dchar[]));
    static assert(isUTF8Decoded!(uint[]));
    static assert(!isUTF8Decoded!(string));
    static assert(!isUTF8Decoded!(char[]));
    static assert(!isUTF8Decoded!(ubyte[]));
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
    tests("UTF decode", {
        tests("Empty string", {
            test("".utf8decode.equals(""d));
        });
        tests("Single-byte code points", {
            test("test".utf8decode.equals("test"d));
            test("hello".utf8decode.equals("hello"d));
        });
        tests("Two-byte code points", {
            test("\xD7\x90".utf8decode.equals("א"d));
            test("\xD7\x90\xD6\xB2\xD7\xA0\xD6\xB8\xD7\xA0\xD6\xB8\xD7\xA1".utf8decode.equals("אֲנָנָס"d));
        });
        tests("Three-byte code points", {
            test("\xE3\x83\x84".utf8decode.equals("ツ"d));
            test("\xE3\x82\xB6\xE3\x83\xBC\xE3\x82\xB6\xE3\x83\xBC".utf8decode.equals("ザーザー"d));
        });
        tests("Four-byte code points", {
            test("\xF0\x9F\x98\x83".utf8decode.equals("😃"d));
        });
        tests("Mixed-size code points", {
            test("!\xD7\x90\xE3\x83\x84\xF0\x9F\x98\x83".utf8decode.equals("!אツ😃"d));
        });
        tests("Range", {
            test("\xE3\x83\x84".asrange.utf8decode.equals("ツ"d));
        });
        tests("Byte array", {
            ubyte[] bytes = [0xe3, 0x83, 0x84];
            test(bytes.utf8decode.equals("ツ"d));
        });
        tests("Invalid inputs", {
            testfail({"\xD7".utf8decode.consume;});
            testfail({"\xF0".utf8decode.consume;});
            testfail({"\xF0\x9F".utf8decode.consume;});
        });
        tests("Already decoded", {
            auto dstr = "test"d;
            testis(dstr.utf8decode, dstr);
            auto wstr = "test"w;
            testis(wstr.utf8decode, wstr);
        });
        tests("Index", {
            auto str = "!\xD7\x90\xE3\x83\x84\xF0\x9F\x98\x83";
            auto utf = str.utf8decode;
            testeq(utf.pointindex, 0);
            testeq(utf.pointlength, 1);
            utf.popFront();
            testeq(utf.pointindex, 1);
            testeq(utf.pointlength, 2);
            utf.popFront();
            testeq(utf.pointindex, 3);
            testeq(utf.pointlength, 3);
            utf.popFront();
            testeq(utf.pointindex, 6);
            testeq(utf.pointlength, 4);
            utf.popFront();
            test(utf.empty());
            testfail({utf.front;});
            testfail({utf.popFront;});
            testfail({utf.pointindex;});
            testfail({utf.pointlength;});
        });
    });
}
