module mach.misc.refcounter;

private:

import std.algorithm : count;

public:

/// Reference counter
struct RefCounter(T){
    
    /// Backing array maps reference counts to values
    size_t[T] counter;
    
    /// Returns the new number of references to this value.
    size_t increment(T value){
        size_t newcount = (value in this.counter) ? this.counter[value] + 1 : 1;
        return this.counter[value] = newcount;
    }
    
    /// Returns the new number of references to this value.
    size_t decrement(T value) in{
        assert(
            cast(bool) (value in this.counter), "Can't decrement unindexed value."
        );
        assert(
            this.counter[value] > 0,
            "Can't decrement value because its reference count is already zero."
        );
    }body{
        return this.counter[value] -= 1;
    }
    
    /// Evaluate the passed delegate if the new reference count is zero.
    size_t decrement(T value, void delegate(in T value) func){
        auto newcount = this.decrement(value);
        if(newcount == 0){
            func(value);
            this.counter.remove(value);
        }
        return newcount;
    }
    
    /// Get the number of references to a value.
    size_t get(in T value) const{
        return value in this.counter ? this.counter[value] : 0;
    }
    
    /// Set the number of references to a value.
    void set(in T value, in size_t count){
        this.counter[value] = count;
    }
    
    /// Determine whether a given value is being tracked by the reference counter.
    auto contains(in T value) const{
        return value in this.counter;
    }
    
    /// Get the number of expired values, where references is zero.
    @property size_t expired() const{
        return count!("a <= b")(this.counter.values, 0);
    }
    
    /// Get the number of alive values, where references is nonzero.
    @property size_t alive() const{
        return count!("a > b")(this.counter.values, 0);
    }
    
    /// Get the length of the backing array.
    @property size_t length() const{
        return this.counter.length;
    }
    
    /// Call func for every value with no references, and delete them from the backing array.
    void clean(in void delegate(in T) func){
        this.clean((in T[] values){
            foreach(value; values) func(value);
        });
    }
    void clean(in void delegate(in T[]) func){
        T[] expired = new T[counter.length];
        size_t expiredcount = 0;
        
        foreach(value, count; this.counter){
            if(count <= 0){
                expired[expiredcount] = value;
                expiredcount++;
            }
        }
        
        func(expired[0 .. expiredcount]);
        
        foreach(size_t index; 0 .. expiredcount){
            this.counter.remove(expired[index]);
        }
        
        this.counter.rehash();
    }
    
    const(T)* opBinaryRight(string op: "in")(T value){
        return this.contains(value);
    }
    void opOpAssign(string op: "+")(T value){
        this.increment(value);
    }
    void opOpAssign(string op: "-")(T value){
        this.decrement(value);
    }
    size_t opIndex(T value) const{
        return this.get(value);
    }
    void opIndexAssign(size_t count, T value){
        this.set(value, count);
    }
    
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    // TODO: more
    tests("Reference counting", {
        tests("Incrementing", {
            RefCounter!uint counter;
            counter += 2;
            counter += 3;
            counter += 5;
            counter += 3;
            testeq(counter[2], 1);
            testeq(counter[3], 2);
            testeq(counter[6], 0);
            testeq(counter.expired, 0);
            counter -= 5;
            testeq(counter.expired, 1);
            testfail({counter -= 5;}); // No more references, throw an AssertError
        });
    });
}
