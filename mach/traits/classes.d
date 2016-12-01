module mach.traits.classes;

private:

//

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
