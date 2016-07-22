module mach.meta.aliases;

private:

//

public:



template Aliases(T...){
    alias Aliases = T;
}

template Alias(T){
    alias Alias = T;
}

template Alias(alias T){
    static if(__traits(compiles, {alias A = T;})){
        alias Alias = T;
    }else static if(__traits(compiles, {enum A = T;})){
        enum Alias = T;
    }else{
        static assert(false, "Failed to alias type " ~ a.stringof ~ ".");
    }
}



unittest{
    alias Nums = Aliases!(int, real);
    void numstest(Nums nums){
        static assert(nums.length == 2);
        static assert(is(typeof(nums[0]) == int));
        static assert(is(typeof(nums[1]) == real));
    }
    alias Ints = Aliases!int;
    void intstest(Ints i){
        static assert(is(typeof(i[0]) == int));
    }
    alias Int = Alias!int;
    void inttest(Int i){
        static assert(is(typeof(i) == int));
    }
    alias Four = Alias!4;
}
