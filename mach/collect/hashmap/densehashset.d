module mach.collect.hashmap.densehashset;

private:

import mach.types : Value;
import mach.traits : isFiniteIterable, ElementType, isTemplateOf;
import mach.traits : hasNumericLength, hasNumericRemaining, hash, canHash;
import mach.collect.hashmap.densehashcommon;
import mach.collect.hashmap.exceptions;

// TODO: Put this in mach.traits and use where appropriate
// e.g. for DoublyLinkedList
template isFiniteIterableOf(Of, T){
    enum bool isFiniteIterableOf = isFiniteIterable!T && is(typeof({
        void fn(Of x){}
        foreach(x; T.init) fn(x);
    }));
}

public:



/// Get the contents of an associative array as a DenseHashSet.
auto asdensehashset(bool dynamic = true, T)(auto ref T values) if(
    isFiniteIterable!T
){
    return DenseHashSet!(ElementType!T, dynamic)(values);
}



template StaticDenseHashSet(K){
    alias StaticDenseHashSet = DenseHashSet!(K, false);
}

template DynamicDenseHashSet(K){
    alias DynamicDenseHashSet = DenseHashSet!(K, true);
}

/// Implementation for a HashSet type.
/// When dynamic is true, the set automatically resizes up and down to
/// accommodate usage. Otherwise an error is produced if too many values are
/// added to the set. Static maps can still be resized, but unlike dynamic maps
/// they will not be resized automatically upon insertion or removal.
struct DenseHashSet(
    K, bool Dynamic = true
) if(canHash!K){
    alias Bucket = Value!K;
    mixin DenseHashFieldsMixin!();
    mixin DenseHashMethodsMixin!();
    
    /// Disallow blitting.
    @disable this(this);
    
    /// Create a set, specifying its initial size.
    this(in size_t size){
        this.setsize(size);
    }
    
    /// Create a set, specifying its initial content.
    this(T)(auto ref T values) if(
        isFiniteIterableOf!(K, T) && (
            dynamic || hasNumericLength!T || hasNumericRemaining!T
        )
    ){
        static if(hasNumericRemaining!T){
            this.setsize(this.suggestsize(values.remaining));
        }else static if(hasNumericLength!T){
            this.setsize(this.suggestsize(values.length));
        }
        this.add(values);
    }
    
    /// Used to genericize some code in `DenseHashMethodsMixin`.
    private static auto getbucketkey(in Bucket* bucket){
        return bucket.value;
    }
    
    /// Adds a key to the map if it was not already present.
    /// If the key was already present, returns a reference to the bucket
    /// containing that key.
    /// If the key was present and has been newly added, returns null.
    /// Throws a `DenseHashMapFullError` if the operation fails because the
    /// map was full and could not be automatically resized.
    auto add(K key){
        this.autoupsize();
        auto result = getbucketin(buckets, key);
        if(result.exists){
            auto prior = this.buckets[result.index];
            if(prior is null){
                this.buckets[result.index] = new Bucket(key);
                this.numvalues++;
            }
            return prior;
        }else{
            throw new DenseHashMapFullError();
        }
    }
    
    /// Adds keys to the map if they were not already present.
    /// Throws a `DenseHashMapFullError` if the operation fails because the
    /// map was full and could not be automatically resized.
    auto add(T)(auto ref T values) if(isFiniteIterableOf!(K, T)){
        foreach(value; values) this.add(value);
    }
    
    /// When `value` is true, adds the key if not present.
    /// When `value` is false, removes the key if present.
    auto set(K key, bool value){
        if(value) this.add(key);
        else this.remove(key);
    }
    
    /// Get a reference to a shallow copy of the map.
    @property typeof(this)* dup(){
        if(this.empty){
            // Get a new map of the same size and with the same empty contents.
            return new typeof(this)(this.size);
        }else{
            static if(dynamic){
                // Get a new map with the same contents, but size may differ.
                return new typeof(this)(this.values);
            }else{
                // Get a new map with the same contents and the same size.
                auto copy = new typeof(this)(this.size);
                copy.add(this.values);
                return copy;
            }
        }
    }
    
    /// Get a hash of the map, which is a function of the hashes of all keys
    /// in the map.
    size_t toHash() @safe const nothrow{
        size_t maphash = (
            this.length << (size_t.sizeof * 4) |
            this.length >> (size_t.sizeof * 4)
        );
        foreach(bucket; this.buckets){
            if(bucket !is null){
                maphash ^= hash(bucket.value);
            }
        }
        return maphash;
    }
    
    /// Returns a range for enumerating values in the map, in arbitrary order.
    /// The resulting range does not allow modification.
    auto ivalues() const{
        return DenseHashSetRange!(
            typeof(this), DenseHashRangeMutability.Immutable
        )(&this);
    }
    /// Returns a range for enumerating values in the map, in arbitrary order.
    /// The resulting range allows removal of its elements.
    auto values(){
        return DenseHashSetRange!(
            typeof(this), DenseHashRangeMutability.Removable
        )(&this);
    }
    
    /// Make the map valid as a range.
    @property auto asrange(){
        return this.values;
    }
    /// ditto
    @property auto asrange() const{
        return this.ivalues;
    }
    
    auto opBinaryRight(string op: "in")(K key){
        return this.contains(key);
    }
    auto opIndex(K key){
        return this.contains(key);
    }
    auto opIndexAssign(bool set, K key){
        this.set(key, set);
    }
}



/// Range for iterating over a `DenseHashSet` instance.
struct DenseHashSetRange(
    Source, DenseHashRangeMutability mutability
) if(
    isTemplateOf!(Source, DenseHashSet)
){
    mixin DenseHashRangeMixin!();
    
    /// Get the front of the range.
    @property auto front() const in{
        assert(this.source !is null, "Range is not valid.");
        assert(!this.empty, "Range is empty.");
    }body{
        return this.frontbucket.value;
    }
    /// Get the back of the range.
    @property auto back() const in{
        assert(this.source !is null, "Range is not valid.");
        assert(!this.empty, "Range is empty.");
    }body{
        return this.backbucket.value;
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.filter : filter;
    import mach.range.compare : equals;
}
unittest{
    tests("DenseHashSet", {
        alias Set = DenseHashSet;
        tests("Empty", {
            auto set = new Set!string();
            test(set.empty);
            testf(set.full);
            testeq(set.length, 0);
            testeq(set.density, 0);
            testf(set.contains("hello"));
            testf(set.remove("hello"));
            foreach(e; set.values) assert(false);
            foreach(e; set.ivalues) assert(false);
            set.clear();
        });
        tests("Addition", {
            auto set = new Set!int();
            auto prior = set.add(0);
            testnull(prior);
            testf(set.empty);
            testeq(set.length, 1);
            prior = set.add(0);
            testeq(prior.value, 0);
            testeq(set.length, 1);
            prior = set.add(1);
            testnull(prior);
            testeq(set.length, 2);
            prior = set.add(1);
            testeq(prior.value, 1);
            testeq(set.length, 2);
        });
        tests("Removal", {
            auto set = new Set!int();
            set.add(0);
            testnull(set.remove(1));
            testeq(set.remove(0).value, 0);
            test(set.empty);
            testeq(set.length, 0);
            set.add(1);
            set.add(2);
            testeq(set.length, 2);
            testnull(set.remove(0));
            testeq(set.length, 2);
            testeq(set.remove(1).value, 1);
            testeq(set.length, 1);
            testeq(set.remove(2).value, 2);
            testeq(set.length, 0);
            test(set.empty);
        });
        tests("Contains", {
            auto set = new Set!int();
            testnull(set.contains(0));
            set.add(0);
            testeq(set.contains(0).value, 0);
            testnull(set.contains(1));
            set.remove(0);
            testnull(set.contains(0));
        });
        tests("Add, Remove, and Contains", {
            void TestSet(T)(T set){
                // Add 0
                testf(set.add(0));
                testf(set.empty);
                testeq(set.length, 1);
                test(set.contains(0));
                // Remove 0
                test(set.remove(0));
                test(set.empty);
                testeq(set.length, 0);
                testf(set.contains(0));
                // Remove 0 (again)
                testf(set.remove(0));
                test(set.empty);
                testeq(set.length, 0);
                // Add 1
                testf(set.add(1));
                testf(set.empty);
                testeq(set.length, 1);
                test(set.contains(1));
                // Add 1 (again)
                test(set.add(1));
                testeq(set.length, 1);
                test(set.contains(1));
                // Add 2
                testf(set.add(2));
                testeq(set.length, 2);
                test(set.contains(1));
                test(set.contains(2));
                // Add 2 (again)
                test(set.add(2));
                testeq(set.length, 2);
                // Remove 3 (not in the set)
                testf(set.remove(3));
                testeq(set.length, 2);
            }
            tests("Dynamic", {
                auto set = new Set!(int, true)(2);
                TestSet(set);
                // Should succeed because of automatic upsizing.
                set.add(3);
            });
            tests("Static", {
                auto set = new Set!(int, false)(2);
                TestSet(set);
                /// Should fail because the map is static and full.
                testfail({set.add(3);});
            });
        });
        tests("Add multiple", {
            auto set = new Set!int();
            set.add(new int[0]);
            testeq(set.length, 0);
            set.add([0, 1, 2]);
            testeq(set.length, 3);
            set.add([2, 3, 4]);
            testeq(set.length, 5);
            set.add(new int[0]);
            testeq(set.length, 5);
        });
        tests("Initialization", {
            tests("Empty", {
                auto set = new Set!int(new int[0]);
                test(set.empty);
            });
            tests("Not empty", {
                auto set = new Set!int([0, 1, 2]);
                testf(set.empty);
                testeq(set.length, 3);
                test(set.contains(0));
                test(set.contains(1));
                test(set.contains(2));
            });
        });
        tests("Clearing", {
            auto set = new Set!int([0, 1, 2]);
            testeq(set.length, 3);
            set.clear();
            test(set.empty);
            testeq(set.length, 0);
            testf(set.contains(0));
            testf(set.contains(1));
            testf(set.contains(2));
            set.add(0);
            testf(set.empty);
            testeq(set.length, 1);
            test(set.contains(0));
        });
        tests("Reserve", {
            tests("Empty", {
                auto set = new Set!int();
                set.reserve(128);
                testgte(set.size, 128);
            });
            tests("Not empty", {
                auto set = new Set!int([0, 1, 2]);
                set.reserve(128);
                testgte(set.size, 128);
            });
        });
        tests("Rehash", {
            // Create and fill a static map.
            auto set = new Set!(int, false)(4);
            testeq(set.size, 4);
            set.add([0, 1, 2, 3]);
            testeq(set.length, 4);
            testeq(set.density, 1.0);
            test(set.full);
            // Ensure that rehashing causes the map to be upsized to better
            // accommodate its contents.
            set.rehash();
            testgt(set.size, 4);
            test(set.contains(0));
            test(set.contains(1));
            test(set.contains(2));
            test(set.contains(3));
            testeq(set.length, 4);
            testlt(set.density, 1.0);
            testf(set.full);
        });
        tests("Duplication", {
            tests("Empty", {
                auto a = new Set!int();
                auto b = a.dup;
                a.add(0);
                b.add(1);
                b.add(2);
                testeq(a.length, 1);
                testeq(b.length, 2);
                test(a.contains(0));
                testf(a.contains(1));
                testf(a.contains(2));
                testf(b.contains(0));
                test(b.contains(1));
                test(b.contains(2));
            });
            tests("Not empty", {
                auto a = new Set!int([0, 1, 2]);
                auto b = a.dup;
                a.add(3);
                b.remove(0);
                testeq(a.length, 4);
                testeq(b.length, 2);
                test(a.contains(3));
                testf(b.contains(3));
                test(a.contains(0));
                testf(b.contains(0));
            });
        });
        tests("Immutable elements", {
            auto set = new Set!(const(int))([0, 1, 2]);
            testeq(set.length, 3);
            test(set.add(0));
            testf(set.add(3));
            testeq(set.length, 4);
            test(set.remove(1));
            testf(set.remove(1));
            testeq(set.length, 3);
        });
        tests("Hashing", {
            auto a = new Set!int([0, 1, 2]);
            auto b = new Set!int([2, 1, 0]);
            auto c = new Set!int();
            auto d = new Set!int();
            testeq(a.toHash, b.toHash);
            testeq(c.toHash, d.toHash);
            testneq(a.toHash, c.toHash);
        });
        tests("Operators", {
            auto a = new Set!int([0, 1, 2]);
            testnull(3 in *a);
            testeq((0 in *a).value, 0);
            (*a)[0] = false;
            (*a)[3] = true;
            test((*a)[3]);
            testf((*a)[0]);
        });
        tests("Ranges", {
            tests("Iteration", {
                auto set = new Set!int([0, 1, 2]);
                void TestRange(T)(auto ref T range){
                    testeq(range.length, 3);
                    testeq(range.remaining, 3);
                    test(set.contains(range.front));
                    range.popFront();
                    testeq(range.length, 3);
                    testeq(range.remaining, 2);
                    test(set.contains(range.front));
                    range.popFront();
                    testeq(range.length, 3);
                    testeq(range.remaining, 1);
                    test(set.contains(range.front));
                    range.popFront();
                    testeq(range.length, 3);
                    testeq(range.remaining, 0);
                    testfail({auto x = range.front;});
                    testfail({range.popFront();});
                }
                tests("Mutable", {
                    TestRange(set.values);
                });
                tests("Immutable", {
                    TestRange(set.ivalues);
                });
            });
            tests("Bidirectionality", {
                auto set = new Set!int([0, 1]);
                auto range = set.values;
                testeq(range.length, 2);
                testeq(range.remaining, 2);
                test(
                    (range.front == 0 && range.back == 1) ||
                    (range.front == 1 && range.back == 0)
                );
                range.popFront();
                testf(range.empty);
                testeq(range.remaining, 1);
                testeq(range.front, range.back);
                range.popBack();
                test(range.empty);
                testeq(range.remaining, 0);
                testfail({auto x = range.front;});
                testfail({auto x = range.back;});
                testfail({range.popFront();});
                testfail({range.popBack();});
            });
            tests("Removal", {
                auto set = new Set!int([0, 1, 2]);
                auto range = set.values;
                testeq(range.length, 3);
                testeq(range.remaining, 3);
                // Remove first key
                auto key0 = range.front;
                test(set.contains(key0));
                range.removeFront();
                testeq(set.length, 2);
                testf(set.contains(key0));
                testeq(range.length, 2);
                testeq(range.remaining, 2);
                // Remove second key
                auto key1 = range.back;
                test(set.contains(key1));
                range.removeBack();
                testeq(set.length, 1);
                testf(set.contains(key1));
                testeq(range.length, 1);
                testeq(range.remaining, 1);
                // Pop final key
                range.popFront();
                testeq(set.length, 1);
                test(range.empty);
                testeq(range.length, 1);
                testeq(range.remaining, 0);
                // Verify final state
                testfail({range.removeFront();});
                testfail({range.removeBack();});
                testeq(range.length, 1);
            });
            tests("Filter", {
                auto set = new Set!int([0, 1, 2, 3]);
                test!equals(set.filter!(e => e == 0), [0]);
                test!equals(set.filter!(e => e == 1), [1]);
                test(set.filter!(e => e == 4).empty);
            });
        });
    });
}
