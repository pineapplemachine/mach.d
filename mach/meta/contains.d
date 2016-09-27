module mach.meta.contains;

private:

//

public:



/// Get whether the first argument is equivalent to any of the successive
/// arguments.
template Contains(Args...) if(Args.length){
    import mach.meta.aliases : Alias;
    alias T = Alias!(Args[0]);
    alias Seq = Args[1 .. $];
    static if(Seq.length == 0){
        static enum bool Contains = false;
    }else static if(is(T == Seq[0])){
        static enum bool Contains = true;
    }else static if(is(typeof({static if(T == Seq[0]){}}))){
        static if(T == Seq[0]){
            static enum bool Contains = true;
        }else{
            static enum bool Contains = Contains!(T, Seq[1 .. $]);
        }
    }else{
        static enum bool Contains = Contains!(T, Seq[1 .. $]);
    }
}



unittest{
    static assert(Contains!(int, int));
    static assert(Contains!(int, int, int));
    static assert(Contains!(int, int, void));
    static assert(Contains!(int, void, int));
    static assert(Contains!(int, void, void, int));
    static assert(!Contains!(int));
    static assert(!Contains!(int, void));
    static assert(!Contains!(int, void, void));
}
unittest{
    static assert(Contains!(0, 0));
    static assert(Contains!(0, 0, 0));
    static assert(Contains!(0, 0, 1));
    static assert(Contains!(0, 1, 0));
    static assert(Contains!(0, 1, 1, 0));
    static assert(Contains!(0, 1, void, 0));
    static assert(!Contains!(0));
    static assert(!Contains!(0, 1));
    static assert(!Contains!(0, void));
    static assert(!Contains!(0, 1, void));
}
