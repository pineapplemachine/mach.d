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
enum string DefaultCtorBody = "super(message, file, line, next);";
    
public:

/// Mixin to build a throwable class
static string ThrowableClassMixin(
    in string classname, in string superclass, in string defaultmessage,
    in string classbody = "",
    in string ctorattr = DefaultCtorAttr,
    in string ctorbody = DefaultCtorBody
){
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
                " ~ ctorbody ~ "
            }
            " ~ classbody ~ "
        }
    ";
}

/// Mixin to build a class extending Error
static string ErrorClassMixin(
    in string classname, in string defaultmessage = "Error",
    in string classbody = "",
    in string ctorattr = DefaultCtorAttr,
    in string ctorbody = DefaultCtorBody
){
    return ThrowableClassMixin(classname, "Error", defaultmessage, classbody, ctorattr, ctorbody);
}

/// Mixin to build a class extending Exception
static string ExceptionClassMixin(
    in string classname, in string defaultmessage = "Exception",
    in string classbody = "",
    in string ctorattr = DefaultCtorAttr,
    in string ctorbody = DefaultCtorBody
){
    return ThrowableClassMixin(classname, "Exception", defaultmessage, classbody, ctorattr, ctorbody);
}

unittest{
    // TODO
}
