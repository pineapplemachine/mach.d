module mach.text.utf.combined;

private:

import mach.traits : isCharacter, isStringLike, ElementType;
import mach.range.bytecontent : bytecontentbe, bytecontentle;
import mach.text.utf.encodings;
import mach.text.utf.utf8;
import mach.text.utf.utf16;

/++ Docs

This module exposes generalized implementations for acquiring UTF-8, UTF-16,
or UTF-32 strings from arbitrary UTF-encoded inputs.
`utf8encode` can be used to acquire a UTF-8 string, `utf16encode` a UTF-16
string, and `utf32encode` a UTF-32 string.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    assert("hello! ツ".utf8encode.equals("hello! ツ")); // UTF-8 => UTF-8
    assert("hello! ツ".utf16encode.equals("hello! ツ"w)); // UTF-8 => UTF-16
    assert("hello! ツ".utf32encode.equals("hello! ツ"d)); // UTF-8 => UTF-32
}

/++ Docs

The `utfdecode` function can be used to acquire a UTF-32 string from some
UTF-encoded input.

The `utfencode` function can be called without template arguments to encode
a UTF-8 string, it can be called with a character type as a template argument
to specify the encoding type (UTF-8 for `char`, UTF-16 for `wchar`, and
UTF-32 for `dchar`), or it can be called with a member of the `UTFEncoding`
enum as a template argument to specify the output encoding type.

+/

unittest{
    import mach.range.compare : equals;
    assert("!!".utfdecode.equals("!!"d)); // UTF-8 => UTF-32
    assert("!!"d.utfencode.equals("!!")); // UTF-32 => UTF-8
    assert("!!".utfencode!wchar.equals("!!"w)); // UTF-8 => UTF-16
    assert("!!"w.utfencode!(UTFEncoding.UTF32).equals("!!"d)); // UTF-16 => UTF-32
}

/++ Docs

Note that if the input was not already encoded with the desired encoding type
then these functions return ranges which lazily enumerate code units, rather
than arrays or string primitives.
To get an in-memory array from the output, a function such as `asarray` from
`mach.range.asarray` can be used.

+/

unittest{ /// Example
    import mach.range.asarray : asarray;
    dstring utf32 = "hello! ツ".utf8decode.asarray!(immutable dchar);
    assert(utf32 == "hello! ツ"d);
}

public:



import mach.text.utf.utf8 : UTF8EncodePoint, utf8decode;
import mach.text.utf.utf16 : UTF16EncodePoint, utf16decode;



/// Get a UTF-8, UTF-16, or UTF-32 string as decoded UTF-32.
alias utfdecode = utf32encode;



/// Get a UTF-8 encoded string from the input.
auto utfencode(S)(auto ref S str) if(isStringLike!S){
    return utf8encode(str);
}

/// When the first template argument is `char`, get a UTF-8 string.
/// When the first template argument is `wchar`, get a UTF-16 string.
/// When the first template argument is `dchar`, get a UTF-32 string.
auto utfencode(Char, S)(auto ref S str) if(isStringLike!S && isCharacter!Char){
    return utfencode!(UTFEncodingForChar!Char)(str);
}

/// Acquire a string of the specified encoding type.
auto utfencode(UTFEncoding encoding, S)(auto ref S str) if(
    isStringLike!S
){
    static if(encoding is UTFEncoding.UTF8){
        return utf8encode(str);
    }else static if(encoding is UTFEncoding.UTF16){
        return utf16encode(str);
    }else static if(encoding is UTFEncoding.UTF16BE){
        return utf16encode(str).bytecontentbe;
    }else static if(encoding is UTFEncoding.UTF16LE){
        return utf16encode(str).bytecontentle;
    }else static if(encoding is UTFEncoding.UTF32){
        return utf32encode(str);
    }else static if(encoding is UTFEncoding.UTF32BE){
        return utf32encode(str).bytecontentbe;
    }else static if(encoding is UTFEncoding.UTF32LE){
        return utf32encode(str).bytecontentle;
    }
}



/// Get an object representing a UTF-8 encoded code point.
auto utf8encode(in dchar ch){
    return UTF8EncodePoint(ch);
}

/// Given an input UTF-8, UTF-16, or UTF-32 string, get a UTF-8 string.
auto utf8encode(S)(auto ref S str) if(isStringLike!S){
    enum size = ElementType!S.sizeof;
    static if(size == 1){
        return str; // Already UTF-8 encoded
    }else static if(size == 2){
        return str.utf16decode.utf8encodestring; // UTF-16 encoded
    }else static if(size == 4){
        return str.utf8encodestring; /// UTF-32 encoded
    }else{
        static assert(false, "Unrecognized string character type.");
    }
}



/// Get an object representing a UTF-16 encoded code point.
auto utf16encode(in dchar ch){
    return UTF16EncodePoint(ch);
}

/// Given an input UTF-8, UTF-16, or UTF-32 string, get a UTF-16 string.
auto utf16encode(S)(auto ref S str) if(isStringLike!S){
    enum size = ElementType!S.sizeof;
    static if(size == 1){
        return str.utf8decode.utf16encodestring; // UTF-8 encoded
    }else static if(size == 2){
        return str; // Already UTF-16 encoded
    }else static if(size == 4){
        return str.utf16encodestring; /// UTF-32 encoded
    }else{
        static assert(false, "Unrecognized string character type.");
    }
}



/// Given an input UTF-8, UTF-16, or UTF-32 string, get a UTF-32 string.
auto utf32encode(S)(auto ref S str) if(isStringLike!S){
    enum size = ElementType!S.sizeof;
    static if(size == 1){
        return str.utf8decode; // UTF-8 encoded
    }else static if(size == 2){
        return str.utf16decode; // UTF-16 encoded
    }else static if(size == 4){
        return str; /// Already UTF-32 encoded
    }else{
        static assert(false, "Unrecognized string character type.");
    }
}



/// Determine whether the input is a valid unicode code point.
/// TODO: Put this in mach.text.unicode
bool unicodevalid(in dchar ch){
    return ch <= 0x10ffff && (ch < 0xd800 || ch > 0xdfff);
}



private version(unittest){
    import mach.range.compare : equals;
}

unittest{ /// Encode UTF-8
    assert("!אツ😃".utf8encode.equals("!אツ😃"));
    assert("!אツ😃"w.utf8encode.equals("!אツ😃"));
    assert("!אツ😃"d.utf8encode.equals("!אツ😃"));
    // `utfencode` aliases `utf8encode`.
    assert("!אツ😃".utfencode.equals("!אツ😃"));
    assert("!אツ😃"w.utfencode.equals("!אツ😃"));
    assert("!אツ😃"d.utfencode.equals("!אツ😃"));
}

unittest{ /// Encode UTF-16
    assert("!אツ😃".utf16encode.equals("!אツ😃"w));
    assert("!אツ😃"w.utf16encode.equals("!אツ😃"w));
    assert("!אツ😃"d.utf16encode.equals("!אツ😃"w));
}

unittest{ /// Encode UTF-32
    assert("!אツ😃".utf32encode.equals("!אツ😃"d));
    assert("!אツ😃"w.utf32encode.equals("!אツ😃"d));
    assert("!אツ😃"d.utf32encode.equals("!אツ😃"d));
    // `utfdecode` aliases `utf32encode`.
    assert("!אツ😃".utfdecode.equals("!אツ😃"d));
    assert("!אツ😃"w.utfdecode.equals("!אツ😃"d));
    assert("!אツ😃"d.utfdecode.equals("!אツ😃"d));
}

unittest{ /// Encode UTF-16 BE & LE
    assert("😃".utfencode!(UTFEncoding.UTF16BE).equals([0xd8, 0x3d, 0xde, 0x03]));
    assert("😃".utfencode!(UTFEncoding.UTF16LE).equals([0x3d, 0xd8, 0x03, 0xde]));
    assert("😃"w.utfencode!(UTFEncoding.UTF16BE).equals([0xd8, 0x3d, 0xde, 0x03]));
    assert("😃"w.utfencode!(UTFEncoding.UTF16LE).equals([0x3d, 0xd8, 0x03, 0xde]));
    assert("😃"d.utfencode!(UTFEncoding.UTF32BE).equals([0x00, 0x01, 0xf6, 0x03]));
    assert("😃"d.utfencode!(UTFEncoding.UTF32LE).equals([0x03, 0xf6, 0x01, 0x00]));
}

unittest{ /// Encode UTF-32 BE & LE
    assert("😃".utfencode!(UTFEncoding.UTF32BE).equals([0x00, 0x01, 0xf6, 0x03]));
    assert("😃".utfencode!(UTFEncoding.UTF32LE).equals([0x03, 0xf6, 0x01, 0x00]));
    assert("😃"w.utfencode!(UTFEncoding.UTF16BE).equals([0xd8, 0x3d, 0xde, 0x03]));
    assert("😃"w.utfencode!(UTFEncoding.UTF16LE).equals([0x3d, 0xd8, 0x03, 0xde]));
    assert("😃"d.utfencode!(UTFEncoding.UTF32BE).equals([0x00, 0x01, 0xf6, 0x03]));
    assert("😃"d.utfencode!(UTFEncoding.UTF32LE).equals([0x03, 0xf6, 0x01, 0x00]));
}
