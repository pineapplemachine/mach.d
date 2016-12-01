module mach.text.utf.encode;

private:

import mach.traits : isIterable, ElementType, isRange;
import mach.range.asrange : asrange, validAsRange;
import mach.text.utf.common : UTFException;

public:



// References:
// https://encoding.spec.whatwg.org/#utf-8
// https://github.com/mathiasbynens/utf8.js/blob/master/utf8.js



class UTFEncodeException: UTFException{
    dchar point;
    this(dchar point = 0, size_t line = __LINE__, string file = __FILE__){
        super("Encountered invalid code point when attempting to encode UTF string.", null, line, file);
        this.point = point;
    }
}



template canUTFEncode(T){
    enum bool canUTFEncode = validAsRange!T && is(typeof({
        static assert(ElementType!T.sizeof > 1);
        dchar ch = T.init.asrange.front;
    }));
}

template canUTFEncodeRange(T){
    enum bool canUTFEncodeRange = isRange!T && is(typeof({
        static assert(ElementType!T.sizeof > 1);
        dchar ch = T.init.front;
    }));
}

template isUTFEncoded(T){
    enum bool isUTFEncoded = isIterable!T && is(typeof({
        static assert(ElementType!T.sizeof == 1);
        char ch = ElementType!T.init;
    }));
}



auto utf8encode(Iter)(auto ref Iter iter) if(isUTFEncoded!Iter || canUTFEncode!Iter){
    static if(isUTFEncoded!Iter){
        return iter;
    }else{
        auto range = iter.asrange;
        return UTFEncodeRange!(typeof(range), char)(range);
    }
}



/// Type returned when calling utf8encode with a dchar argument.
/// Contains up to four bytes, the count determined by an object's length
/// property, representing an encoding of the inputted unicode character.
struct UTFEncodePoint(Element = char){
    size_t length = 0;
    Element[4] data = void;
    this(Args...)(Args args) if(Args.length <= this.data.length){
        foreach(i, arg; args) this.data[i] = cast(Element) arg;
        this.length = args.length;
    }
    auto opIndex(in size_t index) const in{
        assert(index >= 0 && index < this.length, "Index out of bounds.");
    }body{
        return this.data[index];
    }
    @property auto chars() const{
        return this.data[0 .. this.length].idup;
    }
    string toString() const{
        return cast(string) this.chars;
    }
    int opApply(in int delegate(in Element) apply) const{
        for(size_t i = 0; i < this.length; i++){
            if(auto result = apply(this.data[i])) return result;
        }
        return 0;
    }
}



/// Returns a struct containing information regarding how to encode a given
/// UTF code point.
auto utf8encode(Element = char)(dchar ch){
    alias Result = UTFEncodePoint!Element;
    if(ch <= 0x7f){
        return Result(ch);
    }else if(ch <= 0x7ff){
        return Result(
            0xc0 | (ch >> 6),
            0x80 | (ch & 0x3f),
        );
    }else if(ch <= 0xffff){
        return Result(
            0xe0 | (ch >> 12),
            0x80 | ((ch >> 6) & 0x3f),
            0x80 | (ch & 0x3f),
        );
    }else if(ch <= 0x10ffff){
        return Result(
            0xf0 | (ch >> 18),
            0x80 | ((ch >> 12) & 0x3f),
            0x80 | ((ch >> 6) & 0x3f),
            0x80 | (ch & 0x3f),
        );
    }else{
        throw new UTFEncodeException(ch);
    }
}



struct UTFEncodeRange(Range, Element = char) if(canUTFEncodeRange!Range){
    alias Encoded = UTFEncodePoint!Element;
    
    Range source;
    Encoded encoded = void;
    size_t encodedindex = 0;
    bool isempty = false;
    
    this(Range source){
        this.source = source;
        this.isempty = source.empty;
        if(!this.isempty) this.popFront();
    }
    this(Range source, Encoded encoded, size_t encodedindex, bool isempty){
        this.source = source;
        this.encoded = encoded;
        this.encodedindex = encodedindex;
        this.isempty = isempty;
    }
    
    @property bool empty() const{
        return this.isempty;
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
            if(this.source.empty){
                this.isempty = true;
            }else{
                this.encoded = utf8encode(this.source.front);
                this.encodedindex = 0;
                this.source.popFront();
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
    static assert(isUTFEncoded!(string));
    static assert(isUTFEncoded!(char[]));
    static assert(isUTFEncoded!(ubyte[]));
    static assert(!isUTFEncoded!(wstring));
    static assert(!isUTFEncoded!(dstring));
    static assert(!isUTFEncoded!(wchar[]));
    static assert(!isUTFEncoded!(dchar[]));
    static assert(!isUTFEncoded!(uint[]));
}
unittest{
    static assert(canUTFEncode!(wstring));
    static assert(canUTFEncode!(dstring));
    static assert(canUTFEncode!(wchar[]));
    static assert(canUTFEncode!(dchar[]));
    static assert(canUTFEncode!(uint[]));
    static assert(!canUTFEncode!(string));
    static assert(!canUTFEncode!(char[]));
    static assert(!canUTFEncode!(ubyte[]));
    static assert(!canUTFEncode!int);
    static assert(!canUTFEncode!uint);
    static assert(!canUTFEncode!void);
}
unittest{
    tests("UTF encode", {
        tests("No chars", {
            test(""d.utf8encode.equals(""));
        });
        tests("Single-byte chars", {
            test("test"d.utf8encode.equals("test"));
            test("hello"d.utf8encode.equals("hello"));
        });
        tests("Two-byte chars", {
            test("א"d.utf8encode.equals("\xD7\x90"));
            test("אֲנָנָס"d.utf8encode.equals("\xD7\x90\xD6\xB2\xD7\xA0\xD6\xB8\xD7\xA0\xD6\xB8\xD7\xA1"));
        });
        tests("Three-byte chars", {
            test("ツ"d.utf8encode.equals("\xE3\x83\x84"));
            test("ザーザー"d.utf8encode.equals("\xE3\x82\xB6\xE3\x83\xBC\xE3\x82\xB6\xE3\x83\xBC"));
        });
        tests("Four-byte chars", {
            test("😃"d.utf8encode.equals("\xF0\x9F\x98\x83"));
        });
        tests("Mixed", {
            test("!אツ😃"d.utf8encode.equals("!\xD7\x90\xE3\x83\x84\xF0\x9F\x98\x83"));
        });
        tests("Array", {
            dchar[] array = ['!', 'א', 'ツ', '😃'];
            test(array.utf8encode.equals("!\xD7\x90\xE3\x83\x84\xF0\x9F\x98\x83"));
        });
        tests("Already encoded", {
            tests("String", {
                auto str = "hello";
                testis(str.utf8encode, str);
            });
            tests("Byte array", {
                ubyte[] bytes = [0x32, 0x32, 0x32];
                testis(bytes.utf8encode, bytes);
            });
        });
    });
}
