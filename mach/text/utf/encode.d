module mach.text.utf.encode;

private:

import mach.traits : isRange;
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
        dchar ch = T.init.asrange.front;
    }));
}

template canUTFEncodeRange(T){
    enum bool canUTFEncodeRange = isRange!T && is(typeof({
        dchar ch = T.init.front;
    }));
}



auto utfencode(Element = char, Iter)(Iter iter) if(canUTFEncode!Iter){
    auto range = iter.asrange;
    return UTFEncodeRange!(typeof(range), Element)(range);
}



/// Type returned when calling utfencode with a dchar argument.
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
        return this.data[0 .. this.length];
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
auto utfencode(Element = char)(dchar ch){
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
                this.encoded = utfencode(this.source.front);
                this.encodedindex = 0;
                this.source.popFront();
            }
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.consume : consume;
}
unittest{
    tests("UTF encode", {
        // No chars
        test(""d.utfencode.equals(""));
        // Single-byte chars
        test("test"d.utfencode.equals("test"));
        test("hello"d.utfencode.equals("hello"));
        // Two-byte chars
        test("א"d.utfencode.equals("\xD7\x90"));
        test("אֲנָנָס"d.utfencode.equals("\xD7\x90\xD6\xB2\xD7\xA0\xD6\xB8\xD7\xA0\xD6\xB8\xD7\xA1"));
        // Three-byte chars
        test("ツ"d.utfencode.equals("\xE3\x83\x84"));
        test("ザーザー"d.utfencode.equals("\xE3\x82\xB6\xE3\x83\xBC\xE3\x82\xB6\xE3\x83\xBC"));
        // Four-byte chars
        test("😃"d.utfencode.equals("\xF0\x9F\x98\x83"));
        // Mixed
        test("!אツ😃"d.utfencode.equals("!\xD7\x90\xE3\x83\x84\xF0\x9F\x98\x83"));
        // Array
        dchar[] array = ['!', 'א', 'ツ', '😃'];
        test(array.utfencode.equals("!\xD7\x90\xE3\x83\x84\xF0\x9F\x98\x83"));
    });
}
