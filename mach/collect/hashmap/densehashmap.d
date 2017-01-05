module mach.collect.hashmap.densehashmap;

private:

import mach.types : KeyValuePair;
import mach.traits : isInfiniteIterable, isTemplateOf;
import mach.traits : hasNumericLength, hasNumericRemaining, hash, canHash;
import mach.collect.hashmap.densehashcommon;
import mach.collect.hashmap.exceptions;

public:



static assert(isKeyValuePairIterable!(int, string, string[int]));
private template isKeyValuePairIterable(K, V, T){
    enum bool isKeyValuePairIterable = !isInfiniteIterable!T && is(typeof({
        foreach(key, value; T.init){
            auto pair = new KeyValuePair!(K, V)(key, value);
        }
    }));
}

private template isKeyValuePairIterable(T){
    enum bool isKeyValuePairIterable = !isInfiniteIterable!T && is(typeof({
        foreach(key, value; T.init){}
    }));
}
private template KeyValuePairIterableKeyType(T) if(isKeyValuePairIterable!T){
    alias KeyValuePairIterableKeyType = typeof({
        foreach(key, value; T.init){return key;}
    }());
}
private template KeyValuePairIterableValueType(T) if(isKeyValuePairIterable!T){
    alias KeyValuePairIterableKeyType = typeof({
        foreach(key, value; T.init){return value;}
    }());
}



/// Get the contents of an associative array as a DenseHashMap.
auto asdensehashmap(bool dynamic = true, T)(auto ref T values) if(
    isKeyValuePairIterable!T
){
    alias K = KeyValuePairIterableKeyType!T;
    alias V = KeyValuePairIterableValueType!T;
    return DenseHashMap!(K, V, dynamic)(values);
}



template StaticDenseHashMap(K, V){
    alias StaticDenseHashMap = DenseHashMap!(K, V, false);
}

template DynamicDenseHashMap(K, V){
    alias DynamicDenseHashMap = DenseHashMap!(K, V, true);
}

/// Implementation for a HashMap type.
/// When dynamic is true, the set automatically resizes up and down to
/// accommodate usage. Otherwise an error is produced if too many values are
/// added to the set. Static maps can still be resized, but unlike dynamic maps
/// they will not be resized automatically upon insertion or removal.
struct DenseHashMap(
    K, V, bool Dynamic = true
) if(canHash!K){
    alias Key = K; /// Key type.
    alias Value = V; /// Value type.
    
    alias Bucket = KeyValuePair!(K, V);
    mixin DenseHashFieldsMixin!();
    mixin DenseHashMethodsMixin!();
    
    /// Disallow blitting.
    @disable this(this);
    
    /// Create a map, specifying its initial size.
    this(in size_t size){
        this.setsize(size);
    }
    
    /// Create a map, specifying its initial content.
    /// Accepts an iterable of key, value pairs.
    this(T)(auto ref T pairs) if(
        isKeyValuePairIterable!(K, V, T) && (
            dynamic || hasNumericLength!T || hasNumericRemaining!T
        )
    ){
        static if(hasNumericRemaining!T){
            this.setsize(this.suggestsize(pairs.remaining));
        }else static if(hasNumericLength!T){
            this.setsize(this.suggestsize(pairs.length));
        }
        this.update(pairs);
    }
    
    /// Used to genericize some code in `DenseHashMethodsMixin`.
    private static auto getbucketkey(in Bucket* bucket){
        return bucket.key;
    }
    
    /// Get the value associated with a key.
    /// Fails when no such key exists in the map.
    V get(K key) const{
        if(!this.empty){
            auto result = this.getbucketin(this.buckets, key);
            if(result.exists) return this.buckets[result.index].value;
        }
        throw new DenseHashMapKeyError();
    }
    /// Get the value associated with a key.
    /// Returns the provided fallback when no such key exists in the map.
    V get(K key, lazy V fallback) const{
        if(!this.empty){
            auto result = this.getbucketin(this.buckets, key);
            if(result.exists) return this.buckets[result.index].value;
        }
        return fallback();
    }
    
    /// Sets a key, value pair in the map. If no value was yet associated with
    /// the given key, then null is returned. If any value had already been
    /// associated with the key, and has been overridden, then a pointer to
    /// the map's representation of that prior key, value pair is returned.
    /// Throws a `DenseHashMapFullError` if the operation fails because the
    /// map was full and could not be automatically resized.
    auto set(K key, V value){
        this.autoupsize();
        auto result = getbucketin(buckets, key);
        if(result.exists){
            auto prior = this.buckets[result.index];
            this.buckets[result.index] = new Bucket(key, value);
            this.numvalues += (prior is null);
            return prior;
        }else{
            throw new DenseHashMapFullError();
        }
    }
    
    /// Add the key, value pairs from some iterable to this one.
    auto update(T)(auto ref T pairs) if(isKeyValuePairIterable!(K, V, T)){
        foreach(key, value; pairs) this.set(key, value);
    }
    
    /// Get a reference to a shallow copy of the map.
    @property typeof(this)* dup(){
        if(this.empty){
            // Get a new map of the same size and with the same empty contents.
            return new typeof(this)(this.size);
        }else{
            static if(dynamic){
                // Get a new map with the same contents, but size may differ.
                return new typeof(this)(this.pairs);
            }else{
                // Get a new map with the same contents and the same size.
                auto copy = new typeof(this)(this.size);
                copy.update(this.pairs);
                return copy;
            }
        }
    }
    
    /// Get a hash of the map, which is a function of the hashes of all keys
    /// and values in the map.
    /// Values in the map must be hashable for this function to be valid.
    /// (Normally, only keys must be hashable.)
    static if(canHash!V) size_t toHash() @safe const nothrow{
        size_t maphash = (
            this.length << (size_t.sizeof * 4) |
            this.length >> (size_t.sizeof * 4)
        );
        foreach(bucket; this.buckets){
            if(bucket !is null){
                maphash ^= hash(bucket.key) * hash(bucket.value);
            }
        }
        return maphash;
    }
    
    /// Returns a range for enumerating keys in the map, in arbitrary order.
    /// The resulting range does not allow modification.
    auto ikeys() const{
        return DenseHashMapRange!(
            typeof(this),
            DenseHashMapRangeValues.Keys,
            DenseHashRangeMutability.Immutable
        )(&this);
    }
    /// Returns a range for enumerating keys in the map, in arbitrary order.
    /// The resulting range allows removal of its elements.
    auto keys(){
        return DenseHashMapRange!(
            typeof(this),
            DenseHashMapRangeValues.Keys,
            DenseHashRangeMutability.Removable
        )(&this);
    }
    
    /// Returns a range for enumerating values in the map, in arbitrary order.
    /// The resulting range does not allow modification.
    auto ivalues() const{
        return DenseHashMapRange!(
            typeof(this),
            DenseHashMapRangeValues.Values,
            DenseHashRangeMutability.Immutable
        )(&this);
    }
    /// Returns a range for enumerating values in the map, in arbitrary order.
    /// The resulting range allows removal of its elements.
    auto values(){
        return DenseHashMapRange!(
            typeof(this),
            DenseHashMapRangeValues.Values,
            DenseHashRangeMutability.Removable
        )(&this);
    }
    
    /// Returns a range for enumerating key, value pairs in the map,
    /// in arbitrary order.
    /// The resulting range does not allow modification.
    auto ipairs() const{
        return DenseHashMapRange!(
            typeof(this),
            DenseHashMapRangeValues.Pairs,
            DenseHashRangeMutability.Immutable
        )(&this);
    }
    /// Returns a range for enumerating key, value pairs in the map,
    /// in arbitrary order.
    /// The resulting range allows removal of its elements.
    auto pairs(){
        return DenseHashMapRange!(
            typeof(this),
            DenseHashMapRangeValues.Pairs,
            DenseHashRangeMutability.Removable
        )(&this);
    }
    
    /// Make the map valid as a range.
    @property auto asrange(){
        return this.pairs;
    }
    /// ditto
    @property auto asrange() const{
        return this.ipairs;
    }
    
    auto opBinaryRight(string op: "in")(K key){
        return this.contains(key);
    }
    auto opIndex(K key){
        return this.get(key);
    }
    auto opIndexAssign(V value, K key){
        this.set(key, value);
    }
}



enum DenseHashMapRangeValues{
    Keys, /// The range enumerates keys.
    Values, /// The range enumerates values.
    Pairs /// The range enumerates key, value pairs.
}

/// Range for iterating over a `DenseHashMap` instance.
struct DenseHashMapRange(
    Source, DenseHashMapRangeValues values, DenseHashRangeMutability mutability
) if(
    isTemplateOf!(Source, DenseHashMap)
){
    alias Key = Source.Key;
    alias Value = Source.Value;
    
    mixin DenseHashRangeMixin!();
    
    /// Get the front of the range.
    @property auto front() const{
        static if(values is DenseHashMapRangeValues.Keys){
            return this.frontbucket.key;
        }else static if(values is DenseHashMapRangeValues.Values){
            return this.frontbucket.value;
        }else static if(values is DenseHashMapRangeValues.Pairs){
            return *this.frontbucket;
        }else{
            static assert(false); // Shouldn't happen
        }
    }
    /// Get the back of the range.
    @property auto back() const{
        static if(values is DenseHashMapRangeValues.Keys){
            return this.backbucket.key;
        }else static if(values is DenseHashMapRangeValues.Values){
            return this.backbucket.value;
        }else static if(values is DenseHashMapRangeValues.Pairs){
            return *this.backbucket;
        }else{
            static assert(false); // Shouldn't happen
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.filter : filter;
}
unittest{
    tests("DenseHashMap", {
        alias Map = DenseHashMap;
        tests("Empty", {
            auto map = new Map!(string, string)();
            test(map.empty);
            testf(map.full);
            testeq(map.length, 0);
            testeq(map.density, 0);
            testnull(map.contains("hello"));
            testnull(map.remove("hello"));
            testeq(map.get("hello", "fallback"), "fallback");
            testfail({map.get("hello");});
            foreach(e; map.values) assert(false);
            foreach(e; map.ivalues) assert(false);
            foreach(e; map.keys) assert(false);
            foreach(e; map.ikeys) assert(false);
            foreach(e; map.pairs) assert(false);
            foreach(e; map.ipairs) assert(false);
            map.clear();
        });
        tests("Insertion", {
            void TestInsertion(T)(T map){
                map.set("a", "apple");
                testeq(map.length, 1);
                testeq(map.get("a"), "apple");
                testeq(map.get("a", "fallback"), "apple");
                map.set("b", "bear");
                testeq(map.length, 2);
                testeq(map.get("a"), "apple");
                testeq(map.get("b"), "bear");
                map.set("a", "alternative");
                testeq(map.length, 2);
                testeq(map.get("a"), "alternative");
                testeq(map.get("b"), "bear");
            }
            tests("Dynamic", {
                auto map = new Map!(string, string, true)(2);
                TestInsertion(map);
                // Should succeed because of automatic upsizing.
                map.set("c", "car");
            });
            tests("Static", {
                auto map = new Map!(string, string, false)(2);
                TestInsertion(map);
                /// Should fail because the map is static and full.
                testfail({map.set("c", "car");});
            });
        });
        tests("Updating", {
            string[string] emptyaa;
            auto map = new Map!(string, string)();
            map.update(emptyaa);
            test(map.empty);
            map.update(["a": "apple", "b": "bear"]);
            testeq(map.length, 2);
            testeq(map.get("a"), "apple");
            testeq(map.get("b"), "bear");
            map.update(emptyaa);
            testeq(map.length, 2);
            map.update(["a": "alternative", "c": "car"]);
            testeq(map.length, 3);
            testeq(map.get("a"), "alternative");
            testeq(map.get("b"), "bear");
            testeq(map.get("c"), "car");
            auto second = new Map!(string, string)();
            second.update(["c": "claw", "d": "drop"]);
            testeq(second.length, 2);
            map.update(second.pairs);
            testeq(map.length, 4);
            testeq(map.get("a"), "alternative");
            testeq(map.get("b"), "bear");
            testeq(map.get("c"), "claw");
            testeq(map.get("d"), "drop");
        });
        tests("Initialization", {
            tests("Empty", {
                string[string] emptyaa;
                auto map = new Map!(string, string)(emptyaa);
                test(map.empty);
            });
            tests("Not empty", {
                auto map = new Map!(string, string)(["a": "apple", "b": "bear"]);
                testf(map.empty);
                testeq(map.length, 2);
                testeq(map.get("a"), "apple");
                testeq(map.get("b"), "bear");
            });
        });
        tests("Contains", {
            auto map = new Map!(string, string)(["a": "apple", "b": "bear"]);
            testnull(map.contains("c"));
            auto a = map.contains("a");
            testeq(a.key, "a");
            testeq(a.value, "apple");
            auto b = map.contains("b");
            testeq(b.key, "b");
            testeq(b.value, "bear");
            test(map.contains("a"));
            testf(map.contains("c"));
        });
        tests("Removal", {
            auto map = new Map!(string, string)(["a": "apple", "b": "bear"]);
            testnull(map.remove("c"));
            testeq(map.length, 2);
            auto a = map.remove("a");
            testeq(a.key, "a");
            testeq(a.value, "apple");
            testeq(map.length, 1);
            auto b = map.remove("b");
            testeq(b.key, "b");
            testeq(b.value, "bear");
            testeq(map.length, 0);
            test(map.empty);
        });
        tests("Clearing", {
            auto map = new Map!(string, string)(["a": "apple", "b": "bear"]);
            testeq(map.length, 2);
            map.clear();
            test(map.empty);
            testeq(map.length, 0);
            testf(map.contains("a"));
            testf(map.contains("b"));
            map.set("a", "apple");
            testf(map.empty);
            testeq(map.length, 1);
            test(map.contains("a"));
        });
        tests("Reserve", {
            tests("Empty", {
                auto map = new Map!(string, string)();
                map.reserve(128);
                testgte(map.size, 128);
            });
            tests("Not empty", {
                auto map = new Map!(string, string)(["a": "apple", "b": "bear"]);
                map.reserve(128);
                testgte(map.size, 128);
            });
        });
        tests("Rehash", {
            // Create and fill a static map.
            auto map = new Map!(string, string, false)(4);
            testeq(map.size, 4);
            map.set("a", "apple");
            map.set("b", "bear");
            map.set("c", "car");
            map.set("d", "drop");
            testeq(map.length, 4);
            testeq(map.density, 1.0);
            test(map.full);
            // Ensure that rehashing causes the map to be upsized to better
            // accommodate its contents.
            map.rehash();
            testgt(map.size, 4);
            test(map.contains("a"));
            test(map.contains("b"));
            test(map.contains("c"));
            test(map.contains("d"));
            testeq(map.length, 4);
            testlt(map.density, 1.0);
            testf(map.full);
        });
        tests("Duplication", {
            tests("Empty", {
                auto a = new Map!(string, string)();
                auto b = a.dup;
                a.set("x", "y");
                b.set("x", "x");
                b.set("z", "w");
                testeq(a.length, 1);
                testeq(b.length, 2);
                testeq(a.get("x"), "y");
                testeq(b.get("x"), "x");
                testeq(b.get("z"), "w");
            });
            tests("Not empty", {
                auto a = new Map!(string, string)(["a": "apple", "b": "bear"]);
                auto b = a.dup;
                a.set("a", "alternative");
                a.set("c", "car");
                b.set("c", "claw");
                testeq(a.length, 3);
                testeq(b.length, 3);
                testeq(a.get("a"), "alternative");
                testeq(a.get("b"), "bear");
                testeq(a.get("c"), "car");
                testeq(b.get("a"), "apple");
                testeq(b.get("b"), "bear");
                testeq(b.get("c"), "claw");
            });
        });
        tests("Immutable elements", {
            void Test(K, V)(){
                K[V] array = [0: 1, 2: 3];
                auto map = new Map!(K, V)(array);
                testeq(map.get(0), 1);
                testeq(map.get(2), 3);
                map.set(4, 5);
                testeq(map.get(4), 5);
                map.set(2, 10);
                testeq(map.get(2), 10);
                testeq(map.remove(0).value, array[0]);
            }
            tests("Immutable keys", {
                Test!(const(int), int)();
            });
            tests("Immutable values", {
                Test!(int, const(int))();
            });
            tests("Immutable keys and values", {
                Test!(const(int), const(int))();
            });
        });
        tests("Hashing", {
            auto array = [0: 1, 2: 3, 4: 5];
            auto a = new Map!(int, int)(10);
            a.update(array);
            auto b = new Map!(int, int)(20);
            b.update(array);
            auto c = new Map!(int, int)();
            auto d = new Map!(int, int)();
            testeq(a.toHash, b.toHash);
            testeq(c.toHash, d.toHash);
            testneq(a.toHash, c.toHash);
        });
        tests("Operators", {
            auto map = new Map!(string, string)(["a": "apple", "b": "bear"]);
            testnull("c" in *map);
            auto a = "a" in *map;
            testeq(a.key, "a");
            testeq(a.value, "apple");
            (*map)["c"] = "car";
            testeq((*map)["b"], "bear");
            testeq((*map)["c"], "car");
        });
        tests("Ranges", {
            tests("Types", {
                auto map = new Map!(string, string)(["key": "value"]);
                auto keys = map.keys;
                auto ikeys = map.ikeys;
                auto values = map.values;
                auto ivalues = map.ivalues;
                auto pairs = map.pairs;
                auto ipairs = map.ipairs;
                testeq(keys.front, "key");
                testeq(ikeys.front, "key");
                testeq(values.front, "value");
                testeq(ivalues.front, "value");
                testeq(pairs.front.key, "key");
                testeq(pairs.front.value, "value");
                testeq(ipairs.front.key, "key");
                testeq(ipairs.front.value, "value");
            });
            tests("Iteration", {
                auto map = new Map!(string, string)(["key": "value"]);
                auto pairs = map.pairs;
                testf(pairs.empty);
                testeq(pairs.length, 1);
                testeq(pairs.remaining, 1);
                testeq(pairs.front.key, "key");
                testeq(pairs.front.value, "value");
                pairs.popFront();
                test(pairs.empty);
                testeq(pairs.length, 1);
                testeq(pairs.remaining, 0);
                testfail({pairs.front;});
                testfail({pairs.popFront();});
            });
            tests("Bidirectionality", {
                int[int] array = [0: 1, 2: 3];
                auto map = new Map!(int, int)(array);
                auto pairs = map.pairs;
                testeq(pairs.length, 2);
                testeq(pairs.remaining, 2);
                test(pairs.front.key in array);
                test(pairs.back.key in array);
                testeq(pairs.front.value, array[pairs.front.key]);
                testeq(pairs.back.value, array[pairs.back.key]);
                test(
                    (pairs.front.key == 0 && pairs.back.key == 2) ||
                    (pairs.front.key == 2 && pairs.back.key == 0)
                );
                pairs.popFront();
                testf(pairs.empty);
                testeq(pairs.remaining, 1);
                testeq(pairs.front.key, pairs.back.key);
                pairs.popBack();
                testeq(pairs.remaining, 0);
                test(pairs.empty);
                testfail({pairs.front;});
                testfail({pairs.popFront();});
                testfail({pairs.back;});
                testfail({pairs.popBack();});
            });
            tests("Immutable elements", {
                auto map = new Map!(const(int), const(int))([0: 1, 2: 3]);
                foreach(key, value; map.pairs){
                    testeq(key + 1, value);
                }
                foreach(key, value; map.ipairs){
                    testeq(key + 1, value);
                }
            });
            tests("Removal", {
                auto map = new Map!(string, string)(
                    ["a": "apple", "b": "bear", "c": "car"]
                );
                auto pairs = map.pairs;
                testeq(pairs.length, 3);
                testeq(pairs.remaining, 3);
                // Remove first key
                auto key0 = pairs.front.key;
                test(map.contains(key0));
                pairs.removeFront();
                testeq(map.length, 2);
                testf(map.contains(key0));
                testeq(pairs.length, 2);
                testeq(pairs.remaining, 2);
                // Remove second key
                auto key1 = pairs.back.key;
                test(map.contains(key1));
                pairs.removeBack();
                testeq(map.length, 1);
                testf(map.contains(key1));
                testeq(pairs.length, 1);
                testeq(pairs.remaining, 1);
                // Pop final key
                pairs.popFront();
                testeq(map.length, 1);
                test(pairs.empty);
                testeq(pairs.length, 1);
                testeq(pairs.remaining, 0);
                // Verify final state
                testfail({pairs.removeFront();});
                testfail({pairs.removeBack();});
                testeq(pairs.length, 1);
            });
            tests("Filter", {
                auto map = new Map!(string, string)(
                    ["a": "apple", "b": "bear", "c": "car"]
                );
                auto a = map.filter!(e => e.key == "a");
                testeq(a.front.key, "a");
                testeq(a.front.value, "apple");
                a.popFront();
                test(a.empty);
                auto d = map.filter!(e => e.key == "d");
                test(d.empty);
            });
        });
    });
}
