module mach.text.ascii.strings;

private:

import mach.traits.element : ElementType;
import mach.traits.string : validAsStringRange;
import mach.range.map : map;
import mach.range.asarray : asarray;
import mach.text.ascii.chars : charupper = toupper, charlower = tolower;

/++ Docs
This module contains functions for operating upon ASCII-encoded strings.
+/

unittest{ /// Example
    // Eagerly convert an ASCII string to upper case.
    assert("Hello".toupper == "HELLO");
    // Eagerly convert an ASCII string to lower case.
    assert("Hello".tolower == "hello");
}

public:

/// Convert an ASCII string to upper case. Returns a range.
auto toupperlazy(T)(in T str) if(validAsStringRange!T){
    return str.map!(charupper!(ElementType!T));
}

/// Convert an ASCII string to lower case. Returns a range.
auto tolowerlazy(T)(in T str) if(validAsStringRange!T){
    return str.map!(charlower!(ElementType!T));
}

/// Eagerly convert an ASCII string to upper case. Returns an array.
auto touppereager(T)(in T str) if(validAsStringRange!T){
    return cast(immutable) str.toupperlazy.asarray;
}

/// Eagerly convert an ASCII string to lower case. Returns an array.
auto tolowereager(T)(in T str) if(validAsStringRange!T){
    return cast(immutable) str.tolowerlazy.asarray;
}

/// Convert an ASCII string to upper case. Returns an array.
auto toupper(T)(in T str) if(validAsStringRange!T){
    return str.touppereager;
}

/// Convert an ASCII string to lower case. Returns an array.
auto tolower(T)(in T str) if(validAsStringRange!T){
    return str.tolowereager;
}

private version(unittest){
    import mach.range.compare : equals;
}

unittest {
    assert("Hello World!".toupper.equals("HELLO WORLD!"));
    assert("Hello World!".tolower.equals("hello world!"));
    assert("Hello World!"w.toupper.equals("HELLO WORLD!"w));
    assert("Hello World!"w.tolower.equals("hello world!"w));
    assert("Hello World!"d.toupper.equals("HELLO WORLD!"d));
    assert("Hello World!"d.tolower.equals("hello world!"d));
}
