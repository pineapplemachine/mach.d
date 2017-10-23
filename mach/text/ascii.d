module mach.text.ascii;

private:

import mach.traits : isCharacter, validAsStringRange;
import mach.range : map, asrange, asarray;

/++ Docs

This module implements various functions for operating upon ASCII-encoded
strings and characters.

+/

unittest{ /// Example
    // Eagerly convert an ASCII character or string to upper case.
    assert('x'.toupper == 'X');
    assert("Hello".toupper == "HELLO");
    // Eagerly convert an ASCII character or string to lower case.
    assert('X'.tolower == 'x');
    assert("Hello".tolower == "hello");
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

public:



// Reference: https://en.wikipedia.org/wiki/ASCII



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



/// Convert an ASCII string to upper case. Returns a range.
auto toupperlazy(T)(in T str) if(validAsStringRange!T){
    return str.map!toupper;
}

/// Convert an ASCII string to lower case. Returns a range.
auto tolowerlazy(T)(in T str) if(validAsStringRange!T){
    return str.map!tolower;
}

/// Convert an ASCII string to upper case. Returns an array.
string touppereager(T)(in T str) if(validAsStringRange!T){
    return cast(string) str.toupperlazy.asarray;
}

/// Convert an ASCII string to lower case. Returns an array.
string tolowereager(T)(in T str) if(validAsStringRange!T){
    return cast(string) str.tolowerlazy.asarray;
}

/// Convert an ASCII string to upper case. Returns an array.
string toupper(T)(in T str) if(validAsStringRange!T){
    return str.touppereager;
}

/// Convert an ASCII string to lower case. Returns an array.
string tolower(T)(in T str) if(validAsStringRange!T){
    return str.tolowereager;
}



version(unittest){
    private:
    import mach.test;
    import mach.meta : Aliases;
}
unittest{
    tests("ASCII", {
        foreach(T; Aliases!(char, wchar, dchar)){
            tests("isascii", {
                test(T(0x00).isascii);
                test(T(0x40).isascii);
                test(T(0x7f).isascii);
                testf(T(0x80).isascii);
                testf(T(0xff).isascii);
            });
            tests("isalpha", {
                test(T('a').isalpha);
                test(T('z').isalpha);
                test(T('A').isalpha);
                test(T('Z').isalpha);
                testf(T(0).isalpha);
                testf(T('1').isalpha);
                testf(T('@').isalpha);
                testf(T('`').isalpha);
                testf(T('{').isalpha);
            });
            tests("isalphanum", {
                test(T('a').isalphanum);
                test(T('z').isalphanum);
                test(T('A').isalphanum);
                test(T('Z').isalphanum);
                test(T('1').isalphanum);
                test(T('9').isalphanum);
                test(T('0').isalphanum);
                testf(T(0).isalphanum);
                testf(T('@').isalphanum);
                testf(T('`').isalphanum);
                testf(T('{').isalphanum);
            });
            tests("isupper", {
                test(T('A').isupper);
                test(T('Z').isupper);
                testf(T('a').isupper);
                testf(T('z').isupper);
                testf(T('?').isupper);
            });
            tests("islower", {
                test(T('a').islower);
                test(T('z').islower);
                testf(T('A').islower);
                testf(T('Z').islower);
                testf(T('?').islower);
            });
            tests("isvowel", {
                test(T('a').isvowel);
                test(T('A').isvowel);
                test(T('e').isvowel);
                test(T('E').isvowel);
                test(T('y').isvowel);
                test(T('Y').isvowel);
                testf(T('z').isvowel);
                testf(T('Z').isvowel);
                testf(T('?').isvowel);
            });
            tests("isdigit", {
                test(T('0').isdigit);
                test(T('1').isdigit);
                test(T('9').isdigit);
                testf(T('a').isdigit);
                testf(T('A').isdigit);
                testf(T('?').isdigit);
            });
            tests("ishexdigit", {
                test(T('0').ishexdigit);
                test(T('1').ishexdigit);
                test(T('9').ishexdigit);
                test(T('a').ishexdigit);
                test(T('A').ishexdigit);
                test(T('f').ishexdigit);
                test(T('F').ishexdigit);
                testf(T('g').ishexdigit);
                testf(T('G').ishexdigit);
                testf(T('z').ishexdigit);
                testf(T('Z').ishexdigit);
                testf(T('?').ishexdigit);
            });
            tests("ispunctuation", {
                test(T('.').ispunctuation);
                test(T('!').ispunctuation);
                test(T('?').ispunctuation);
                test(T(',').ispunctuation);
                testf(T('a').ispunctuation);
                testf(T('A').ispunctuation);
                testf(T('0').ispunctuation);
                testf(T(' ').ispunctuation);
                testf(T('\t').ispunctuation);
            });
            tests("iswhitespace", {
                test(T(' ').iswhitespace);
                test(T('\t').iswhitespace);
                test(T('\r').iswhitespace);
                test(T('\n').iswhitespace);
                testf(T('a').iswhitespace);
                testf(T('A').iswhitespace);
            });
            tests("iscontrol", {
                test(T(0x00).iscontrol);
                test(T(0x10).iscontrol);
                test(T(0x1f).iscontrol);
                test(T(0x7f).iscontrol);
                testf(T('a').iscontrol);
                testf(T('A').iscontrol);
                testf(T('0').iscontrol);
            });
            tests("isprintable", {
                test(T('a').isprintable);
                test(T('A').isprintable);
                test(T('0').isprintable);
                test(T(' ').isprintable);
                testf(T(0x00).isprintable);
                testf(T(0x10).isprintable);
                testf(T(0x1f).isprintable);
                testf(T(0x7f).isprintable);
            });
            tests("toupper", {
                testeq(T('a').toupper, 'A');
                testeq(T('z').toupper, 'Z');
                testeq(T('A').toupper, 'A');
                testeq(T('Z').toupper, 'Z');
                testeq(T('?').toupper, '?');
            });
            tests("tolower", {
                testeq(T('a').tolower, 'a');
                testeq(T('z').tolower, 'z');
                testeq(T('A').tolower, 'a');
                testeq(T('Z').tolower, 'z');
                testeq(T('?').tolower, '?');
            });
        }
        tests("Strings", {
            testeq("Hello World!".toupper, "HELLO WORLD!");
            testeq("Hello World!".tolower, "hello world!");
        });
    });
}
