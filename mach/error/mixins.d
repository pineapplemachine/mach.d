module mach.error.mixins;

/+

Example usage:

mixin(ErrorClassMixin("ExampleError"));
throw new ExampleError();
throw new ExampleError("Hello, world!");
throw new ExampleError(new AssertError());

+/

private:

enum string DefaultCtorAttr = "@safe pure nothrow";

static string getdefaultctorbody(string superclass)(){
    static if(superclass == `Error` || superclass == `Exception`){
        return "super(message, file, line, next);";
    }else{
        return `super(message, next, line, file);`;
    }
}

public:



/// Mixin to build a throwable class
static string ThrowableClassMixin(
    string classname,
    string superclass,
    string defaultmessage,
    string classbody = ``,
    string ctorattr = DefaultCtorAttr,
    string ctorbody = ``
)(){
    return "
        class " ~ classname ~ " : " ~ superclass ~ "{
            " ~ ctorattr ~ " this(size_t line = __LINE__, string file = __FILE__){
                this(cast(Throwable) null, line, file);
            }
            " ~ ctorattr ~ " this(Throwable next, size_t line = __LINE__, string file = __FILE__){
                this(\"" ~ defaultmessage ~ "\", next, line, file);
            }
            " ~ ctorattr ~ " this(string message, size_t line, string file){
                this(message, null, line, file);
            }
            " ~ ctorattr ~ " this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
                " ~ (ctorbody != `` ? ctorbody : getdefaultctorbody!superclass) ~ "
            }
            " ~ classbody ~ "
        }
    ";
}

/// Mixin to build a class extending Error
static string ErrorClassMixin(
    string classname,
    string defaultmessage = "Error",
    string classbody = "",
    string ctorattr = DefaultCtorAttr,
    string ctorbody = ``
)(){
    return ThrowableClassMixin!(classname, "Error", defaultmessage, classbody, ctorattr, ctorbody);
}

/// Mixin to build a class extending Exception
static string ExceptionClassMixin(
    string classname,
    string defaultmessage = "Exception",
    string classbody = "",
    string ctorattr = DefaultCtorAttr,
    string ctorbody = ``
)(){
    return ThrowableClassMixin!(classname, "Exception", defaultmessage, classbody, ctorattr, ctorbody);
}

unittest{
    // TODO
}
