module mach.traits.transform;

private:

//

public:



template isTransformation(alias transform, T...){
    enum bool isTransformation = is(typeof((inout int = 0){
        auto result = transform(T.init);
    }));
}

template isTransformationType(alias transform, Result, T...){
    enum bool isTransformation = is(typeof((inout int = 0){
        Result result = transform(T.init);
    }));
}



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
    // isTransformation
    static assert(isTransformation!((a) => (a), int));
    static assert(isTransformation!((a) => (a[0]), int[]));
}
