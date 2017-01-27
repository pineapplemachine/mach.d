module mach.types.refcounted;

private:

import mach.sys : malloc, memfree;

/++ Docs

The `RefCounted` type can be used to acquire a reference-counted wrapper
type of another type, which calls a given function when the number of
living references becomes zero.

By default, the basis value's `free` method is called when the number of
references reaches zero.
However, this behavior can be changed by using a template argument when
defining the `RefCounted` type.

+/

unittest{ /// Example
    int freed = 0;
    {
        // Create a reference-counted int type, which increments `freed` when refs hit zero.
        auto value = RefCounted!(int, i => freed++)(1);
        assert(value == 1); // Acts like an int!
        assert(value.references == 1);
        {
            auto anothervalue = value; // Another reference!
            assert(value.references == 2);
        }
        assert(value.references == 1); // No more second reference.
    }
    assert(freed == 1); // No more references, so the callback was evaluated.
}

public:



alias DefaultOnZeroReferences = x => x.free();

template canRefCount(T, alias onzeroref = DefaultOnZeroReferences){
    enum canRefCount = is(typeof({onzeroref(T.init);}));
}

/// Maintain a reference-counted value and, when the number of references
/// reaches zero, evaluate a function passed as a template argument.
/// By default, the function calls the value's `free` method.
struct RefCounted(T, alias onzeroref = DefaultOnZeroReferences) if(
    canRefCount!(T, onzeroref)
){
    alias References = size_t;
    
    /// The value being reference counted.
    T payload;
    /// Pointer to a value tracking the number of living references.
    References* countreferences = null;
    
    alias payload this;
    
    this(Args...)(auto ref Args args){
        this.payload = T(args);
        this.allocreferences();
    }
    
    this(this) @trusted @nogc nothrow{
        assert(this.countreferences !is null);
        *this.countreferences += 1;
    }
    
    ~this(){
        if(this.decrementreferences()) onzeroref(this.payload);
    }
    
    /// Get the number of living references.
    @property auto references() @trusted @nogc nothrow const{
        assert(this.countreferences !is null);
        return *this.countreferences;
    }
    
    /// Method used to allocate `countreferences`.
    private @trusted @nogc nothrow void allocreferences(){
        assert(this.countreferences is null);
        this.countreferences = malloc!References;
        *this.countreferences = 1;
    }
    
    /// Method used to decrement `countreferences`.
    /// If it reaches zero, the pointer is freed and the method returns true.
    /// Otherwise the method returns false.
    private @trusted @nogc nothrow bool decrementreferences(){
        assert(this.countreferences !is null);
        *this.countreferences -= 1;
        if(*this.countreferences <= 0){
            memfree(this.countreferences);
            return true;
        }else{
            return false;
        }
    }
}



private version(unittest){
    struct Test{
        int x = 0;
        static int freed = 0;
        void free(){
            this.freed += 1;
        }
    }
    void dotest(in Test test){
        return;
    }
}
unittest{
    assert(Test.freed == 0);
    {
        auto counted = RefCounted!Test(1);
        assert(Test.freed == 0);
        assert(counted.references == 1);
        assert(counted.x == 1);
        dotest(counted);
        {
            auto c2 = counted;
            assert(Test.freed == 0);
            assert(counted.references == 2);
        }
        assert(Test.freed == 0);
        assert(counted.references == 1);
    }
    assert(Test.freed == 1);
}
