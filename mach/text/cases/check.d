module mach.text.cases.check;

private:

import std.ascii : isAlpha;
import std.traits : isSomeString;
import std.algorithm : all;

public:
    
import std.ascii : isUpper, isLower;

/// Determine if all letters in a string are upper case.
bool isUpper(S)(in S text) if(isSomeString!S){
    return text.all!((ch) => (!isAlpha(ch) || isUpper(ch)));
}
/// Determine if all letters in a string are lower case.
bool isLower(S)(in S text) if(isSomeString!S){
    return text.all!((ch) => (!isAlpha(ch) || !isUpper(ch)));
}
    
alias isupper = isUpper;
alias islower = isLower;

version(unittest) import mach.error.unit;
unittest{
    // is upper case
    test("HELLO WORLD".isupper);
    testf("hello world".isupper);
    testf("Hello World".isupper);
    // is lower case
    testf("HELLO WORLD".islower);
    test("hello world".islower);
    testf("Hello World".islower);
}
