module mach.types.keyvaluepair;

private:

import mach.meta : Aliases;

/++ Docs

This module defines the `KeyValuePair` type, which behaves similarly to a tuple
containing two elements, a key and a value.

+/

unittest{ /// Example
    auto pair = KeyValuePair!(string, int)("hello", 1);
    assert(pair.key == "hello");
    assert(pair.value == 1);
}

public:



/// Key, value pair type. Intended primarily to store a key, value pair
/// belonging to the built-in associative array type.
struct KeyValuePair(K, V){
    alias KeyValue = Aliases!(K, V);
    
    KeyValue expand;
    alias expand this;
    
    alias key = expand[0];
    alias value = expand[1];
}



unittest{
    // Define types to test with
    alias Pair = KeyValuePair!(string, string);
    struct Pairs{
        enum bool empty = false;
        @property auto front(){return Pair("key", "value");}
        void popFront(){}
    }
    {
        // Verify integrity of attributes
        auto pair = Pair("key", "value");
        assert(pair.key == "key");
        assert(pair.value == "value");
    }{
        // Verify foreach pattern
        foreach(key, value; Pairs()){
            assert(key == "key");
            assert(value == "value");
            break;
        }
    }{
        // Verify behavior of opAssign
        auto pair = Pair("a", "b");
        pair = Pair("x", "y");
    }
}
