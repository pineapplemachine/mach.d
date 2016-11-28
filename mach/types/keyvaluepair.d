module mach.types.keyvaluepair;

private:

import mach.types.tuple : tuple;

public:



/// Key, value pair type. Intended primarily to store a key, value pair
/// belonging to the built-in associative array type.
struct KeyValuePair(K, V){
    K key;
    V value;
    
    alias astuple this;
    
    @property auto astuple(){
        return tuple(this.key, this.value);
    }
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
