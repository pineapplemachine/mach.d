module mach.collect.orderedaa;

private:

import std.typecons : Tuple;
import std.traits : isImplicitlyConvertible;
import mach.traits : canHash, isIterableOf, hasNumericLength;
import mach.error : enforcebounds;
import mach.collect : LinkedList;
import mach.range : map;

public:



// TODO: This probably has a place in mach.traits I'm just not sure where
private template isItemsIterable(T, K, V){
    import mach.traits : isIterable, ElementType;
    static if(isIterable!T){
        enum bool isItemsIterable = (
            is(typeof(ElementType!T[0]) == K) &&
            is(typeof(ElementType!T[1]) == V)
        );
    }else{
        enum bool isItemsIterable = false;
    }
}



/// A collection which associates keys to values, and remembers the order in
/// which keys are added.
class OrderedAA(K, V, alias ListTemplate = LinkedList) if(canHash!K){
    /// Node type used to represent key, value pairs.
    alias Node = Tuple!(K, `key`, V, `value`);
    /// List type used to preserve order of key, value pairs.
    alias List = ListTemplate!Node;
    /// Associative array type used to associate keys to values.
    alias Dict = List.Node*[K];
    
    List list;
    Dict dict;
    
    this(){
        this.list = new List;
    }
    this(Items)(Items items) if(is(typeof(this.extend(items)))){
        this();
        this.extend(items);
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
    /// overwrite the previous value for that key. The resulting key, value
    /// pair will be placed at the front of the array if the key doesn't
    /// already exist.
    void setfront(K key, V value){
        this.setfront(Node(key, value));
    }
    /// ditto
    void setfront(Node node){
        if(auto current = node.key in this.dict){
            (**current).value.value = node.value;
        }else{
            this.dict[node.key] = this.list.prepend(node);
        }
    }
    
    /// Add a key, value entry to the array or, if that key already exists,
    /// overwrite the previous value for that key. The resulting key, value
    /// pair will be placed at the back of the array if the key doesn't
    /// already exist.
    void setback(K key, V value){
        this.setback(Node(key, value));
    }
    /// ditto
    void setback(Node node){
        if(auto current = node.key in this.dict){
            (**current).value.value = node.value;
        }else{
            this.dict[node.key] = this.list.append(node);
        }
    }
    /// ditto
    void opIndexAssign(V value, K key){
        this.set(key, value);
    }
    
    /// Add many key, value entries to the array at once. Order of resulting
    /// key, values pairs not guaranteed.
    auto extendfront(in V[K] array){
        foreach(K key, V value; array) this.setfront(key, value);
    }
    /// ditto
    auto extendback(in V[K] array){
        foreach(K key, V value; array) this.setback(key, value);
    }
    
    /// Add many key, value entries to the array at once. Order of resulting
    /// key, value pairs guaranteed to be the same as in the given array.
    auto extendfront(in typeof(this) array){
        foreach_reverse(node; array.list.values) this.setfront(node);
    }
    /// ditto
    auto extendback(in typeof(this) array){
        foreach(node; array.list.values) this.setback(node);
    }
    
    /// Add many key, value entries to the array at once. Order of resulting
    /// key, value pairs guaranteed to be the same as in the given iterable,
    /// which should contain tuples where the item at the first index is a key
    /// and the item at the second index is a value.
    auto extendfront(Items)(auto ref Items items) if(isItemsIterable!(Items, K, V)){
        auto frontnode = this.list.frontnode;
        foreach(K key, V value; items){
            this.dict[key] = this.list.insertbefore(frontnode, Node(key, value));
        }
    }
    /// ditto
    auto extendback(Items)(auto ref Items items) if(isItemsIterable!(Items, K, V)){
        foreach(K key, V value; items) this.setback(key, value);
    }
    
    alias set = setback;
    alias extend = extendback;
    
    /// Extend this array with key, value pairs from another array.
    auto opOpAssign(string op: "~", Items)(Items items) if(
        is(typeof(this.extend(items)))
    ){
        this.extend(items);
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
    auto removekey(in K key) in{assert(this.has(key));} body{
        auto node = this.dict[key];
        this.dict.remove(key);
        this.list.remove(node);
    }
    /// ditto
    auto remove(in K key) in{assert(this.has(key));} body{
        return this.removekey(key);
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
    
    /// Remove the key, pair value at an index.
    auto removeindex(in size_t index) in{assert(!this.empty);} body{
        auto node = this.list.nodeat(index);
        this.dict.remove(node.value.key);
        this.list.remove(node);
    }
    static if(!isImplicitlyConvertible!(K, size_t)){
        /// ditto
        auto remove(in size_t index) in{
            assert(index >= 0 && index < this.length);
        }body{
            return this.removeindex(index);
        }
    }
    
    /// Remove all key, value pairs from the array.
    auto clear(){
        this.list.clear();
        this.dict.clear();
    }
    
    /// Create a shallow copy of the array.
    @property typeof(this) dup(){
        auto array = new typeof(this);
        array.extend(this);
        return array;
    }
    
    /// Get the front key, value pair in the array.
    @property auto front() const{
        return this.list.front;
    }
    /// Get the back key, value pair in the array.
    @property auto back() const{
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
    /// must be in the same order in each array for them to be
    /// considered equal.
    override bool opEquals(Object object) const{
        import mach.range : compare;
        auto array = cast(typeof(this)) object;
        if(array){
            return compare!((a, b) => (a.key == b.key && a.value == b.value))(
                this.asrange, array.asrange
            );
        }else{
            return false;
        }
    }
    /// Compare equality with an unordered associative array. Equality is simply
    /// determined by having the same keys and values; order is irrelevant.
    bool opEquals(in V[K] array) const{
        import mach.range : all;
        if(this.length == array.length){
            return this.asrange.all!(e => array[e.key] == e.value);
        }else{
            return false;
        }
    }
    /// Compare equality with an iterable of key, value pairs. Key, value pairs
    /// must be in the same order in each collection for them to be considered
    /// equal.
    bool opEquals(Items)(auto ref Items items) const if(isItemsIterable!(Items, K, V)){
        auto range = this.items;
        foreach(K key, V value; items){
            if(range.empty) return false;
            auto item = range.front; range.popFront();
            if(item.key != key || item.value != value) return false;
        }
        return range.empty;
    }
    
    /// Get a range for iterating over the contents of this array which may not
    /// itself alter the array.
    auto asrange() pure nothrow @safe @nogc const{
        return this.list.asrange!false; // TODO: Also a mutable range
    }
    
    /// ditto
    @property auto items() pure nothrow @safe @nogc const{
        return this.asrange;
    }
    /// Get the keys of this array as a range.
    @property auto keys() pure nothrow @safe @nogc const{
        return this.asrange.map!(e => e.key);
    }
    /// Get the values of this array as a range.
    @property auto values() pure nothrow @safe @nogc const{
        return this.asrange.map!(e => e.value);
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
        return "[" ~ join(
            this.asrange.map!(e => e.key.to!string ~ ": " ~ e.value.to!string), ", "
        ).asarray ~ "]";
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
        tests("Copying", {
            auto a = new OrderedAA!(char, char);
            a['x'] = 'y';
            auto b = a.dup;
            a['z'] = 'w';
            b['i'] = 'j';
            test('x' in a);
            test('x' in b);
            test('z' in a);
            test('z' !in b);
            test('i' !in a);
            test('i' in b);
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
        tests("Extend", {
            auto array = new OrderedAA!(string, int)(["a": 1]);
            auto zw = new OrderedAA!(string, int);
            zw["z"] = 0; zw["w"] = 1;
            tests("Append unordered AA", {
                auto copy = array.dup;
                copy.extend(["b": 2, "c": 3]);
                testeq(copy.length, 3);
                testeq(copy["a"], 1);
                testeq(copy["b"], 2);
            });
            tests("Append OrderedAA", {
                auto copy = array.dup;
                auto extension = new OrderedAA!(string, int)(["b": 2]);
                copy.extend(extension);
                testeq(extension.length, 1);
                testeq(copy.length, 2);
                extension["b"] = 10;
                testeq(extension["b"], 10);
                testeq(copy["b"], 2);
                testeq(copy[$-1].key, "b");
            });
            tests("Prepend unordered AA", {
                auto copy = array.dup;
                testeq(copy[0].key, "a");
                copy.extendfront(["x": 0]);
                testeq(copy.length, 2);
                testeq(copy["x"], 0);
                testeq(copy[0].key, "x");
            });
            tests("Prepend OrderedAA", {
                auto copy = array.dup;
                alias extension = zw;
                copy.extendfront(extension);
                testeq(copy[0].key, extension[0].key);
                testeq(copy[1].key, extension[1].key);
                testeq(copy[2].key, "a");
            });
            tests("Append items", {
                auto copy = array.dup;
                alias extension = zw;
                copy.extend(extension.items);
                testeq(copy.length, 3);
                testeq(copy[0].key, "a");
                testeq(copy[1].key, "z");
                testeq(copy[2].key, "w");
                testeq(copy["z"], 0);
            });
            tests("Prepend items", {
                auto copy = array.dup;
                alias extension = zw;
                copy.extendfront(extension.items);
                testeq(copy.length, 3);
                testeq(copy[0].key, "z");
                testeq(copy[1].key, "w");
                testeq(copy[2].key, "a");
                testeq(copy["z"], 0);
            });
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
            tests("Front", {
                auto copy = array.dup;
                copy.removefront();
                testeq(copy.length, 3);
                testeq(copy[0].key, "b");
                testeq(copy[$-1].key, "d");
                test("a" !in copy);
            });
            tests("Back", {
                auto copy = array.dup;
                copy.removeback();
                testeq(copy.length, 3);
                testeq(copy[0].key, "a");
                testeq(copy[$-1].key, "c");
            });
            tests("By key", {
                auto copy = array.dup;
                copy.remove("b");
                testeq(copy.length, 3);
                testeq(copy[0].key, "a");
                testeq(copy[$-1].key, "d");
                test("b" !in copy);
            });
            tests("By index", {
                auto copy = array.dup;
                copy.remove(1);
                testeq(copy.length, 3);
                testeq(copy[0].key, "a");
                testeq(copy[$-1].key, "d");
                test("b" !in copy);
            });
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
            tests("With items", {
                auto array = new OrderedAA!(char, char)(['a': 'b', 'c': 'd']);
                testeq(array, array.items);
                testeq(array.items, array);
                testeq(array, array.dup.items);
                testeq(array.dup, array.items);
            });
        });
    });
}
