module mach.traits.ctor;

private:

//

public:

enum hasConstructor(T) = is(typeof(T.__ctor));

version(unittest){
    private:
    struct CtorTest{
        int x;
        this(int x){
            this.x = x;
        }
    }
    struct NoCtorTest{
        int x;
    }
}
unittest{
    static assert(hasConstructor!CtorTest);
    static assert(!hasConstructor!NoCtorTest);
    static assert(!hasConstructor!int);
}
