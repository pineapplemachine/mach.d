module mach.text.utf.combined;

private:

import mach.traits : isStringLike, ElementType;
import mach.text.utf.utf8;
import mach.text.utf.utf16;

/++ Docs

This module exposes generalized implementations for acquiring UTF-8, UTF-16,
or UTF-32 strings from arbitrary UTF-encoded inputs.
`utf8encode` can be used to acquire a UTF-8 string, `utf16encode` a UTF-16
string, and `utf32encode` a UTF-32 string.

The `utfencode` alias can be used to acquire UTF-8 strings and the `utfdecode`
alias can be used to acquire UTF-32 strings.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    // UTF-8 => UTF-8
    assert("hello! ツ".utf8encode.equals("hello! ツ"));
    // UTF-8 => UTF-16
    assert("hello! ツ".utf16encode.equals("hello! ツ"w));
    // UTF-8 => UTF-32
    assert("hello! ツ".utfdecode.equals("hello! ツ"d));
    // UTF-16 => UTF-32
    assert("hello! ツ"w.utfdecode.equals("hello! ツ"d));
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
    dstring utf32 = "hello! ツ".utfdecode.asarray!(immutable dchar); // Decode UTF-8
    assert(utf32 == "hello! ツ"d);
}

public:



import mach.text.utf.utf8 : UTF8EncodePoint, utf8decode;
import mach.text.utf.utf16 : UTF16EncodePoint, utf16decode;



/// Get a string as encoded UTF-8.
alias utfencode = utf8encode;

/// Get a UTF-8, UTF-16, or UTF-32 string as decoded UTF-32.
alias utfdecode = utf32encode;



/// Get an object representing a UTF-8 encoded code point.
auto utf8encode(in dchar ch){
    return UTF8EncodePoint(ch);
}

/// Given an input UTF-8, UTF-16, or UTF-32 string, get a UTF-8 string.
auto utf8encode(T)(auto ref T iter) if(isStringLike!T){
    enum size = ElementType!T.sizeof;
    static if(size == 1){
        return iter; // Already UTF-8 encoded
    }else static if(size == 2){
        return iter.utf16decode.utf8encodestring; // UTF-16 encoded
    }else static if(size == 4){
        return iter.utf8encodestring; /// UTF-32 encoded
    }else{
        static assert(false, "Unrecognized string character type.");
    }
}



/// Get an object representing a UTF-16 encoded code point.
auto utf16encode(in dchar ch){
    return UTF16EncodePoint(ch);
}

/// Given an input UTF-8, UTF-16, or UTF-32 string, get a UTF-16 string.
auto utf16encode(T)(auto ref T iter) if(isStringLike!T){
    enum size = ElementType!T.sizeof;
    static if(size == 1){
        return iter.utf8decode.utf16encodestring; // UTF-8 encoded
    }else static if(size == 2){
        return iter; // Already UTF-16 encoded
    }else static if(size == 4){
        return iter.utf16encodestring; /// UTF-32 encoded
    }else{
        static assert(false, "Unrecognized string character type.");
    }
}



/// Given an input UTF-8, UTF-16, or UTF-32 string, get a UTF-32 string.
auto utf32encode(T)(auto ref T iter) if(isStringLike!T){
    enum size = ElementType!T.sizeof;
    static if(size == 1){
        return iter.utf8decode; // UTF-8 encoded
    }else static if(size == 2){
        return iter.utf16decode; // UTF-16 encoded
    }else static if(size == 4){
        return iter; /// Already UTF-32 encoded
    }else{
        static assert(false, "Unrecognized string character type.");
    }
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
