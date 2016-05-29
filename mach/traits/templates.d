module mach.traits.templates;

private:

//

public:



template isTemplateType(alias T: Base!Args, alias Base, Args...){
    enum bool isTemplateType = Args.length > 0;
}
template isTemplateType(T: Base!Args, alias Base, Args...){
    enum bool isTemplateType = Args.length > 0;
}
template isTemplateType(T){
    enum bool isTemplateType = false;
}



template isTemplateOf(alias T: Base!Args, alias Base, Args...){
    enum bool isTemplateOf = true;
}
template isTemplateOf(T: Base!Args, alias Base, Args...){
    enum bool isTemplateOf = true;
}
enum isTemplateOf(T, alias Base) = false;
enum isTemplateOf(T, Base) = false;



version(unittest){
    private:
    struct TemplateTest(T){
        T value;
    }
    struct NoTemplateTest{
        int value;
    }
}
unittest{
    // isTemplateType
    assert(isTemplateType!(TemplateTest!int));
    assert(!isTemplateType!NoTemplateTest);
    assert(!isTemplateType!int);
    // isTemplateOf
    static assert(isTemplateOf!(TemplateTest!int, TemplateTest));
    static assert(!isTemplateOf!(TemplateTest!int, int));
    static assert(!isTemplateOf!(int, TemplateTest));
    static assert(!isTemplateOf!(NoTemplateTest, TemplateTest));
}
