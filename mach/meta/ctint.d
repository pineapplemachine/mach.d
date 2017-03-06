module mach.meta.ctint;

private:

/++ Docs

This module provides a dead-simple, no-dependency integer stringification
function intended primarily for use in functions generating mixin strings
at compile time.

+/

unittest{ /// Example
    static assert(ctint(1234) == "1234");
}

public:



string ctint(N)(in N value){
    if(value == 0) return "0";
    N x = value;
    string result = "";
    while(x != 0){
        immutable d = x % 10;
        result = cast(char)('0' + (d > 0 ? d : -d)) ~ result;
        x /= 10;
    }
    return value > 0 ? result : "-" ~ result;
}



unittest{
    assert(ctint(0) == "0");
    assert(ctint(1) == "1");
    assert(ctint(-1) == "-1");
    assert(ctint(1u) == "1");
    assert(ctint(2) == "2");
    assert(ctint(-2) == "-2");
    assert(ctint(2u) == "2");
    assert(ctint(100) == "100");
    assert(ctint(-100) == "-100");
    assert(ctint(int.max) == "2147483647");
    assert(ctint(int.min) == "-2147483648");
}
