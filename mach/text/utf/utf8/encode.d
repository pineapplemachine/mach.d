module mach.text.utf.utf8.encode;

private:

import mach.range.asrange : asrange;
import mach.text.utf.encode;
import mach.text.utf.exceptions;

/++ Docs

This module implements UTF-8 encoding of a UTF-32 input string.

+/

public:



// References:
// https://encoding.spec.whatwg.org/#utf-8
// https://github.com/mathiasbynens/utf8.js/blob/master/utf8.js



alias isUTF8Encoded = isUTFEncoded!char;

auto utf8encodestring(Iter)(auto ref Iter iter) if(canUTFEncode!Iter){
    auto range = iter.asrange;
    return UTFEncodeRange!(typeof(range), ch => UTF8EncodePoint(ch))(range);
}



struct UTF8EncodePoint{
    size_t length = 0;
    char[4] data = void;
    
    this(size_t length, char[4] data){
        this.length = length;
        this.data = data;
    }
    
    this(in dchar ch){
        static const error = new UTFEncodeException();
        if(ch <= 0x7f){
            this.length = 1;
            this.data[0] = cast(char) ch;
        }else if(ch <= 0x7ff){
            this.length = 2;
            this.data[0] = cast(char)(0xc0 | (ch >> 6));
            this.data[1] = cast(char)(0x80 | (ch & 0x3f));
        }else if(ch <= 0xffff){
            if(ch >= 0xd800 && ch <= 0xdfff) throw error;
            this.length = 3;
            this.data[0] = cast(char)(0xe0 | (ch >> 12));
            this.data[1] = cast(char)(0x80 | ((ch >> 6) & 0x3f));
            this.data[2] = cast(char)(0x80 | (ch & 0x3f));
        }else if(ch <= 0x10ffff){
            this.length = 4;
            this.data[0] = cast(char)(0xf0 | (ch >> 18));
            this.data[1] = cast(char)(0x80 | ((ch >> 12) & 0x3f));
            this.data[2] = cast(char)(0x80 | ((ch >> 6) & 0x3f));
            this.data[3] = cast(char)(0x80 | (ch & 0x3f));
        }else{
            throw error;
        }
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
}



private version(unittest){
    import mach.test.assertthrows : assertthrows;
    import mach.range.compare : equals;
    import mach.range.consume : consume;
}

/// isUTF8Encoded template tests
unittest {
    static assert(isUTF8Encoded!(string));
    static assert(isUTF8Encoded!(char[]));
    static assert(isUTF8Encoded!(ubyte[]));
    static assert(!isUTF8Encoded!(wstring));
    static assert(!isUTF8Encoded!(dstring));
    static assert(!isUTF8Encoded!(wchar[]));
    static assert(!isUTF8Encoded!(dchar[]));
    static assert(!isUTF8Encoded!(uint[]));
}

/// Encode UTF-32 strings as UTF-8 strings
unittest {
    assert(""d.utf8encodestring.equals(""));
    assert("test"d.utf8encodestring.equals("test"));
    assert("hello"d.utf8encodestring.equals("hello"));
    assert("א"d.utf8encodestring.equals("א"));
    assert("אֲנָנָס"d.utf8encodestring.equals("אֲנָנָס"));
    assert("ツ"d.utf8encodestring.equals("ツ"));
    assert("ザーザー"d.utf8encodestring.equals("ザーザー"));
    assert("!אツ"d.utf8encodestring.equals("!אツ"));
    assert("😃"d.utf8encodestring.equals("😃"));
    assert("?😃?"d.utf8encodestring.equals("?😃?"));
    assert("!אツ😃"d.utf8encodestring.equals("!אツ😃"));
}

/// Encode UTF-32 strings represented as types other than `dstring`
unittest {
    assert("test"d.asrange.utf8encodestring.equals("test"));
    assert([cast(uint) 'x', cast(uint) 'ツ'].utf8encodestring.equals("xツ"));
}

/// Code point outside unicode planes
unittest{
    assertthrows!UTFEncodeException({
        [cast(dchar) 0x110000].utf8encodestring.consume;
    });
}
