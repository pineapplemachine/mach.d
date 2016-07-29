module mach.traits.mutability;

private:

//

public:



enum isMutable(alias T) = isMutable!(typeof(T));
template isMutable(T){
    enum bool isMutable = is(typeof((){
        T value = T.init;
        value = T.init;
    }));
}



unittest{
    struct MutMember{int x;}
    struct ConstMember{const int x;}
    int x; const int cx;
    static assert(isMutable!x);
    static assert(isMutable!int);
    static assert(isMutable!string);
    static assert(isMutable!MutMember);
    static assert(!isMutable!cx);
    static assert(!isMutable!(const int));
    static assert(!isMutable!(immutable char));
    static assert(!isMutable!(const MutMember));
    static assert(!isMutable!ConstMember);
    static assert(!isMutable!(typeof(ConstMember[].init[0])));
}
