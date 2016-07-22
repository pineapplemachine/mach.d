module mach.range.cache;

public:

import mach.traits : ElementType, hasNumericLength, isSlicingRange;
import mach.range.meta : MetaRangeMixin;
import mach.range.asrange : asrange, validAsRange;

private:



alias DefaultCacheIndex = size_t;



/// Creates a range which accesses the front of the source iterable only once
/// and will store the most recent values for retrieval, by default just one.
/// This may be useful for ranges whose fronts are expensive to evaluate and so
/// should not be evaluated multiple times, or for ranges that are transient in
/// that evaluating the front of the range also consumes it.
auto cache(Iter, Index = DefaultCacheIndex)(auto ref Iter iter, Index size = 1) in{
    assert(size > 0);
}body{
    auto range = iter.asrange;
    return CacheRange!(typeof(range), Index)(range, size);
}



/// Used internally by the CacheRange type to store and access values taken from
/// its source range.
struct Cache(Element, Index = DefaultCacheIndex){
    alias Array = Element[];
    
    Index count; /// Number of elements that have been added to the cache.
    Array array; /// Backing array, contains elements known to the cache.
    
    /// Construct a cache of a given size.
    this(Index size) in{
        assert(size > 0);
    }body{
        this(0, new Element[size]);
    }
    this(Index count, Array array){
        this.count = count;
        this.array = array;
    }
    
    /// Maximum number of elements the cache can hold.
    @property Index size() const{
        return cast(Index) this.array.length;
    }
    /// Number of elements that are currently in the cache.
    @property Index length() const{
        return this.count < this.size ? this.count : this.size;
    }
    /// ditto
    alias opDollar = length;
    /// True when the cache has no values in it.
    @property bool empty() const{
        return this.count == 0;
    }
    
    /// Empty the cache of values.
    void clear(){
        this.count = 0;
    }
    
    /// Get a copy of the cache object.
    @property typeof(this) dup(){
        return typeof(this)(this.count, this.array[]);
    }
    
    /// Add a new element to the cache. (And cycle out the oldest one, if the
    /// cache size has been met.)
    void add(Element element){
        this.array[(this.count++) % this.array.length] = element;
    }
    /// Get an element, where 0 is the most recent and length-1 is the oldest.
    auto get(in Index offset) in{
        assert(offset >= 0 && offset < this.length);
    }body{
        return this.array[this.index(offset)];
    }
    /// ditto
    auto opIndex(in Index offset){
        return this.get(offset);
    }
    
    /// Get the index of the latest value in the backing array.
    @property Index latestindex() const in{assert(!this.empty);} body{
        return (this.count - 1) % this.size;
    }
    /// Get the index of the oldest value in the backing array.
    @property Index oldestindex() const in{assert(!this.empty);} body{
        if(this.count > this.size){
            return (this.latestindex + 1) % this.size;
        }else{
            return 0;
        }
    }
    
    /// Transform an offset from most recent to an index in the backing array.
    Index index(in Index offset) const in{
        assert(offset >= 0 && offset < this.length);
    }body{
        auto current = this.latestindex;
        if(offset <= current) return current - offset;
        else return (current + this.size) - offset;
    }
    
    /// Get the latest value in the cache.
    @property auto latest() in{assert(!this.empty);} body{
        return this.array[this.latestindex];
    }
    /// Get the oldest value in the cache.
    @property auto oldest() in{assert(!this.empty);} body{
        return this.array[this.oldestindex];
    }
    
    /// Get the cache object as a range that can be iterated over.
    @property auto asrange(){
        import mach.range.asrange : asindexrange;
        return this.asindexrange;
    }
}



struct CacheRange(Range, Index = DefaultCacheIndex){
    alias Cache = .Cache!(ElementType!Range, Index);
    
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Length Dollar`
    );
    
    Range source;
    Cache cache;
    
    this(Range source, Index size = 1){
        this(source, Cache(size));
        this.cacheFront();
    }
    this(Range source, Cache cache){
        this.source = source;
        this.cache = cache;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this.cache.latest;
    }
    void popFront() in{assert(!this.empty);} body{
        this.source.popFront();
        if(!this.source.empty) this.cacheFront();
    }
    void cacheFront() in{assert(!this.empty);} body{
        this.cache.add(this.source.front);
    }
    
    /// Get the most recent value in the cache. In the majority of cases, a call
    /// to latest will behave the same as a call to front. But where front will
    /// fail when the range is empty, this will only fail when the cache is
    /// empty. Practically speaking, that should be never.
    @property auto latest() in{assert(!this.cache.empty);} body{
        return this.cache.latest;
    }
    /// Get the oldest value in the cache.
    @property auto oldest() in{assert(!this.cache.empty);} body{
        return this.cache.oldest;
    }
    /// Get a value from the cache, where 0 is the most recent and cache.length-1
    /// is the oldest.
    @property auto get(Index index) in{
        assert(index >= 0 && index < this.cache.length);
    }body{
        return this.cache.get(index);
    }
    
    static if(isSlicingRange!Range){
        typeof(this) opSlice(size_t low, size_t high) in{
            assert(low >= 0 && high >= low);
            static if(hasNumericLength!(typeof(this))) assert(high < this.length);
        }body{
            return typeof(this)(this.source[low .. high], this.cache.size);
        }
    }
    
    @property typeof(this) save(){
        return typeof(this)(this.source, this.cache.dup);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    /// Raise an AssertError if you attempt to access the front element more
    /// than once before popping; this helps make sure cache only ever accesses
    /// the front element once.
    struct TrickyRange{
        bool accessed = false;
        enum bool empty = false;
        void popFront(){this.accessed = false;}
        @property auto ref front(){
            assert(!this.accessed, "Cache accessed front element twice.");
            this.accessed = true; return 0;
        }
    }
}
unittest{
    tests("Cache", {
        import std.stdio;
        import mach.range.ends : head;
        tests("Internal cache data", {
            auto cache = Cache!int(3);
            testeq(cache.length, 0);
            testeq(cache.size, 3);
            for(int i = 1; i <= cache.size; i++){
                cache.add(i);
                testeq(cache.length, i);
                testeq(cache.latest, i);
                testeq(cache.oldest, 1);
            }
            testeq(cache[0], 3);
            testeq(cache[$-1], 1);
            cache.add(4);
            testeq(cache.count, 4);
            testeq(cache.length, 3);
            testeq(cache.latest, 4);
            testeq(cache.oldest, 2);
        });
        tests("Range", {
            int[] input = [0, 1, 2, 3, 4];
            tests("Single-length cache", {
                auto range = input.cache(1);
                auto index = 0;
                testeq(range.length, input.length);
                while(!range.empty){
                    testeq(range.front, range.latest);
                    testeq(range.front, range.oldest);
                    testeq(range.front, input[index++]);
                    range.popFront();
                }
                testeq(range.cache.length, 1);
            });
            tests("Longer cache", {
                auto range = input.cache(3);
                auto index = 0;
                while(!range.empty){
                    testeq(range.front, input[index]);
                    testeq(range.oldest, input[index > 2 ? index - 2 : 0]);
                    range.popFront();
                    index++;
                }
            });
            tests("Slicing", {
                static assert(isSlicingRange!(typeof(input.cache())));
                auto slice = input.cache[1 .. $-1];
                test(slice.equals(input[1 .. $-1]));
            });
            tests("Only access front once", {
                TrickyRange input;
                auto range = input.cache;
                fail({input.front; input.front;});
                range.front; range.front;
                range.popFront();
                range.front; range.front;
            });
        });
    });
}
