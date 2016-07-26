module mach.traits.call.func;

private:

//

public:



template isFunctionPointer(Tx...) if(Tx.length == 1){
    enum bool isFunctionPointer = !is(FunctionPointerType!(Tx[0]) == void);
}

template FunctionPointerType(alias T){
    alias FunctionPointerType = FunctionPointerType!(typeof(T));
}
template FunctionPointerType(T){
    static if(is(T F : F*) && is(F == function)){
        alias FunctionPointerType = F;
    }else{
        alias FunctionPointerType = void;
    }
}



template isDelegate(Tx...) if(Tx.length == 1){
    enum bool isDelegate = !is(DelegateType!(Tx[0]) == void);
}

template DelegateType(alias T){
    static if(is(typeof(&T) F : F*) && is(typeof(&T) F == delegate)){
        alias DelegateType = F;
    }else{
        alias DelegateType = DelegateType!(typeof(T));
    }
}
template DelegateType(T){
    static if(is(T F) && is(F == delegate)){
        alias DelegateType = F;
    }else{
        alias DelegateType = void;
    }
}



/// Determine whether some type or reference describes a function or delegate.
template isFunction(Tx...) if(Tx.length == 1){
    enum bool isFunction = !is(FunctionType!(Tx[0]) == void);
}

/// Get the type of some function or delegate, or void if T is neither.
template FunctionType(alias T){
    static if(is(typeof(&T) F : F*) && is(F == function) || is(typeof(&T) F == delegate)){
        alias FunctionType = F; // Nested symbols
    }else{
        alias FunctionType = FunctionType!(typeof(T));
    }
}
/// ditto
template FunctionType(T){
    static if(is(T F : F*) && is(F == function)){
        alias FunctionType = F;
    }else static if(is(T == function) || is(T == delegate)){
        alias FunctionType = T;
    }else{
        alias FunctionType = void;
    }
}



unittest{
    static void sfunc(){}
    void func(){}
    void function() fptr1;
    auto fptr2 = &sfunc;
    auto delptr = &func;
    static assert(isFunctionPointer!fptr1);
    static assert(isFunctionPointer!fptr2);
    static assert(isFunctionPointer!(typeof(fptr1)));
    static assert(isFunctionPointer!(typeof(fptr2)));
    // TODO: Phobos' FunctionTypeOf fail these for the same reason - why?
    //static assert(is(FunctionPointerType!fptr1 == typeof(fptr1)));
    //static assert(is(FunctionPointerType!(typeof(fptr1)) == typeof(fptr1)));
    static assert(!isFunctionPointer!delptr);
    static assert(!isFunctionPointer!(void delegate()));
    static assert(!isFunctionPointer!func);
    static assert(!isFunctionPointer!sfunc);
    static assert(!isFunctionPointer!int);
}

unittest{
    static void sfunc(){}
    void func(){}
    void delegate() del;
    void function() fptr;
    static assert(isDelegate!del);
    static assert(is(DelegateType!del == typeof(del)));
    static assert(isDelegate!(typeof(del)));
    static assert(isDelegate!(int delegate(in int x)));
    static assert(isDelegate!(typeof(&func)));
    static assert(is(DelegateType!(typeof(del)) == typeof(del)));
    static assert(is(DelegateType!(typeof(&func)) == typeof(&func)));
    static assert(!isDelegate!fptr);
    static assert(!isDelegate!(typeof(fptr)));
    static assert(!isDelegate!(int function(in int x)));
    static assert(!isDelegate!(typeof(&sfunc)));
    static assert(!isDelegate!int);
}

unittest{
    static void sfunc(){}
    void func(){}
    void delegate() del;
    void function() fptr;
    static assert(isFunction!(typeof(sfunc)));
    static assert(isFunction!sfunc);
    static assert(isFunction!func);
    static assert(isFunction!del);
    static assert(isFunction!fptr);
    static assert(isFunction!(typeof(&sfunc)));
    static assert(isFunction!(typeof(&func)));
    static assert(is(FunctionType!(typeof(sfunc)) == typeof(sfunc)));
    static assert(is(FunctionType!sfunc == typeof(sfunc)));
    static assert(is(FunctionType!func == typeof(func)));
    static assert(is(FunctionType!del == typeof(del)));
    //static assert(is(FunctionType!fptr == typeof(fptr))); // See TODO in prior unittest
}
