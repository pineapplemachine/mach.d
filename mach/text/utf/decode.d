module mach.text.utf.decode;

private:

import mach.traits : isRange, isIterable, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.text.utf.common : UTFException;

public:



// References:
// https://encoding.spec.whatwg.org/#utf-8
// https://github.com/mathiasbynens/utf8.js/blob/master/utf8.js



class UTFDecodeException: UTFException{
    static enum Reason{
        UnexpectedEOF,
        InvalidInitial,
        InvalidContinuation,
    }
    
    Reason reason;
    
    this(Reason reason, size_t line = __LINE__, string file = __FILE__){
        super("Failed to decode UTF-8 string: " ~ reasonname(reason), null, line, file);
        this.reason = reason;
    }
    
    static string reasonname(in Reason reason){
        final switch(reason){
            case Reason.UnexpectedEOF: return "Unexpected end of input.";
            case Reason.InvalidInitial: return "Invalid initial byte.";
            case Reason.InvalidContinuation: return "Invalid continuation byte.";
        }
    }
    
    static void enforce(T)(auto ref T cond, Reason reason){
        if(!cond) throw new typeof(this)(reason);
    }
    static void enforceeof(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.UnexpectedEOF);
    }
    static void enforcecont(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.InvalidContinuation);
    }
}



template canUTFDecode(T){
    enum bool canUTFDecode = validAsRange!T && is(typeof({
        static assert(ElementType!T.sizeof == 1);
        char ch = T.init.asrange.front;
    }));
}

template canUTFDecodeRange(T){
    enum bool canUTFDecodeRange = isRange!T && is(typeof({
        static assert(ElementType!T.sizeof == 1);
        char ch = T.init.front;
    }));
}

template isUTFDecoded(T){
    enum bool isUTFDecoded = isIterable!T && is(typeof({
        static assert(ElementType!T.sizeof > 1);
        dchar ch = ElementType!T.init;
    }));
}



/// Given an input iterable containing raw char or byte data, iterate over
/// its UTF-8 encoded code points.
/// Throws a UTFDecodeException when the input is malformed.
auto utf8decode(Iter)(auto ref Iter iter) if(isUTFDecoded!Iter || canUTFDecode!Iter){
    static if(isUTFDecoded!Iter){
        return iter;
    }else{
        auto range = iter.asrange;
        return UTFDecodeRange!(typeof(range), dchar)(range);
    }
}



/// Iterates over UTF code points as indicated by the contents of a range with
/// char or ubyte elements.
struct UTFDecodeRange(Range, CodePoint = dchar) if(canUTFDecodeRange!Range){
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
                throw new UTFDecodeException(
                    UTFDecodeException.Reason.InvalidInitial
                );
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
    static assert(isUTFDecoded!(wstring));
    static assert(isUTFDecoded!(dstring));
    static assert(isUTFDecoded!(wchar[]));
    static assert(isUTFDecoded!(dchar[]));
    static assert(isUTFDecoded!(uint[]));
    static assert(!isUTFDecoded!(string));
    static assert(!isUTFDecoded!(char[]));
    static assert(!isUTFDecoded!(ubyte[]));
}
unittest{
    static assert(canUTFDecode!(string));
    static assert(canUTFDecode!(char[]));
    static assert(canUTFDecode!(ubyte[]));
    static assert(!canUTFDecode!(wstring));
    static assert(!canUTFDecode!(dstring));
    static assert(!canUTFDecode!(wchar[]));
    static assert(!canUTFDecode!(dchar[]));
    static assert(!canUTFDecode!(uint[]));
    static assert(!canUTFDecode!int);
    static assert(!canUTFDecode!uint);
    static assert(!canUTFDecode!void);
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
