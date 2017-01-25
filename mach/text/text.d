module mach.text.text;

private:

import mach.text.str : str, StrSettings;

/++ Docs

This module implements the `text` function, which converts all of its arguments
to strings using `str` in `mach.text.str` and concatenates them.

+/

unittest{ /// Example
    assert(text("hello", ' ', "world") == "hello world");
    assert(text("I would walk ", 1000, " miles") == "I would walk 1000 miles");
}

public:



/// Convert each argument to a string and return the concatenation of those
/// strings.
auto text(StrSettings settings = StrSettings.Default, Args...)(Args args){
    auto result = "";
    foreach(arg; args) result ~= str(arg);
    return result;
}



private version(unittest){
    import mach.test;
}
unittest{
    tests("Text", {
        testeq(text("hello"), "hello");
        testeq(text("hello", ' ', "world"), "hello world");
        testeq(text("abc", 123), "abc123");
        testeq(text(0, 1, 2), "012");
        testeq(text(), "");
    });
}
