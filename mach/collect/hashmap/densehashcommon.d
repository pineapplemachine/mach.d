module mach.collect.hashmap.densehashcommon;

private:

//

public:



/// Type used to store information resulting from a query for a bucket.
struct GetBucketResult{
    bool exists;
    size_t index;
}



/// Contains fields common to map and set types.
template DenseHashFieldsMixin(){
    /// Array of buckets type.
    alias Buckets = Bucket*[];
    
    // Whether the map is dynamically resized when it is nearly full or
    /// nearly empty.
    static enum bool dynamic = Dynamic;
    /// Default initial size for maps where size is not otherwise specified.
    static enum size_t DefaultSize = 64;
    /// Dynamically-sized maps will not be automatically resized any smaller
    /// than this size.
    static enum size_t MinDynamicSize = 64;
    
    /// Array which stores key, value pair data contained within the map.
    Buckets buckets = null;
    /// Counts the number of values currently in the map.
    size_t numvalues = 0;
    
    /// When a dynamic map is rehashed to be larger, this is the factor by
    /// which its prior size will be multiplied to determine the new size.
    /// Must be greater than 1.
    double upsizefactor = 2.0;
    /// When a dynamic map is rehashed to be smaller, this is the factor by
    /// which its prior size will be multiplied to determine the new size.
    /// Must be less than 1.
    double downsizefactor = 0.5;
    /// When the density of a dynamic map is greater than or equal to this
    /// value, the map will be rehashed with a larger size.
    /// Must be less than or equal to one, and greater than `downsizeat`.
    double upsizeat = 0.75;
    /// When the density of a dynamic map is less than or equal to this
    /// value, the map will be rehashed with a smaller size.
    /// Must be less than or equal to one.
    double downsizeat = 0.25;
}



/// Contains methods common to map and set types.
template DenseHashMethodsMixin(){
    import mach.traits : hasNumericRemaining, hasNumericLength;
    import mach.math : abs, clog2;
    
    /// Get a size suggestion for optimally accommodating some expected number
    /// of key, value pairs.
    size_t suggestsize(in size_t length){
        auto size = cast(size_t)(length * this.upsizefactor);
        static if(dynamic){
            if(size < MinDynamicSize) size = MinDynamicSize;
        }
        return size <= 0 ? 0 : 1 << clog2(size);
    }
    
    /// Get the number of key, value pairs in the map.
    @property size_t length() pure @safe const nothrow{
        return this.numvalues;
    }
    /// True when the map contains no key, value pairs.
    @property bool empty() pure @safe const nothrow{
        return (this.buckets is null) | (this.numvalues == 0);
    }
    /// Return true when the map's backing array is full, false otherwise.
    /// Returns false when the map's storage has not yet been initialized.
    /// Returns true when the map's size and length are both zero.
    @property bool full() const{
        return (this.buckets !is null) && (this.length == this.buckets.length);
    }
    /// Return a measurement of how full the backing array is, 0 for completely
    /// empty and 1 for completely full.
    /// Returns 0 when the map's storage has not yet been initialized.
    @property double density() const{
        if(this.buckets is null){
            return 0;
        }else{
            return this.length / cast(double) this.size;
        }
    }
    
    /// Get the size of the map, which counts the number of buckets.
    /// A map's density is equal to its length divided by its size;
    /// an optimally-built map has a density of around 0.5.
    /// Returns 0 when the map's storage has not yet been initialized.
    @property size_t size() const{
        return this.buckets is null ? 0 : this.buckets.length;
    }
    /// Set the size of the map, or the number of buckets.
    @property void size(in size_t size){
        this.rehash(size);
    }
    
    /// If the map is not already at least as large as the provided size,
    /// then resize is to that size.
    void reserve(in size_t size){
        if(this.buckets is null || size > this.buckets.length){
            this.rehash(size);
        }
    }
    
    /// If the map is not already at least as large as a size automatically
    /// determined for accommodating the number of values in some type with
    /// either a numeric `length` or numeric `remaining` property,
    /// then resize is to that size.
    /// Otherwise, do nothing.
    void accommodate(T)(auto ref T values){
        static if(hasNumericRemaining!T){
            this.reserve(this.suggestsize(values.remaining));
        }else static if(hasNumericLength!T){
            this.reserve(this.suggestsize(values.length));
        }
    }
    
    /// Resize the map. Erases all existing key, value pairs.
    void setsize(in size_t size){
        this.numvalues = 0;
        if(size == 0){
            this.buckets = null;
        }else{
            this.buckets = new Bucket*[size];
        }
    }
    
    /// Resize the map to an automatically-determined optimal size,
    /// and preserve its contents.
    /// If the automatically-determined size is sufficiently close to the
    /// map's current size, then the map is not resized.
    void rehash(){
        immutable newsize = this.suggestsize(this.length);
        if(abs(this.size - newsize) > (this.size / 16)){
            this.rehash(newsize);
        }
    }
    /// Resize the map to the specified size,
    /// and preserve its contents.
    void rehash(in size_t size){
        if(this.buckets is null || this.empty){
            this.buckets = new Bucket*[size];
        }else{
            Buckets newbuckets = new Bucket*[size];
            for(size_t i; i < this.buckets.length; i++){
                if(this.buckets[i] !is null){
                    auto result = getbucketin(
                        newbuckets, this.getbucketkey(this.buckets[i])
                    );
                    assert(result.exists && newbuckets[result.index] is null);
                    newbuckets[result.index] = this.buckets[i];
                }
            }
            this.buckets = newbuckets;
        }
    }
    
    /// Upsizes the map if it's both dynamic and sufficiently full.
    /// Initializes the map if it hasn't been initialized yet.
    void autoupsize(){
        if(this.buckets is null){
            this.setsize(this.DefaultSize);
        }else{
            static if(dynamic){ // Upsize almost-full dynamic maps.
                if(this.density >= upsizeat){
                    this.rehash(cast(size_t)(this.size * upsizefactor));
                    assert(!this.full);
                }
            }
        }
    }
    
    /// Downsizes the map if it's both dynamic and sufficiently sparse.
    void autodownsize(){
        static if(dynamic){ // Downsize almost-empty dynamic maps.
            if(this.density <= downsizeat){
                auto size = cast(size_t)(this.size * downsizefactor);
                if(size >= this.MinDynamicSize) this.rehash(size);
            }
        }
    }
    
    /// Remove all key, value pairs from the map.
    /// The size of the map is not changed.
    void clear(){
        this.numvalues = 0;
        for(size_t i = 0; i < this.buckets.length; i++){
            this.buckets[i] = null;
        }
    }
    
    /// If the key is contained within the map, then a pointer to the map's
    /// representation of the corresponding key, value pair is returned.
    /// Otherwise, returns null.
    auto contains(K key) const{
        if(!this.empty){
            auto result = this.getbucketin(this.buckets, key);
            return result.exists ? this.buckets[result.index] : null;
        }else{
            return null;
        }
    }
    
    /// Remove a key from the map.
    /// If the value was not present in the map, then null is returned.
    /// If the key did exist within the map prior to removal, then a pointer to
    /// the map's representation of the removed key is returned.
    auto remove(K key){
        if(!this.empty){
            auto result = this.removein(this.buckets, key);
            this.numvalues -= (result !is null);
            this.autodownsize();
            return result;
        }else{
            return null;
        }
    }
    
    /// Get the index of the bucket that a key belongs in.
    static auto getbucketin(in Buckets buckets, K key) in{
        assert(buckets !is null && buckets.length);
    }body{
        auto startindex = (cast(size_t) hash(key)) % buckets.length;
        auto index = startindex;
        while(
            buckets[index] !is null &&
            typeof(this).getbucketkey(buckets[index]) != key
        ){
            index = index == 0 ? buckets.length - 1 : index - 1;
            if(index == startindex){
                // Case where no buckets either were empty or contained the
                // searched-for key.
                return GetBucketResult(false, 0);
            }
        }
        return GetBucketResult(true, index);
    }
    
    /// Removes a key from some Buckets.
    /// Returns the removed bucket, if any, and null if no such bucket existed.
    static auto removein(Buckets buckets, K key) in{
        assert(buckets !is null && buckets.length);
    }body{
        auto result = getbucketin(buckets, key);
        if(result.exists && buckets[result.index] !is null){
            auto prior = buckets[result.index];
            buckets[result.index] = null;
            return prior;
        }else{
            return null;
        }
    }
}



enum DenseHashRangeMutability{
    Immutable, /// The range is not mutable.
    Removable /// Elements may be removed, but not mutated.
}

/// Contains code common to map and set ranges.
/// Ranges using this mixin must define `front` and `back` properties.
template DenseHashRangeMixin(){
    enum bool mutable = mutability !is DenseHashRangeMutability.Immutable;
    
    static if(mutable){
        alias Map = Source*;
    }else{
        alias Map = const(Source)*;
    }
    
    /// The map whose values the range is enumerating.
    Map source;
    /// Index of the front cursor in the map's array of buckets.
    size_t frontindex;
    /// Index of the back cursor in the map's array of buckets.
    size_t backindex;
    /// How many values remain in the range.
    size_t remainingvalues;
    /// Whether the range is currently empty.
    bool isempty;
    
    this(Map source){
        this(source, 0, source.size, source.length, source.empty);
        if(!this.isempty){
            this.nextFront();
            this.nextBack();
        }
    }
    this(
        Map source, size_t frontindex, size_t backindex,
        size_t remainingvalues, bool isempty
    ){
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
        this.remainingvalues = remainingvalues;
        this.isempty = isempty;
    }
    
    /// Get whether the range is empty.
    @property bool empty() const in{
        assert(this.source !is null, "Range is not valid.");
    }body{
        return this.isempty;
    }
    /// Get the length of the range.
    @property auto length() const in{
        assert(this.source !is null, "Range is not valid.");
    }body{
        return this.source.length;
    }
    /// Get the number of values remaining in the range.
    @property auto remaining() const in{
        assert(this.source !is null, "Range is not valid.");
    }body{
        return this.remainingvalues;
    }
    
    @property auto frontbucket() const in{
        assert(this.source !is null, "Range is not valid.");
        assert(!this.empty, "Range is empty.");
    }out{
        assert(__result !is null);
    }body{
        return this.source.buckets[this.frontindex];
    }
    @property auto backbucket() const in{
        assert(this.source !is null, "Range is not valid.");
        assert(!this.empty, "Range is empty.");
    }out{
        assert(__result !is null);
    }body{
        return this.source.buckets[this.backindex - 1];
    }
    
    void popFront() in{
        assert(this.source !is null, "Range is not valid.");
        assert(!this.empty, "Range is empty.");
    }body{
        this.remainingvalues--;
        this.frontindex++;
        this.nextFront();
        this.isempty = this.frontindex >= this.backindex;
    }
    private void nextFront(){
        while(
            this.frontindex < this.backindex &&
            this.source.buckets[this.frontindex] is null
        ){
            this.frontindex++;
        }
    }
    
    void popBack() in{
        assert(this.source !is null, "Range is not valid.");
        assert(!this.empty, "Range is empty.");
    }body{
        this.remainingvalues--;
        this.backindex--;
        this.nextBack();
        this.isempty = this.frontindex >= this.backindex;
    }
    private void nextBack(){
        while(
            this.frontindex < this.backindex &&
            this.source.buckets[this.backindex - 1] is null
        ){
            this.backindex--;
        }
    }
    
    @property typeof(this) save(){
        return typeof(this)(
            this.source, this.frontindex, this.backindex,
            this.remainingvalues, this.isempty
        );
    }
    
    static if(mutability is DenseHashRangeMutability.Removable){
        /// Remove and pop the front element of the range.
        void removeFront() in{
            assert(this.source !is null, "Range is not valid.");
            assert(!this.empty, "Range is empty.");
        }body{
            this.source.buckets[this.frontindex] = null;
            this.source.numvalues--;
            this.popFront();
        }
        /// Remove and pop the back element of the range.
        void removeBack() in{
            assert(this.source !is null, "Range is not valid.");
            assert(!this.empty, "Range is empty.");
        }body{
            this.source.buckets[this.backindex - 1] = null;
            this.source.numvalues--;
            this.popBack();
        }
    }
}
