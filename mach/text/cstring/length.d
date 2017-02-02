module mach.text.cstring.length;

private:

import mach.traits : isCharacter;

/++ Docs

The `cstringlength` function can be used to determine the length of a
null-terminated string by traversing it.

+/

unittest{ /// Example
    assert("hello world\0".ptr.cstringlength == "hello world".length);
}

/++ Docs

The function can also be called with wchar or dchar strings as its input.

+/

unittest{ /// Example
    assert("hello\0"w.ptr.cstringlength == 5);
    assert("world\0"d.ptr.cstringlength == 5);
}

public:



/// Get the length of a null-terminated string by traversing it.
/// Reference: http://www.stdlib.net/~colmmacc/strlen.c.html
@system pure nothrow auto cstringlength(Char)(in Char* cstr) if(isCharacter!Char){
    // Check bytes up to the first word boundary
    immutable origin = cast(size_t) cstr;
    auto initsearch = cast(immutable(Char)*) cstr;
    while(true){
        if(((cast(size_t) initsearch) & (ulong.sizeof - 1)) == 0) break;
        if(*initsearch == '\0') return cast(size_t) initsearch - origin;
        initsearch++;
    }
    // Check a word at a time
    auto lsearch = cast(immutable(ulong)*) initsearch;
    static if(Char.sizeof == 1){
        //enum ulong magicbits = 0x7efefefefefefeff;
        enum ulong himagic = 0x8080808080808080;
        enum ulong lomagic = 0x0101010101010101;
        while(true){
            if(((*lsearch - lomagic) & himagic) != 0){
                auto at = cast(immutable(Char)*) lsearch;
                if(at[0] == '\0'){
                    return cast(size_t) at - origin;
                }else if(at[1] == '\0'){
                    return cast(size_t) at - origin + 1;
                }else if(at[2] == '\0'){
                    return cast(size_t) at - origin + 2;
                }else if(at[3] == '\0'){
                    return cast(size_t) at - origin + 3;
                }else if(at[4] == '\0'){
                    return cast(size_t) at - origin + 4;
                }else if(at[5] == '\0'){
                    return cast(size_t) at - origin + 5;
                }else if(at[6] == '\0'){
                    return cast(size_t) at - origin + 6;
                }else if(at[7] == '\0'){
                    return cast(size_t) at - origin + 7;
                }
            }
            lsearch++;
        }
    }else static if(Char.sizeof == 2){
        enum ulong himagic = 0x8000800080008000;
        enum ulong lomagic = 0x0001000100010001;
        while(true){
            // TODO: This algorithm gets surprisingly many false positives
            if(((*lsearch - lomagic) & himagic) != 0){
                auto at = cast(immutable(Char)*) lsearch;
                if(at[0] == '\0'){
                    return (cast(size_t) at - origin) / 2;
                }else if(at[1] == '\0'){
                    return (cast(size_t) at - origin) / 2 + 1;
                }else if(at[2] == '\0'){
                    return (cast(size_t) at - origin) / 2 + 2;
                }else if(at[3] == '\0'){
                    return (cast(size_t) at - origin) / 2 + 3;
                }
            }
            lsearch++;
        }
    }else static if(Char.sizeof == 4){
        while(true){
            if((*lsearch & 0x0000000ffffffff) == 0 || (*lsearch & 0xffffffff0000000) == 0){
                auto at = cast(immutable(Char)*) lsearch;
                return (cast(size_t) at - origin) / 4 + (*at != '\0');
            }
            lsearch++;
        }
    }else{
        static assert(false, "Unrecognized character type.");
    }
}



private version(unittest){
    import mach.range.random : xorshift;
}

unittest{ /// char* cstringlength
    char[] chars = new char[256];
    for(uint i = 0; i < 256; i++) chars[i] = cast(char)(255 - i);
    assert(chars.ptr.cstringlength == 255);
}

unittest{ /// wchar* cstringlength
    auto rng = xorshift(0x1234u);
    wchar[] wchars = new wchar[512];
    wchars[$-1] = 0;
    foreach(i; 0 .. wchars.length - 1){
        wchars[i] = rng.random!wchar(1, wchar.max);
    }
    assert(wchars.ptr.cstringlength == wchars.length - 1);
}

unittest{ /// dchar* cstringlength
    auto rng = xorshift(0x1234u);
    dchar[] dchars = new dchar[1024];
    dchars[$-1] = 0;
    foreach(i; 0 .. dchars.length - 1){
        dchars[i] = rng.random!dchar(1, dchar.max);
    }
    assert(dchars.ptr.cstringlength == dchars.length - 1);
}
