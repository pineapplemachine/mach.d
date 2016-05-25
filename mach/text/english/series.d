module mach.text.english.series;

private:

import std.conv : to;
import std.algorithm : canFind;
import std.string : join;

public:

/// Get a grammatically-correct (probably) series of items, e.g. "one, two, and three".
/// Oxford comma can be optionally disabled (get "one, two and three" instead).
string series(bool oxford = true, Args...)(in Args items){
    if(items.length == 0){
        return "";
    }else if(items.length == 1){
        return to!string(items[0]);
    }else if(items.length == 2){
        return to!string(items[0]) ~ " and " ~ to!string(items[$-1]);
    }else{
        string[items.length] itemstrings;
        string separator = ", ";
        foreach(index, item; items){
            itemstrings[index] = to!string(item);
            if(separator == ", " && itemstrings[index].canFind(",")) separator = "; ";
        }
        immutable string left = join(itemstrings[0 .. $-1], separator);
        static if(oxford){
            immutable string right = separator ~ "and " ~ itemstrings[$-1];
        }else{
            immutable string right = " and " ~ itemstrings[$-1];
        }
        return left ~ right;
    }
}

version(unittest) import mach.error.unit;
unittest{
    tests("English series", {
        testeq(list("abc"), "abc");
        testeq(list("abc", "xyz"), "abc and xyz");
        testeq(list!true("one", "two", "three"), "one, two, and three");
        testeq(list!false("one", "two", "three"), "one, two and three");
        testeq(list("one, two", "three, four", "five, six"), "one, two; three, four; and five, six");
    });
}
