module mach.meta.indexof;

private:

//

public:



/// Get the first index of the first argument in the sequence represented by
/// the remaining arguments. Evaluates to -1 if that argument is not present in
/// the sequence.
template IndexOf(Args...) if(Args.length){
    alias IndexOf = IndexOfImpl!(0, Args);
}

private template IndexOfImpl(size_t index, Args...) if(Args.length){
    import mach.meta.aliases : Alias;
    alias T = Alias!(Args[0]);
    alias Seq = Args[1 .. $];
    static if(Seq.length == 0){
        static enum ptrdiff_t IndexOfImpl = -1;
    }else static if(is(T == Seq[0])){
        static enum ptrdiff_t IndexOfImpl = index;
    }else static if(is(typeof({static if(T == Seq[0]){}}))){
        static if(T == Seq[0]){
            static enum ptrdiff_t IndexOfImpl = index;
        }else{
            static enum ptrdiff_t IndexOfImpl = (
                IndexOfImpl!(index + 1, T, Seq[1 .. $])
            );
        }
    }else{
        static enum ptrdiff_t IndexOfImpl = (
            IndexOfImpl!(index + 1, T, Seq[1 .. $])
        );
    }
}



unittest{
    static assert(IndexOf!(int) == -1);
    static assert(IndexOf!(int, void) == -1);
    static assert(IndexOf!(int, int) == 0);
    static assert(IndexOf!(int, int, int) == 0);
    static assert(IndexOf!(int, int, void) == 0);
    static assert(IndexOf!(int, void, void, int) == 2);
}
unittest{
    static assert(IndexOf!(0) == -1);
    static assert(IndexOf!(0, void) == -1);
    static assert(IndexOf!(0, 1) == -1);
    static assert(IndexOf!(0, 0) == 0);
    static assert(IndexOf!(0, 0, 0) == 0);
    static assert(IndexOf!(0, 0, 1) == 0);
    static assert(IndexOf!(0, 1, 1, 0) == 2);
    static assert(IndexOf!(0, 1, void, 0) == 2);
}
