module mach.text.utf.utf16.encode;

private:

import mach.range.asrange : asrange;
import mach.text.utf.encode;
import mach.text.utf.exceptions;

/++ Docs

This module implements UTF-16 encoding of a UTF-32 input string.

+/

public:



// References:
// https://tools.ietf.org/html/rfc2781



alias isUTF16Encoded = isUTFEncoded!wchar;

auto utf16encodestring(Iter)(auto ref Iter iter) if(canUTFEncode!Iter){
    auto range = iter.asrange;
    return UTFEncodeRange!(typeof(range), ch => UTF16EncodePoint(ch))(range);
}



struct UTF16EncodePoint{
    bool surrogatepair;
    wchar ch0;
    wchar ch1;
    
    this(bool surrogatepair, wchar ch0, wchar ch1){
        this.ch0 = ch0;
        this.ch1 = ch1;
        this.surrogatepair = surrogatepair;
    }
    
    this(in dchar ch){
        if(ch < 0x10000){
            this.surrogatepair = false;
            this.ch0 = cast(wchar) ch;
        }else{
            static const error = new UTFEncodeException();
            if(ch > 0x10ffff) throw error;
            immutable chp = ch - 0x10000;
            this.surrogatepair = true;
            this.ch0 = cast(wchar)(0xd800 | (chp >> 10));
            this.ch1 = cast(wchar)(0xdc00 | (chp & 0x3ff));
        }
    }
    
    @property size_t length() const{
        return cast(size_t) this.surrogatepair + 1;
    }
    auto opIndex(in size_t index) const in{
        assert(index <= this.surrogatepair);
    }body{
        return index ? this.ch1 : this.ch0;
    }
    @property auto chars() const{
        return this.surrogatepair ? [this.ch0, this.ch1] : [this.ch0];
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

unittest{
    static assert(isUTF16Encoded!(wstring));
    static assert(isUTF16Encoded!(wchar[]));
    static assert(isUTF16Encoded!(ushort[]));
    static assert(!isUTF16Encoded!(string));
    static assert(!isUTF16Encoded!(dstring));
    static assert(!isUTF16Encoded!(char[]));
    static assert(!isUTF16Encoded!(dchar[]));
    static assert(!isUTF16Encoded!(uint[]));
}

unittest{
    // Single code units
    assert(""d.utf16encodestring.equals(""w));
    assert("test"d.utf16encodestring.equals("test"w));
    assert("hello"d.utf16encodestring.equals("hello"w));
    assert("א"d.utf16encodestring.equals("א"w));
    assert("אֲנָנָס"d.utf16encodestring.equals("אֲנָנָס"w));
    assert("ツ"d.utf16encodestring.equals("ツ"w));
    assert("ザーザー"d.utf16encodestring.equals("ザーザー"w));
    assert("!אツ"d.utf16encodestring.equals("!אツ"w));
    // Surrogate pairs
    assert("😃"d.utf16encodestring.equals("😃"w));
    assert("?😃?"d.utf16encodestring.equals("?😃?"w));
    assert("!אツ😃"d.utf16encodestring.equals("!אツ😃"w));
}
unittest{
    assert("test"d.asrange.utf16encodestring.equals("test"w));
    assert([cast(uint) 'x', cast(uint) 'ツ'].utf16encodestring.equals("xツ"w));
}
unittest{
    assertthrows!UTFEncodeException({
        // Code point outside unicode planes.
        [cast(dchar) 0x110000].utf16encodestring.consume;
    });
}
