module mach.error.mixins;

private:

//

public:



string ThrowableCtorMixin(string DefaultMessage)(){
    return `
        this(size_t line = __LINE__, string file = __FILE__){
            this("` ~ DefaultMessage ~ `", cast(Throwable) null, line, file);
        }
        this(Throwable next, size_t line = __LINE__, string file = __FILE__){
            this("` ~ DefaultMessage ~ `", next, line, file);
        }
        this(string message, size_t line, string file){
            this(message, null, line, file);
        }
    `;
}

template ThrowableMixin(string DefaultMessage){
    import std.traits : BaseClassesTuple;
    import mach.error.mixins : ThrowableCtorMixin;
    mixin(ThrowableCtorMixin!DefaultMessage);
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        alias BaseClass = BaseClassesTuple!(typeof(this))[0];
        static if(__traits(compiles, {new BaseClass(message, file, line, next);})){
            super(message, file, line, next);
        }else static if(__traits(compiles, {new BaseClass(message, next, line, file);})){
            super(message, next, line, file);
        }else{
            static assert(false, "Cannot automatically assign constructor.");
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    class A: Exception{mixin ThrowableMixin!"A";}
    class B: Error{mixin ThrowableMixin!"B";}
    class C: A{mixin ThrowableMixin!"C";}
}
unittest{
    tests("Error mixins", {
        fail({throw new A;});
        fail({throw new B;});
        fail({throw new C;});
    });
}
