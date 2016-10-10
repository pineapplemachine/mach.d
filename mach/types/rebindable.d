module mach.types.rebindable;

private:

import mach.traits : Unqual;
import mach.sys.memory : malloc, free, memcpy;

public:



/// Determine whether a type is rebindable. That is, whether a value of this
/// type can be rebound using the assignment operator.
enum isRebindable(T) = is(typeof({
    T x = T.init;
    x = T.init;
}));



/// Given a value, get it as a rebindable type.
auto rebindable(T)(T value){
    static if(isRebindable!T){
        return value;
    }else static if(isRebindable!(Unqual!T)){
        return cast(Unqual!T) value;
    }else{
        return RebindableType!T(value);
    }
}



/// Given a type, get its rebindable analog.
template Rebindable(T){
    static if(isRebindable!T){
        alias Rebindable = T;
    }else static if(isRebindable!(Unqual!T)){
        alias Rebindable = Unqual!T;
    }else{
        alias Rebindable = RebindableType!T;
    }
}



/// Wraps a value that would normally not be rebindable in a struct whose value
/// can be freely rebound.
struct RebindableType(T){
    T* rebind = null;
    
    alias value this;
    
    /// Used to verify correctness of memory allocation and deallocation.
    version(unittest) static long alive = 0;
    
    this(T value) @trusted @nogc{
        this.rebind = malloc!T;
        version(unittest) alive++;
        memcpy(this.rebind, &value, T.sizeof);
    }
    
    this(this) @trusted @nogc{
        T* newptr = malloc!T;
        version(unittest) alive++;
        memcpy(newptr, this.rebind, T.sizeof);
        this.rebind = newptr;
    }
    ~this() @trusted @nogc{
        free(this.rebind);
        version(unittest) alive--;
    }
    
    /// The `init` property is overriden in an attempt to avoid the edge-casey
    /// state where the rebindable type has no actual value.
    static @property typeof(this) init(){
        return typeof(this)(T.init);
    }
    
    /// Throws an AssertError if the internal `rebind` pointer is null,
    /// which should be considered an illegal state.
    void assertbound() const @safe pure nothrow{
        assert(this.rebind !is null, "Rebindable type has no value.");
    }
    
    /// Get the value wrapped by this rebindable type.
    @property auto value() @safe pure nothrow in{this.assertbound();} body{
        return *this.rebind;
    }
    /// Set the value wrapped by this rebindable type.
    @property void value(T value) @trusted pure nothrow in{this.assertbound();} body{
        memcpy(this.rebind, &value, T.sizeof);
    }
    
    auto ref opUnary(string op)() if(is(typeof({
        mixin(`return `~ op ~ `(*this.rebind);`);
    }))) in{this.assertbound();} body{
        mixin(`return `~ op ~ `(*this.rebind);`);
    }
    
    auto ref opBinary(string op, X)(auto ref X value) if(is(typeof({
        mixin(`return this.value ` ~ op ~ ` value;`);
    }))){
        mixin(`return this.value ` ~ op ~ ` value;`);
    }
    auto ref opBinaryRight(string op, X)(auto ref X value) if(is(typeof({
        mixin(`return value ` ~ op ~ ` this.value;`);
    }))){
        mixin(`return value ` ~ op ~ ` this.value;`);
    }
    void opAssign(T value) @safe pure nothrow{
        this.value = value;
    }
    auto ref opOpAssign(string op, X)(auto ref X value) if(is(typeof({
        mixin(`this.value = this.value ` ~ op ~ ` value;`);
    }))){
        mixin(`this.value = this.value ` ~ op ~ ` value;`);
    }
}



version(unittest){
    import mach.io.log;
    private:
    struct MutMember{int x;}
    struct ConstMember{
        int x;
        const int y = 0;
        auto opUnary(string op)() if(op != `++` && op != `--`){
            mixin(`return ConstMember(` ~ op ~ `this.x);`);
        }
        auto opUnary(string op: `++`)(){++this.x;}
        auto opUnary(string op: `--`)(){--this.x;}
        auto opBinary(string op)(ConstMember x){
            mixin(`return ConstMember(this.x ` ~ op ~ ` x.x);`);
        }
        auto opCmp(T)(T x){
            if(this.x > x) return 1;
            else if(this.x < x) return -1;
            else return 0;
        }
        auto opIndex(in size_t i){return this.x + i;}
    }
}

unittest{
    static assert(isRebindable!int);
    static assert(isRebindable!string);
    static assert(isRebindable!MutMember);
    static assert(!isRebindable!void);
    static assert(!isRebindable!(const(int)));
    static assert(!isRebindable!(immutable(int)));
    static assert(!isRebindable!ConstMember);
}
unittest{
    static assert(is(Rebindable!(int) == int));
    static assert(is(Rebindable!(MutMember) == MutMember));
    static assert(is(Rebindable!(const(int)) == int));
    static assert(is(Rebindable!(immutable(int)) == int));
    static assert(is(Rebindable!(const(MutMember)) == MutMember));
}
unittest{
    static assert(is(typeof(rebindable(int(0))) == int));
    static assert(is(typeof(rebindable(MutMember.init)) == MutMember));
    static assert(is(typeof(rebindable(const(int)(0))) == int));
    static assert(is(typeof(rebindable(immutable(int)(0))) == int));
    static assert(is(typeof(rebindable(const(MutMember).init)) == MutMember));
}

unittest{
    auto x = ConstMember(0);
    static assert(!isRebindable!(typeof(x)));
    alias T = Rebindable!ConstMember;
    assert(T.alive == 0);
    {
        // Comparison
        auto y = rebindable(x);
        static assert(isRebindable!(typeof(y)));
        assert(y.value == x);
        assert(y.x == 0);
        assert(y == x);
        assert(y != ConstMember(1));
        assert(y < ConstMember(1));
        assert(y > ConstMember(-1));
        assert(T.alive == 1);
    }
    assert(T.alive == 0);
    {
        // Init
        auto y = Rebindable!ConstMember.init;
        assert(y == ConstMember.init);
    }
    assert(T.alive == 0);
    {
        // OpUnary
        auto y = rebindable(x);
        assert(y == x);
        assert(-y == x);
        auto z = rebindable(ConstMember(1));
        assert(-z == ConstMember(-1));
        assert(-z == y - ConstMember(1));
        // Increment/decrement
        z--;
        assert(z == y);
        y++;
        assert(z < y);
    }
    assert(T.alive == 0);
    {
        // OpBinary
        auto y = rebindable(x);
        assert(y == x);
        assert(x + y == x);
        assert(y + ConstMember(1) == rebindable(ConstMember(1)));
    }
    assert(T.alive == 0);
    {
        // Assign
        auto y = rebindable(x);
        assert(y == x);
        y = ConstMember(1);
        assert(y == ConstMember(1));
        y = ConstMember(100);
        assert(y == ConstMember(100));
        y = y;
        assert(y == ConstMember(100));
        // OpAssign
        y += ConstMember(1);
        assert(y == ConstMember(101));
        y *= ConstMember(2);
        assert(y == ConstMember(202));
    }
    assert(T.alive == 0);
    {
        // OpIndex
        auto y = rebindable(x);
        assert(y[0] == x[0]);
        assert(y[100] == x[100]);
    }
    assert(T.alive == 0);
    {
        // OpCast
        auto y = rebindable(x);
        static assert(is(typeof(cast(ConstMember) y) == ConstMember));
        assert(cast(ConstMember) y == x);
    }
    assert(T.alive == 0);
}
