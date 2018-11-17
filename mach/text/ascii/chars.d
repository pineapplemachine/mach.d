module mach.text.ascii.chars;

private:

import mach.traits.primitives : isCharacter;

/++ Docs

This module implements various functions for operating upon ASCII characters.
See https://en.wikipedia.org/wiki/ASCII.

+/

unittest{ /// Example
    // Convert an ASCII character to upper case.
    assert('x'.toupper == 'X');
    // Convert an ASCII character to lower case.
    assert('X'.tolower == 'x');
}

unittest{ /// Example
    assert('A'.isascii); // Is a valid ASCII character
    assert('a'.isalpha); // Is a–z or A–Z.
    assert('X'.isupper); // Is A–Z.
    assert('x'.islower); // Is a–z.
    assert('e'.isvowel); // Is a, e, i, o, u, or y (case-insensitive)
    assert('0'.isdigit); // Is 0–9.
    assert('F'.ishexdigit); // Is 0–9, a–f, or A–F.
    assert(';'.ispunctuation); // Is punctuation (excluding whitespace)
    assert(' '.iswhitespace); // Is whitespace
    assert('\0'.iscontrol); // Is a control character
    assert('!'.isprintable); // Is a printable (non-control) character
}

public pure nothrow @safe @nogc:



/// Determine whether a character code is valid within the ASCII character set.
bool isascii(T)(in T ch) if(isCharacter!T){
    return ch <= 0x7f;
}

/// Determine whether an ASCII character is an upper- or lower-case letter.
bool isalpha(T)(in T ch) if(isCharacter!T){
    return ch >= 'A' && ch <= 'z' && (ch <= 'Z' || ch >= 'a');
}

/// Determine whether an ASCII character is alphanumeric.
bool isalphanum(T)(in T ch) if(isCharacter!T){
    return isalpha(ch) || isdigit(ch);
}

/// Determine whether an ASCII character is a upper-case letter.
bool isupper(T)(in T ch) if(isCharacter!T){
    return ch >= 'A' && ch <= 'Z';
}

/// Determine whether an ASCII character is a lower-case letter.
bool islower(T)(in T ch) if(isCharacter!T){
    return ch >= 'a' && ch <= 'z';
}

/// Determine whether an ASCII character is an upper- or lower-case vowel,
/// including 'Y'.
bool isvowel(T)(in T ch) if(isCharacter!T){
    return (
        ch == 'a' || ch == 'e' || ch == 'i' ||
        ch == 'o' || ch == 'u' || ch == 'y' ||
        ch == 'A' || ch == 'E' || ch == 'I' ||
        ch == 'O' || ch == 'U' || ch == 'Y'
    );
}

/// Determine whether an ASCII character is a decimal digit 0-9.
bool isdigit(T)(in T ch) if(isCharacter!T){
    return ch >= '0' && ch <= '9';
}

/// Determine whether an ASCII character is a hexadecimal digit 0-9, a-f,
/// and A-F.
bool ishexdigit(T)(in T ch) if(isCharacter!T){
    return (
        (ch >= '0' && ch <= '9') ||
        (ch >= 'A' && ch <= 'F') ||
        (ch >= 'a' && ch <= 'f')
    );
}

/// Determine whether an ASCII character is a punctuation character.
/// This includes those ASCII codes labeled as either punctuation or
/// as undefined, excluding whitespace.
bool ispunctuation(T)(in T ch) if(isCharacter!T){
    return (
        (ch >= '!' && ch <= '/') ||
        (ch >= ':' && ch <= '@') ||
        (ch >= '[' && ch <= '`') ||
        (ch >= '{' && ch <= '~')
    );
}

/// Determine whether an ASCII character is a whitespace character.
bool iswhitespace(T)(in T ch) if(isCharacter!T){
    return (
        ch == ' ' || ch == '\n' ||
        ch == '\r' || ch == '\t' ||
        ch == '\f' || ch == '\v'
    );
}

/// Determine whether an ASCII character is a control character.
bool iscontrol(T)(in T ch) if(isCharacter!T){
    return ch <= 0x1f || ch == 0x7f;
}

/// Determine whether an ASCII character is a printable character.
bool isprintable(T)(in T ch) if(isCharacter!T){
    return ch >= 0x20 && ch <= 0x7e;
}

/// Convert an ASCII character to upper case.
/// Returns the input itself when the input is not a lower-case letter.
T toupper(T)(in T ch) if(isCharacter!T){
    return cast(T)(ch.islower ? ch - 0x20 : ch);
}

/// Convert an ASCII character to lower case.
/// Returns the input itself when the input is not an upper-case letter.
T tolower(T)(in T ch) if(isCharacter!T){
    return cast(T)(ch.isupper ? ch + 0x20 : ch);
}



private version(unittest){
    import mach.meta.aliases : Aliases;
}

/// isascii
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T(0x00).isascii);
        assert(T(0x40).isascii);
        assert(T(0x7f).isascii);
        assert(!T(0x80).isascii);
        assert(!T(0xff).isascii);
    }
}

/// isalpha
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('a').isalpha);
        assert(T('z').isalpha);
        assert(T('A').isalpha);
        assert(T('Z').isalpha);
        assert(!T(0).isalpha);
        assert(!T('1').isalpha);
        assert(!T('@').isalpha);
        assert(!T('`').isalpha);
        assert(!T('{').isalpha);
    }
}


/// isalphanum
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('a').isalphanum);
        assert(T('z').isalphanum);
        assert(T('A').isalphanum);
        assert(T('Z').isalphanum);
        assert(T('1').isalphanum);
        assert(T('9').isalphanum);
        assert(T('0').isalphanum);
        assert(!T(0).isalphanum);
        assert(!T('@').isalphanum);
        assert(!T('`').isalphanum);
        assert(!T('{').isalphanum);
    }
}

/// isupper
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('A').isupper);
        assert(T('Z').isupper);
        assert(!T('a').isupper);
        assert(!T('z').isupper);
        assert(!T('?').isupper);
    }
}

/// islower
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('a').islower);
        assert(T('z').islower);
        assert(!T('A').islower);
        assert(!T('Z').islower);
        assert(!T('?').islower);
    }
}

/// isvowel
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('a').isvowel);
        assert(T('A').isvowel);
        assert(T('e').isvowel);
        assert(T('E').isvowel);
        assert(T('y').isvowel);
        assert(T('Y').isvowel);
        assert(!T('z').isvowel);
        assert(!T('Z').isvowel);
        assert(!T('?').isvowel);
    }
}

/// isdigit
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('0').isdigit);
        assert(T('1').isdigit);
        assert(T('9').isdigit);
        assert(!T('a').isdigit);
        assert(!T('A').isdigit);
        assert(!T('?').isdigit);
    }
}

/// ishexdigit
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('0').ishexdigit);
        assert(T('1').ishexdigit);
        assert(T('9').ishexdigit);
        assert(T('a').ishexdigit);
        assert(T('A').ishexdigit);
        assert(T('f').ishexdigit);
        assert(T('F').ishexdigit);
        assert(!T('g').ishexdigit);
        assert(!T('G').ishexdigit);
        assert(!T('z').ishexdigit);
        assert(!T('Z').ishexdigit);
        assert(!T('?').ishexdigit);
    }
}

/// ispunctuation
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('.').ispunctuation);
        assert(T('!').ispunctuation);
        assert(T('?').ispunctuation);
        assert(T(',').ispunctuation);
        assert(!T('a').ispunctuation);
        assert(!T('A').ispunctuation);
        assert(!T('0').ispunctuation);
        assert(!T(' ').ispunctuation);
        assert(!T('\t').ispunctuation);
    }
}

/// iswhitespace
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T(' ').iswhitespace);
        assert(T('\t').iswhitespace);
        assert(T('\r').iswhitespace);
        assert(T('\n').iswhitespace);
        assert(!T('a').iswhitespace);
        assert(!T('A').iswhitespace);
    }
}

/// iscontrol
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T(0x00).iscontrol);
        assert(T(0x10).iscontrol);
        assert(T(0x1f).iscontrol);
        assert(T(0x7f).iscontrol);
        assert(!T('a').iscontrol);
        assert(!T('A').iscontrol);
        assert(!T('0').iscontrol);
    }
}

/// isprintable
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('a').isprintable);
        assert(T('A').isprintable);
        assert(T('0').isprintable);
        assert(T(' ').isprintable);
        assert(!T(0x00).isprintable);
        assert(!T(0x10).isprintable);
        assert(!T(0x1f).isprintable);
        assert(!T(0x7f).isprintable);
    }
}

/// toupper
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('a').toupper == T('A'));
        assert(T('z').toupper == T('Z'));
        assert(T('A').toupper == T('A'));
        assert(T('Z').toupper == T('Z'));
        assert(T('?').toupper == T('?'));
    }
}

/// tolower
unittest{
    foreach(T; Aliases!(char, wchar, dchar)){
        assert(T('a').tolower == T('a'));
        assert(T('z').tolower == T('z'));
        assert(T('A').tolower == T('a'));
        assert(T('Z').tolower == T('z'));
        assert(T('?').tolower == T('?'));
    }
}
