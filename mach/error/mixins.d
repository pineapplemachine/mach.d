module mach.error.mixins;

/+

Example usage:

mixin(errorclassmixin("ExampleError"));
throw new ExampleError();
throw new ExampleError("Hello, world!");
throw new ExampleError(new AssertError());

+/

private:
    
import std.string : split;

enum string DEFAULT_CONSTRUCTOR_ATTR = "@safe pure nothrow";
enum string DEFAULT_CONSTRUCTOR_BODY = "super(message, file, line, next);";
    
public:

static string ThrowableClassMixin(
    in string classname, in string superclass, in string defaultmessage,
    in string classbody = "",
    in string constructorattr = DEFAULT_CONSTRUCTOR_ATTR,
    in string constructorbody = DEFAULT_CONSTRUCTOR_BODY
){
    return "
        class " ~ classname ~ " : " ~ superclass ~ "{
            " ~ constructorattr ~ " this(size_t line = __LINE__, string file = __FILE__){
                this(cast(Throwable) null, line, file);
            }
            " ~ constructorattr ~ " this(Throwable next, size_t line = __LINE__, string file = __FILE__){
                this(\"" ~ defaultmessage ~ "\", next, line, file);
            }
            " ~ constructorattr ~ " this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
                " ~ constructorbody ~ "
            }
            " ~ classbody ~ "
        }
    ";
}

static string ErrorClassMixin(
    in string classname, in string defaultmessage = "Error",
    in string classbody = "",
    in string constructorattr = DEFAULT_CONSTRUCTOR_ATTR,
    in string constructorbody = DEFAULT_CONSTRUCTOR_BODY
){
    return ThrowableClassMixin(classname, "Error", defaultmessage);
}

static string ExceptionClassMixin(
    in string classname, in string defaultmessage = "Exception",
    in string classbody = "",
    in string constructorattr = DEFAULT_CONSTRUCTOR_ATTR,
    in string constructorbody = DEFAULT_CONSTRUCTOR_BODY
){
    return ThrowableClassMixin(classname, "Exception", defaultmessage);
}

unittest{
    // TODO
}
