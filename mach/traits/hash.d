module mach.traits.hash;

private:

//

public:

template canHash(T){
    enum bool canHash = is(typeof((inout int = 0){
        T thing = T.init;
        typeid(thing).getHash(&thing);
    }));
}

unittest{
    // TODO: more tests
    static assert(canHash!string);
}
