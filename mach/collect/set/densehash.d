module mach.collect.set.densehash;

private:

import mach.collect.set.templates;
import mach.traits : isIterable, isIterableOf, ElementType;
import mach.traits : hasNumericLength, hash, canHash, Unqual;
import mach.math.log2 : clog2;

public:



/// Get the contents of some iterable as a set.
auto asdensehashset(bool dynamic = true, Iter)(auto ref Iter iter) if(
    isIterable!Iter
){
    return DenseHashSet!(ElementType!Iter, dynamic)(iter);
}



struct DenseHashSetBucket(T){
    Unqual!T rawvalue = void;
    bool empty = true;
    @property T value() const{
        return cast(T) this.rawvalue;
    }
    @property void value(T value){
        this.rawvalue = cast(Unqual!T) value;
        this.empty = false;
    }
}



/// Implementation for a Set type.
/// When dynamic is true, the set automatically resizes up and down to
/// accommodate usage. Otherwise an error is produced if too many values are
/// added to the set. Static sets can still be resized, but unlike dynamic sets
/// they will not be resized automatically.
/// upsize_factor, downsize_factor, upsize_at, downsize_at define the behavior
/// of dynamically-sized sets.
struct DenseHashSet(
    T, bool dynamic = true,
    real upsize_factor = 2.0, real downsize_factor = 0.5,
    real upsize_at = 0.75, real downsize_at = 0.25
){
    alias Element = T;
    
    static assert(upsize_factor > 1);
    static assert(downsize_factor < 1);
    static assert(upsize_at <= 1);
    static assert(downsize_at >= 0);
    static assert(upsize_at > downsize_at);
    
    mixin SetMixin!T;
    
    alias Hash = typeof(T.init.hash);
    alias Range = DenseHashSetRange!T;
    alias Bucket = DenseHashSetBucket!T;
    alias Buckets = Bucket[];
    static enum size_t DefaultSize = 64;
    static enum size_t MinDynamicSize = 64;
    
    static if(!is(typeof({
        auto x(T[] values...){}
        size_t i; x(i);
    }))){
        this(in size_t size){
            this.resize_unsafe(size);
        }
    }
    this(Values)(auto ref Values values) if(isIterableOf!(Values, T)){
        static if(hasNumericLength!Values){
            this.resize_unsafe(this.suggestsize(values.length));
        }else{
            this(this.DefaultSize);
        }
        this.add(values);
    }
    this(T[] values...){
        this.resize_unsafe(this.suggestsize(values.length));
        this.add(values);
    }
    
    static auto ofsize(in size_t size){
        typeof(this) set;
        set.resize_unsafe(size);
        return set;
    }
    
    static auto expectedlength(in size_t length){
        return typeof(this).ofsize(typeof(this).suggestsize(length));
    }
    static size_t suggestsize(in size_t length, size_t line = __LINE__){
        auto size = cast(size_t)(length * upsize_factor);
        static if(dynamic){
            if(size < MinDynamicSize) size = MinDynamicSize;
        }
        return size <= 0 ? 0 : 1 << clog2(size);
    }
    
    Buckets buckets = null;
    size_t values = 0;
    
    @property size_t length() pure @safe const nothrow{
        return this.values;
    }
    @property bool empty() pure @safe const nothrow{
        return (this.buckets is null) | (this.values == 0);
    }
    
    /// Return true when the set's backing array is full, false otherwise.
    @property bool full() const{
        return this.values == this.size;
    }
    /// Return a measurement of how full the backing array is, 0 for completely
    /// empty and 1 for completely full.
    @property real density() const{
        return (cast(real) this.values) / this.size;
    }
    
    @property auto size() const{
        return this.buckets is null ? DefaultSize : this.buckets.length;
    }
    @property void size(in size_t size){
        this.resize(size);
    }
    void reserve(in size_t size){
        if(this.buckets is null || size > this.buckets.length){
            this.resize(size);
        }
    }
    void resize(in size_t size){
        if(this.buckets is null || size != this.buckets.length){
            if(this.empty){
                this.resize_unsafe(size);
            }else{
                this.rehash(size);
            }
        }
    }
    /// Resize the set's backing array. Also clears the set.
    void resize_unsafe(in size_t size){
        this.buckets = new Bucket[size];
        this.values = 0;
    }
    /// Resize the set's backing array, but preserve the values in the set.
    void rehash(in size_t size){
        Buckets newbuckets = new Bucket[size];
        foreach(value; this){
            this.addin(newbuckets, value);
        }
        this.buckets = newbuckets;
    }
    
    static bool addin(Buckets buckets, T value) in{
        assert(buckets !is null && buckets.length);
    }body{
        auto bucket = typeof(this).getbucketin(buckets, value);
        assert(bucket !is null);
        if(bucket.empty){
            bucket.value = value;
            return true;
        }else{
            assert(bucket.value == value);
            return false;
        }
    }
    static bool removein(Buckets buckets, T value) in{
        assert(buckets !is null && buckets.length);
    }body{
        auto bucket = typeof(this).getbucketin(buckets, value);
        if(bucket !is null && !bucket.empty && bucket.value == value){
            bucket.empty = true;
            return true;
        }else{
            return false;
        }
    }
    static Bucket* getbucketin(Buckets buckets, T value) in{
        assert(buckets !is null && buckets.length);
    }body{
        auto startindex = (cast(size_t) value.hash) % buckets.length;
        auto index = startindex;
        while(!buckets[index].empty && buckets[index].value != value){
            index = index == 0 ? buckets.length - 1 : index - 1;
            if(index == startindex) return null;
        }
        return &buckets[index];
    }
    
    bool containsvalue(T value){
        if(!this.empty){
            auto bucket = this.getbucketin(this.buckets, value);
            return bucket !is null && !bucket.empty && bucket.value == value;
        }else{
            return false;
        }
    }
    
    bool addvalue(T value) in{
        static if(!dynamic){
            assert(!this.full, "Can't add value because the set is already full.");
        }
    }body{
        static if(dynamic){
            if(this.density >= upsize_at){
                this.resize(cast(size_t)(this.size * upsize_factor));
                assert(!this.full);
            }
        }
        if(this.buckets is null) this.resize_unsafe(this.DefaultSize);
        if(this.addin(this.buckets, value)){
            this.values++;
            return true;
        }else{
            return false;
        }
    }
    
    bool removevalue(T value){
        if(this.buckets !is null && this.removein(this.buckets, value)){
            this.values--;
            static if(dynamic){
                if(this.density <= downsize_at){
                    auto size = cast(size_t)(this.size * downsize_factor);
                    if(size >= this.MinDynamicSize) this.resize(size);
                }
            }
            return true;
        }else{
            return false;
        }
    }
    
    T pop() in{
        assert(!this.empty, "Cannot pop value from empty set.");
    }body{
        static size_t popindex = 0;
        static if(dynamic){
            // Account for resizing
            if(popindex >= this.size) popindex = 0;
        }
        auto startindex = popindex;
        do{
            auto bucket = &this.buckets[popindex];
            if(!bucket.empty){
                bucket.empty = true;
                this.values--;
                return bucket.value;
            }
            popindex++;
            if(popindex >= this.size) popindex = 0;
        }while(popindex != startindex);
        assert(false);
    }
    
    void clear(){
        this.buckets = new Bucket[this.size];
        this.values = 0;
    }
    
    @property typeof(this) dup(){
        return typeof(this)(this);
    }
    
    Hash toHash() @safe const nothrow{
        Hash hash = cast(Hash) this.length;
        foreach(bucket; this.buckets){
            if(!bucket.empty) hash ^= bucket.value.hash;
        }
        return hash;
    }
    
    auto asrange() const{ // TODO: Also a mutable range? May not be practical considering rehashes
        return Range(this);
    }
    
    // TODO: god dammit opApply stop being so dumb
    int opApply(in int delegate(in ref T value) apply) const{
        if(!this.empty){
            for(size_t index = 0; index < this.size; index++){
                if(!this.buckets[index].empty){
                    auto value = this.buckets[index].value;
                    if(auto result = apply(value)) return result;
                }
            }
        }
        return 0;
    }
}



/// Range type for iterating over a DenseHashSet object.
struct DenseHashSetRange(T){
    alias Set = const(DenseHashSet!T);
    
    Set source;
    size_t frontindex;
    size_t backindex;
    bool empty;
    
    this(Set)(Set source){
        this(source, 0, source.size, source.empty);
        if(!this.empty){
            this.nextFront();
            this.nextBack();
        }
    }
    this(Set)(Set source, size_t frontindex, size_t backindex, bool empty){
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
        this.empty = empty;
    }
    
    @property auto length(){
        return this.source.length;
    }
    
    @property auto frontbucket() const in{assert(!this.empty);} body{
        return this.source.buckets[this.frontindex];
    }
    @property auto front() const in{assert(!this.empty);} body{
        return this.frontbucket.value;
    }
    @property auto backbucket() const in{assert(!this.empty);} body{
        return this.source.buckets[this.backindex - 1];
    }
    @property auto back() const in{assert(!this.empty);} body{
        return this.backbucket.value;
    }
    
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
        this.nextFront();
        this.empty = this.frontindex >= this.backindex;
    }
    void nextFront(){
        while(
            this.frontindex < this.backindex &&
            this.source.buckets[this.frontindex].empty
        ){
            this.frontindex++;
        }
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
        this.nextBack();
        this.empty = this.frontindex >= this.backindex;
    }
    void nextBack(){
        while(
            this.frontindex < this.backindex &&
            this.source.buckets[this.backindex - 1].empty
        ){
            this.backindex--;
        }
    }
    
    @property typeof(this) save(){
        return typeof(this)(
            cast(Set) this.source, this.frontindex, this.backindex, this.empty
        );
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.traits : isRange;
}
unittest{
    tests("DenseHashSet", {
        alias Set = DenseHashSet;
        static assert(isIterableOf!(Set!int, int));
        tests("Contains", {
            tests("Empty set", {
                Set!int set;
                testf(0 in set);
            });
            tests("Not empty", {
                auto set = Set!int(0, 1, 2);
                test(0 in set);
                test(1 in set);
                test(2 in set);
                testf(3 in set);
                testf(4 in set);
            });
        });
        tests("Add", {
            Set!int set;
            testf(0 in set);
            testf(1 in set);
            testf(2 in set);
            testf(3 in set);
            test(set.add(0));
            test(0 in set);
            testf(set.add(0));
            testeq(set.add(1, 2), 2);
            test(1 in set);
            test(2 in set);
            testeq(set.add([2, 3]), 1);
            test(2 in set);
            test(3 in set);
            testeq(set.add(0, 1, 2), 0);
        });
        tests("Remove", {
            auto set = Set!int(0, 1, 2);
            test(set.remove(0));
            testf(0 in set);
            testf(set.remove(0));
            test(1 in set);
            testeq(set.remove(2, 3), 1);
            testf(2 in set);
            test(1 in set);
            testeq(set.remove([2, 3, 4]), 0);
        });
        tests("Length", {
            Set!int a;
            testeq(a.length, 0);
            Set!int b = Set!int(1);
            testeq(b.length, 1);
            Set!int c = Set!int(1, 2);
            testeq(c.length, 2);
            c.add(3);
            testeq(c.length, 3);
            c.add(3);
            testeq(c.length, 3);
            c.remove(1);
            testeq(c.length, 2);
            c.remove(1);
            testeq(c.length, 2);
        });
        tests("Pop", {
            tests("Empty set", {
                Set!int set;
                testfail({set.pop;});
            });
            tests("Not empty", {
                auto a = Set!int(0, 1, 2);
                auto b = Set!int(0, 1, 2);
                test(b.remove(a.pop));
                test(b.remove(a.pop));
                test(b.remove(a.pop));
                test(a.empty);
                test(b.empty);
            });
        });
        tests("Equality", {
            tests("To sets", {
                testeq(Set!int.init, Set!int.init);
                testeq(Set!int(0), Set!int(0));
                testeq(Set!int(0, 1, 2), Set!int([0, 1, 2]));
                testeq(Set!int(0, 1, 2), Set!int(2, 1, 0));
                testneq(Set!int.init, Set!int(0));
                testneq(Set!int(0), Set!int(0, 1));
            });
            tests("To arrays", {
                testeq(Set!int.init, new int[0]);
                testeq(Set!int(0), [0]);
                testeq(Set!int(0, 1), [0, 1]);
                testeq(Set!int(0, 1), [1, 0]);
                testneq(Set!int(0), new int[0]);
                testneq(Set!int.init, [0]);
                testneq(Set!int(0), [0, 1]);
                testneq(Set!int(0, 1), [0]);
            });
        });
        tests("Clear", {
            tests("Empty set", {
                Set!int set;
                set.clear;
                test(set.empty);
                testeq(set.length, 0);
            });
            tests("Not empty", {
                auto set = Set!int(0, 1, 2);
                set.clear;
                test(set.empty);
                testeq(set.length, 0);
                testf(0 in set);
            });
        });
        tests("As array", {
            tests("Empty set", {
                Set!int set;
                testeq(set.asarray, new int[0]);
            });
            tests("Not empty", {
                auto set = Set!int(0, 1, 2);
                testeq(set.asarray, [0, 1, 2]);
            });
        });
        tests("As range", {
            tests("Empty set", {
                Set!int set;
                auto range = set.asrange;
                test(range.empty);
            });
            tests("Not empty", {
                Set!int a = Set!int(0, 1, 2);
                Set!int b;
                auto range = a.asrange;
                static assert(isRange!(typeof(range)));
                testf(range.empty);
                testeq(range.length, 3);
                foreach(value; range){
                    test(value in a);
                    test(b.add(value));
                }
                testeq(a, b);
            });
        });
        tests("Hashing", {
            testeq(Set!int.init.hash, Set!int.init.hash);
            testeq(Set!int(0, 1, 2).hash, Set!int(0, 1, 2).hash);
            testeq(Set!int(0, 1, 2).hash, Set!int(2, 1, 0).hash);
            testeq(Set!string("abc", "def", "xyz").hash, Set!string("xyz", "abc", "def").hash);
        });
        tests("Copying", {
            auto a = Set!int(0, 1, 2);
            auto b = a.dup;
            a.add(3);
            b.remove(0);
            testeq(a.length, 4);
            testeq(b.length, 2);
            test(0 in a);
            test(0 !in b);
            test(3 in a);
            test(3 !in b);
        });
        tests("As set", {
            auto set = asdensehashset([0, 1, 2]);
            testeq(set.length, 3);
            test(0 in set);
            test(1 in set);
            test(2 in set);
            testf(3 in set);
        });
        tests("Static", {
            Set!(int, false) set;
            set.reserve(4);
            testeq(set.length, 0);
            testeq(set.add(0, 1, 2, 3), 4);
            testeq(set.length, 4);
            testfail({set.add(4);});
            testeq(set.length, 4);
            test(set.remove(0));
            test(set.add(4));
            testfail({set.add(5);});
        });
        tests("Strings", {
            Set!string set;
            set.add("hello");
            set.add("world");
            test("hello" in set);
            test("world" in set);
            testf("yo" in set);
        });
        tests("Stress", {
            Set!int set;
            foreach(value; 0 .. 500){
                test(set.add(value * 4));
            }
            foreach(value; 0 .. 500){
                test(value * 4 in set);
                testf(value * 4 + 1 in set);
                testf(value * 4 - 1 in set);
            }
        });
    });
}
