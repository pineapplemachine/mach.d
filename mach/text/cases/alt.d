module mach.text.cases.alt;

public:

/// Alternate a character between upper and lower case if it's an English letter
char altcase(in char ch) @safe pure nothrow{
    if(ch >= 'A' && ch <= 'Z'){
        return cast(char) ((cast(int) ch) + 32);
    }else if(ch >= 'a' && ch <= 'z'){
        return cast(char) ((cast(int) ch) - 32);
    }else{
        return ch;
    }
}

unittest{
    assert(altcase('a') == 'A');
    assert(altcase('f') == 'F');
    assert(altcase('N') == 'n');
    assert(altcase('Z') == 'z');
    assert(altcase('4') == '4');
    assert(altcase('$') == '$');
}
