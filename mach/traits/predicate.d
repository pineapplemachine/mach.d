module mach.traits.predicate;

private:

//

public:



/// Can some alias serve as a unary predicate for a type?
template isPredicate(T, alias predicate){
    enum bool isPredicate = is(typeof((inout int = 0){
        auto result = predicate(T.init);
        if(result){}
    }));
}

/// Can some alias serve as a binary predicate for two types?
template isPredicate(A, B, alias predicate){
    enum bool isPredicate = is(typeof((inout int = 0){
        auto result = predicate(A.init, B.init);
        if(result){}
    }));
}



unittest{
    // Unary isPredicate
    static assert(isPredicate!(int, (n) => (n > 0)));
    static assert(isPredicate!(int, (in int n) => (n > 0)));
    static assert(isPredicate!(const int, (n) => (n > 0)));
    static assert(!isPredicate!(int, (x, y) => (x)));
    static assert(!isPredicate!(int, (in string str) => (str.length)));
    // Binary isPredicate
    static assert(isPredicate!(int, int, (a, b) => (a > b)));
    static assert(!isPredicate!(int, int, (x, y, z) => (x)));
}
