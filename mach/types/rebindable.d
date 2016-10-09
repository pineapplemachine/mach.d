module mach.types.rebindable;

private:

import mach.traits : Unqual;

public:



// TODO: Maybe support increment and decrement operators
// I'm not sure whether that's possible to do in a decent way honestly



enum isRebindable(T) = is(typeof({
    T x = T.init;
    x = T.init;
}));



auto rebindable(T)(T value){
    static if(isRebindable!T){
        return value;
    }else static if(isRebindable!(Unqual!T)){
        return cast(Unqual!T) value;
    }else{
        return RebindableType!T(value);
    }
}



template Rebindable(T){
    static if(isRebindable!T){
        alias Rebindable = T;
    }else static if(isRebindable!(Unqual!T)){
        alias Rebindable = Unqual!T;
    }else{
        alias Rebindable = RebindableType!T;
    }
}



struct RebindableType(T){
    static enum bool canAssignTo(X) = is(typeof({this.rebind ~= value;}));
    static enum bool isImmutableUnaryOp(string op) = is(typeof({
        mixin(`return `~ op ~ `this.rebind[0];`);
    }));
    
    T[] rebind;
    
    alias value this;
    
    this(X)(X value) if(canAssignTo!X){
        this.value = value;
    }
    
    void assertbound() const{
        assert(this.rebind.length != 0,
            "Rebindable type is not currently storing a value."
        );
        assert(this.rebind.length == 1,
            "Something went terribly wrong; rebindable type is currently " ~
            "storing more than one value."
        );
    }
    
    @property auto value() in{this.assertbound();} body{
        return this.rebind[0];
    }
    
    @property void value(X)(X value) if(canAssignTo!X){
        this.rebind.length = 0;
        this.rebind ~= value;
    }
    
    auto ref opUnary(string op)() if(isImmutableUnaryOp!op) in{this.assertbound();} body{
        mixin(`return `~ op ~ `this.rebind[0];`);
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
    void opAssign(X)(auto ref X value) if(canAssignTo!X){
        this.value = value;
    }
    auto ref opOpAssign(string op, X)(auto ref X value) if(is(typeof({
        mixin(`this.value = this.value ` ~ op ~ ` value;`);
    }))){
        mixin(`this.value = this.value ` ~ op ~ ` value;`);
    }
}



version(unittest){
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
    static assert(is(typeof(rebindable(int(0))) == int));
    static assert(is(typeof(rebindable(MutMember.init)) == MutMember));
}
unittest{
    static assert(is(typeof(rebindable(const(int)(0))) == int));
    static assert(is(typeof(rebindable(immutable(int)(0))) == int));
    static assert(is(typeof(rebindable(const(MutMember).init)) == MutMember));
}
unittest{
    auto x = ConstMember(0);
    static assert(!isRebindable!(typeof(x)));
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
    }
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
    {
        // OpBinary
        auto y = rebindable(x);
        assert(y == x);
        assert(x + y == x);
        assert(y + ConstMember(1) == rebindable(ConstMember(1)));
    }
    {
        // Assign
        auto y = rebindable(x);
        assert(y == x);
        y = ConstMember(1);
        assert(y == ConstMember(1));
        y = ConstMember(100);
        assert(y == ConstMember(100));
        // OpAssign
        y += ConstMember(1);
        assert(y == ConstMember(101));
        y *= ConstMember(2);
        assert(y == ConstMember(202));
    }
    {
        // OpIndex
        auto y = rebindable(x);
        assert(y[0] == x[0]);
        assert(y[100] == x[100]);
    }
}
