module mach.traits.predicate;

private:

//

public:



template isPredicate(alias predicate, T...){
    enum bool isPredicate = is(typeof((inout int = 0){
        auto result = predicate(T.init);
        if(result){}
    }));
}



unittest{
    // Unary isPredicate
    static assert(isPredicate!((n) => (n > 0), int));
    static assert(isPredicate!((in int n) => (n > 0), int));
    static assert(isPredicate!((n) => (n > 0), const int));
    static assert(!isPredicate!((x, y) => (x), int));
    static assert(!isPredicate!((in string str) => (str.length), int));
    // Binary isPredicate
    static assert(isPredicate!((a, b) => (a > b), int, int));
    static assert(!isPredicate!((x, y, z) => (x), int, int));
}
