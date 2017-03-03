module mach.traits.classes;

private:

/++ Docs

The `isClass` template can be used to determine whether some type is implemented
as a class, as opposed to being a struct or a primitive.

+/

unittest{ /// Example
    static assert(isClass!(Object));
    static assert(!isClass!(int));
}

public:



template isClass(T){
    enum bool isClass = is(T == class);
}



version(unittest){
    private:
    class TestClass{
        int x, y;
    }
    struct TestStruct{
        int x, y;
    }
}
unittest{
    static assert(isClass!TestClass);
    static assert(!isClass!void);
    static assert(!isClass!int);
    static assert(!isClass!(int[]));
    static assert(!isClass!TestStruct);
}
