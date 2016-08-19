module mach.collect.orderedaa;

private:

import std.typecons : Tuple;
import std.traits : isImplicitlyConvertible;
import mach.traits : canHash, isIterableOf, hasNumericLength;
import mach.error : enforcebounds;
import mach.collect : LinkedList;
import mach.range : map;

public:


class OrderedAA(K, V) if(canHash!K){
    alias Node = Tuple!(K, `key`, V, `value`);
    alias List = LinkedList!Node;
    alias Dict = List.Node*[K];
    
    List list;
    Dict dict;
    
    this(){
        this.list = new List;
    }
    this(V[K] array){
        this();
        this.extend(array);
    }
    this(typeof(this) array){
        this();
        this.extend(array);
    }
    
    ~this(){
        this.clear();
    }
    
    /// Determine whether the array is empty.
    @property bool empty() const{
        return this.list.empty;
    }
    /// Get the number of elements in the array.
    @property auto length() const{
        return this.list.length;
    }
    /// ditto
    alias opDollar = length;
    
    /// Add a key, value entry to the array or, if that key already exists,
    /// overwrite the previous value for that key.
    void set(bool prepend = false)(K key, V value){
        this.set!prepend(Node(key, value));
    }
    /// ditto
    void set(bool prepend = false)(Node node){
        if(auto current = node.key in this.dict){
            (**current).value.value = node.value;
        }else{
            static if(prepend) auto listnode = this.list.prepend(node);
            else auto listnode = this.list.append(node);
            this.dict[node.key] = listnode;
        }
    }
    /// ditto
    void opIndexAssign(V value, K key){
        this.set(key, value);
    }
    
    /// Add many key, value entries to the array at once. Order of resulting
    /// key, values pairs not guaranteed.
    auto extend(bool prepend = false)(V[K] array){
        foreach(K key, V value; array) this.set!prepend(key, value);
    }
    /// Add many key, value entries to the array at once. Order of resulting
    /// key, value pairs guaranteed to be the same as in the given array.
    auto extend(bool prepend = false)(typeof(this) array){
        static if(!prepend) foreach(node; array.list.values) this.set!prepend(node);
        else foreach_reverse(node; array.list.values) this.set!prepend(node);
    }
    /// Extend this array with key, value pairs from another array.
    auto opOpAssign(string op: "~", Array)(Array array) if(
        is(Array == V[K]) || is(Array == typeof(this))
    ){
        this.extend(array);
    }
    
    /// Get the value associated with some key.
    auto get(in K key) const in{
        assert(this.has(key));
    }body{
        return this.dict[key].value.value;
    }
    /// ditto
    auto opIndex(in K key) const{
        return this.get(key);
    }
    /// Get the value associated with some key, or a fallback value if the key
    /// is not present in the array.
    auto get(in K key, V fallback) const{
        if(auto node = this.has(key)){
            return (**node).value.value;
        }else{
            return fallback;
        }
    }
    /// ditto
    auto opIndex(in K key, V fallback) const{
        return this.get(key, fallback);
    }
    
    /// Determine whether some key is contained within the array.
    auto has(in K key) const{
        return key in this.dict;
    }
    /// ditto
    auto opBinaryRight(string op: "in")(K lhs) const{
        return this.has(lhs);
    }
    
    /// Remove some key from the array. Fails if the key is not contained within
    /// the array.
    auto remove(in K key) in{
        assert(this.has(key));
    }body{
        auto node = this.dict[key];
        this.dict.remove(key);
        this.list.remove(node);
    }
    
    /// Remove the front key, value pair from the array.
    auto removefront() in{assert(!this.empty);} body{
        this.dict.remove(this.list.front.key);
        this.list.removefront();
    }
    /// Remove the back key, value pair from the array.
    auto removeback() in{assert(!this.empty);} body{
        this.dict.remove(this.list.back.key);
        this.list.removeback();
    }
    
    /// Remove all key, value pairs from the array.
    auto clear(){
        this.list.clear();
        this.dict.clear();
    }
    
    /// Get the front key, value pair in the array.
    @property auto front(){
        return this.list.front;
    }
    /// Get the back key, value pair in the array.
    @property auto back(){
        return this.list.back;
    }
    
    /// Get the key, value pair at the given index of the array.
    auto index(in size_t index) in{
        assert(index >= 0 && index < this.length);
    }body{
        return &this.list.nodeat(index).value;
    }
    static if(!isImplicitlyConvertible!(K, size_t)){
        /// ditto
        auto opIndex(in size_t index){
            return this.index(index);
        }
    }
    
    /// Compare two ordered associative arrays for equality. Key, value pairs
    /// must be in the same order in each array in order for them to be
    /// considered equal.
    override bool opEquals(Object object) const{
        import mach.range : compare;
        auto array = cast(typeof(this)) object;
        if(array){
            return compare!((a, b) => (a.key == b.key && a.value == b.value))(this.asrange!false, array.asrange!false);
        }else{
            return false;
        }
    }
    /// Compare equality with an unordered associative array. Equality is simply
    /// determined by having the same keys and values; order is irrelevant.
    bool opEquals(in V[K] array) const{
        import mach.range : all;
        if(this.length == array.length){
            return this.asrange!false.all!(e => array[e.key] == e.value);
        }else{
            return false;
        }
    }
    
    /// Get a range for iterating over the key, value pairs of this array whose
    /// contents can be mutated.
    auto asrange()() pure nothrow @safe @nogc{
        return this.list.asrange!mutable;
    }
    /// ditto
    auto asrange(bool mutable)() pure nothrow @safe @nogc if(mutable){
        return this.list.asrange!mutable;
    }
    /// Get a range for iterating over the contents of this array which may not
    /// itself alter the array.
    auto asrange(bool mutable)() pure nothrow @safe @nogc const if(!mutable){
        return this.list.asrange!mutable;
    }
    
    /// ditto
    @property auto items(bool mutable = false)(){
        return this.asrange!mutable;
    }
    /// Get the keys of this array as a range.
    @property auto keys(bool mutable = false)(){
        return this.asrange!mutable.map!(e => e.key);
    }
    /// Get the values of this array as a range.
    @property auto values(bool mutable = false)(){
        return this.asrange!mutable.map!(e => e.value);
    }
    
    // TODO: Figure out how to make this not broken
    /+
    int opApply(F)(F apply) if(is(F == int delegate(ref K key, ref V value))){
        foreach(ref node; this.list){
            if(auto result = apply(node.key, node.value)) return result;
        }
        return 0;
    }
    +/
    
    /// Get a string representation.
    override string toString() const{
        import std.conv : to;
        import mach.range : map, join, asarray;
        return "[" ~ join(this.asrange!false.map!(e => e.key.to!string ~ ": " ~ e.value.to!string), ", ").asarray ~ "]";
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range : contains, equals;
}
unittest{
    tests("Ordered associative array", {
        tests("Basic functionality", {
            auto array = new OrderedAA!(string, string);
            test(array.empty);
            testeq(array.length, 0);
            array["a"] = "apple";
            testf(array.empty);
            testeq(array.length, 1);
            testeq(array["a"], "apple");
            testeq(array[0].key, "a");
            testeq(array[0].value, "apple");
            testeq(array[$-1].key, "a");
            testeq(array.front.key, "a");
            testeq(array.back.key, "a");
            test("a" in array);
            test("b" !in array);
        });
        tests("Extend", {
            auto array = new OrderedAA!(string, int);
            tests("Append unordered AA", {
                array.extend(["a": 1, "b": 2, "c": 3]);
                testeq(array.length, 3);
                testeq(array["a"], 1);
            });
            tests("Append OrderedAA", {
                auto extension = new OrderedAA!(string, int)(["d": 4]);
                array.extend(extension);
                testeq(extension.length, 1);
                testeq(array.length, 4);
                extension["d"] = 10;
                testeq(extension["d"], 10);
                testeq(array["d"], 4);
                testeq(array[3].key, "d");
            });
            tests("Prepend unordered AA", {
                test(["a", "b", "c"].contains(array[0].key));
                array.extend!true(["x": 0]);
                testeq(array["x"], 0);
                testeq(array[0].key, "x");
            });
            tests("Prepend OrderedAA", {
                auto extension = new OrderedAA!(string, int);
                extension["z"] = 0;
                extension["w"] = 1;
                array.extend!true(extension);
                testeq(array[0].key, extension[0].key);
                testeq(array[1].key, extension[1].key);
                testeq(array[2].key, "x");
            });
        });
        tests("Iteration", {
            auto array = new OrderedAA!(string, string);
            array["a"] = "apple";
            array["b"] = "bear";
            array["c"] = "culpable";
            test("Keys",
                array.keys.equals(["a", "b", "c"])
            );
            test("Values",
                array.values.equals(["apple", "bear", "culpable"])
            );
            test("Items",
                array.items.equals([
                    array.Node("a", "apple"),
                    array.Node("b", "bear"),
                    array.Node("c", "culpable")
                ])
            );
        });
        tests("Removal", {
            auto array = new OrderedAA!(string, int);
            array["a"] = 1;
            array["b"] = 2;
            array["c"] = 3;
            array["d"] = 4;
            testeq(array.length, 4);
            testeq(array[0].key, "a");
            testeq(array[$-1].key, "d");
            test("a" in array);
            array.removefront();
            testeq(array.length, 3);
            testeq(array[0].key, "b");
            testeq(array[$-1].key, "d");
            test("a" !in array);
            array.removeback();
            testeq(array.length, 2);
            testeq(array[0].key, "b");
            testeq(array[$-1].key, "c");
            array.remove("b");
            testeq(array.length, 1);
            testeq(array[0].key, "c");
            array.remove("c");
            test(array.empty);
        });
        tests("Clear", {
            auto array = new OrderedAA!(string, int)(["a": 1]);
            testf(array.empty);
            array.clear;
            test(array.empty);
        });
        tests("Get with fallback", {
            auto array = new OrderedAA!(string, int)(["a": 1]);
            testeq(array["a", 2], 1);
            testeq(array["z", 2], 2);
        });
        tests("Equality", {
            tests("With unordered AA", {
                auto a = ['a': 'b', 'c': 'd', 'e': 'f'];
                auto b = new OrderedAA!(char, char)(a);
                auto c = new OrderedAA!(char, char);
                testeq(a, b);
                testeq(b, a);
                testneq(a, c);
                testneq(c, a);
            });
            tests("With OrderedAA", {
                auto a = new OrderedAA!(string, int)(["a": 1]);
                auto b = new OrderedAA!(string, int)(["a": 1]);
                auto c = new OrderedAA!(string, int)(["a": 2]);
                testeq(a, b);
                testeq(b, a);
                testneq(a, c);
                testneq(b, c);
            });
        });
    });
}
