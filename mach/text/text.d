module mach.text.text;

private:

import mach.text.str : str, StrSettings;

public:



/// Convert each argument to a string and return the concatenation of those
/// strings.
auto text(StrSettings settings = StrSettings.Default, Args...)(Args args){
    auto result = "";
    foreach(arg; args) result ~= str(arg);
    return result;
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
