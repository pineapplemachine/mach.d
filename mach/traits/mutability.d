module mach.traits.mutability;

private:

//

public:



/// Determine whether a type is mutable.
enum isMutable(alias T) = isMutable!(typeof(T));
/// ditto
template isMutable(T){
    enum bool isMutable = (
        !is(T == const) && !is(T == immutable) && !is(T == inout)
    );
}

/// Determine whether variables holding the given type can legally be reassigned.
/// Const and immutable values can't be reassigned, nor can mutable types that
/// have immutable members.
enum canReassign(alias T) = canReassign!(typeof(T));
/// ditto
template canReassign(T){
    enum bool canReassign = is(typeof((){
        T value = T.init;
        value = T.init;
    }));
}



unittest{
    int i;
    const(int) ci;
    string str;
    const(string) cstr;
    static assert(isMutable!i);
    static assert(isMutable!str);
    static assert(isMutable!int);
    static assert(isMutable!real);
    static assert(isMutable!string);
    static assert(isMutable!int);
    static assert(isMutable!(const(int)[]));
    static assert(isMutable!(immutable(int)[]));
    static assert(!isMutable!ci);
    static assert(!isMutable!cstr);
    static assert(!isMutable!(const(int)));
    static assert(!isMutable!(const(string)));
    static assert(!isMutable!(immutable(int)));
    static assert(!isMutable!(immutable(int[])));
    static assert(!isMutable!(const(const(int)[])));
}

unittest{
    struct MutMember{int x;}
    struct ConstMember{const int x;}
    int x; const int cx;
    static assert(canReassign!x);
    static assert(canReassign!int);
    static assert(canReassign!string);
    static assert(canReassign!MutMember);
    static assert(!canReassign!cx);
    static assert(!canReassign!(const int));
    static assert(!canReassign!(immutable char));
    static assert(!canReassign!(const MutMember));
    static assert(!canReassign!ConstMember);
    static assert(!canReassign!(typeof(ConstMember[].init[0])));
}
