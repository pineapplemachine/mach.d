module mach.traits.mutability;

private:

//

public:



template isMutable(T){
    enum bool isMutable = is(typeof((inout int = 0){
        T value = T.init;
        value = T.init;
    }));
}



unittest{
    // TODO: More tests
    static assert(isMutable!int);
    static assert(!isMutable!(const int));
}
