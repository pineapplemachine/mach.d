module mach.text.cstring;

private:

import mach.meta : varmin;
import mach.traits : isString, isCharacter, ElementType;
import mach.text.utf : utfencode;

/++ Docs

The `tocstring` and `fromcstring` functions can be used to acquire a null-
terminated string from some input string, and a regular string from a pointer
to a null-terminated string, respectively.

+/

unittest{ /// Example
    assert("hello".tocstring == "hello\0");
    assert("world\0".ptr.fromcstring == "world");
}

/++ Docs

`tocstring` optionally accepts a template parameter specifying how the output
should be encoded. The default is UTF-8, indicated by passing `char`.
Passing `wchar` would cause the output to be encoded in UTF-16, and `dchar`
in UTF-32.

+/

unittest{ /// Example
    wstring wstr = "hello".tocstring!wchar;
    assert(wstr == "hello\0"w);
    dstring dstr = "hello".tocstring!dchar;
    assert(dstr == "hello\0"d);
}

/++ Docs

`fromcstring` optionally accepts a limit, where characters beyond the length
limit are cut off. This can be used to prevent very long strings from causing
performance problems, if the full content of the string is not important in
that case.

If no limit is given, then the function will proceed indefinitely, until a
null byte is found. (Or, perhaps, when a memory error results from attempting
to accumulate such a long string.)

+/

unittest{ /// Example
    assert("hello\0".ptr.fromcstring!4 == "hell"); // Cuts off after the fourth character.
}

public:



/// Get a null-terminated string from some input string.
/// Gets a UTF-8 encoded string by default, but this behavior can be
/// changed by passing a different character type for the first template
/// argument.
auto tocstring(Char = char, S)(auto ref S str) if(isString!S && isCharacter!Char){
    auto encoded = str.utfencode!Char;
    immutable(Char)[] result;
    static if(is(typeof({result.reserve(encoded.length + 1);}))){
        result.reserve(encoded.length + 1);
    }
    foreach(const ch; encoded) result ~= ch;
    result ~= Char(0);
    return result;
}



/// TODO: lazy fromcstring
alias fromcstring = eagerfromcstring;

/// Get a string type from some null-terminated input string.
@system pure nothrow auto eagerfromcstring(Char)(in Char* cstr, in size_t approxlength = 256) if(isCharacter!Char){
    immutable(Char)[] result;
    result.reserve(approxlength);
    const(Char)* ptr = cstr;
    while(*ptr != 0) result ~= *(ptr++);
    return result;
}

/// Get a string type from some null-terminated input string.
/// Will not attempt to acquire any more than `limit` characters.
@system pure nothrow auto eagerfromcstring(size_t limit, Char)(
    in Char* cstr, in size_t approxlength = 256
) if(isCharacter!Char){
    immutable(Char)[] result;
    result.reserve(varmin(limit, approxlength));
    const(Char)* ptr = cstr;
    while(*ptr != 0 && result.length < limit) result ~= *(ptr++);
    return result;
}



private version(unittest){
    import mach.meta : Aliases;
    void TestString(alias str)(){
        mixin(`string utf8 = "` ~ str ~ `";`);
        mixin(`wstring utf16 = "` ~ str ~ `"w;`);
        mixin(`dstring utf32 = "` ~ str ~ `"d;`);
        mixin(`string utf8n = "` ~ str ~ `\0";`);
        mixin(`wstring utf16n = "` ~ str ~ `\0"w;`);
        mixin(`dstring utf32n = "` ~ str ~ `\0"d;`);
        auto utf8c = str.tocstring!char;
        auto utf16c = str.tocstring!wchar;
        auto utf32c = str.tocstring!dchar;
        assert(utf8c == utf8n);
        assert(utf16c == utf16n);
        assert(utf32c == utf32n);
        assert(fromcstring(utf8c.ptr) == utf8);
        assert(fromcstring(utf16c.ptr) == utf16);
        assert(fromcstring(utf32c.ptr) == utf32);
    }
}

unittest{
    TestString!"";
    TestString!"!";
    TestString!"?";
    TestString!"hello";
    TestString!"ツ";
    TestString!"😃";
    TestString!"אֲנָנָס";
    TestString!"!אツ😃";
    TestString!"this is a somewhat longer input";
}

unittest{ /// fromcstring with limit
    auto input = "abcdef\0";
    assert(fromcstring!4(input.ptr) == "abcd");
}
