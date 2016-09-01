module mach.text.text;

private:

import std.conv : to;

public:



/// Convert each argument to a string and return the concatenation of those
/// strings.
auto text(Args...)(Args args){
    auto str = "";
    foreach(arg; args){
        str ~= arg.to!string;
    }
    return str;
}



version(unittest){
    private:
    import mach.error.unit;
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
