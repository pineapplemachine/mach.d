module mach.text.cstring.convert;

private:

import mach.meta : varmin;
import mach.traits : isString, isCharacter, isArray, ElementType;
import mach.error : IndexOutOfBoundsError;
import mach.text.utf : utfencode;
import mach.range.asrange : asrange;

/++ Docs

The `tocstring` and `fromcstring` functions can be used to acquire a null-
terminated string from some input string, and a regular string from a pointer
to a null-terminated string, respectively.

`tocstring` returns a value of type `CString`, which imitates a string but
can be passed to functions which require a pointer.

+/

unittest{ /// Example
    assert("hello".tocstring.payload == "hello\0");
    assert("world\0".ptr.fromcstring == "world");
}

/++ Docs

`tocstring` optionally accepts a template parameter specifying how the output
should be encoded. The default is UTF-8, indicated by passing `char`.
Passing `wchar` would cause the output to be encoded in UTF-16, and `dchar`
in UTF-32.

+/

unittest{ /// Example
    assert("hello".tocstring!wchar.payload == "hello\0"w);
    assert("hello".tocstring!dchar.payload == "hello\0"d);
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
    return CString!Char(str);
}



/// TODO: lazy fromcstring
alias fromcstring = eagerfromcstring;

/// Get a string type from some null-terminated input string.
@system pure nothrow auto eagerfromcstring(Char)(in Char* cstr, in size_t approxlength = 256) if(
    isCharacter!Char
){
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



/// Type representing a null-terminated character string.
/// Can be passed to functions as though it was a pointer to a cstring with
/// indeterminate length, yet imitates a normal string.
struct CString(Char) if(isCharacter!Char){
    immutable(Char)[] payload;
    
    alias ptr this;
    
    this(S)(auto ref S str, in bool nullterminated = false) if(isString!S){
        static if(isArray!S && is(ElementType!S == immutable(Char))){
            if(nullterminated){
                this.payload = str;
                return;
            }
        }
        auto encoded = str.utfencode!Char;
        static if(is(typeof({this.payload.reserve(encoded.length + 1);}))){
            this.payload.reserve(encoded.length + 1);
        }
        foreach(const ch; encoded) this.payload ~= ch;
        if(!nullterminated) this.payload ~= Char(0);
    }
    
    @property auto ptr() const{
        return this.payload.ptr;
    }
    
    /// Length of the string, not including the terminating byte.
    /// Assumes that there are no null characters other than the one terminating
    /// the string.
    @property auto length() const{
        assert(this.payload.length > 0);
        return this.payload.length - 1;
    }
    
    @property typeof(this) dup() const{
        return typeof(this)(this.payload.idup, true);
    }
    
    /// Get a range for enumerating characters in the string.
    /// Optionally accepts a boolean template argument specifying whether the
    /// terminating null character should be included in the output range.
    /// By default, the terminating character is not included.
    @property auto asrange(bool includenull = false)() const{
        static if(includenull){
            return this.payload[0 .. $].asrange;
        }else{
            return this.payload[0 .. $-1].asrange;
        }
    }
    
    auto opIndex(in size_t index) const in{
        static const error = new IndexOutOfBoundsError();
        error.enforce(index, this);
    }body{
        return this.payload[index];
    }
    
    /// Check equality with another, not null-terminated string.
    bool opEquals(in immutable(Char)[] str) const{
        assert(this.payload.length > 0);
        return str == this.payload[0 .. $-1];
    }
    /// Check equality with another null-terminated string.
    bool opEquals(in typeof(this) cstr) const{
        return this.payload == cstr.payload;
    }
}



private version(unittest){
    import mach.text.cstring.length : cstringlength;
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
        // Verify payload
        assert(utf8c.payload == utf8n);
        assert(utf16c.payload == utf16n);
        assert(utf32c.payload == utf32n);
        // Test fromcstring
        assert(fromcstring(utf8c.ptr) == utf8);
        assert(fromcstring(utf16c.ptr) == utf16);
        assert(fromcstring(utf32c.ptr) == utf32);
        // Ensure alias this to pointer works as expected
        assert(cstringlength(utf8c) == utf8.length);
    }
}

unittest{ /// Convert to and from cstring
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
